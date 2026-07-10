import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, '..');
const logFile = path.join(rootDir, '.codex-runtime', 'agent-debug-runtime.log');
const port = Number(process.env.GOPLAN_AGENT_DEBUG_PORT || 8787);

const config = readLocalConfig();

log(`boot pid=${process.pid}`);
process.on('uncaughtException', (error) => {
  log(`uncaughtException ${error.stack || error.message}`);
});
process.on('unhandledRejection', (error) => {
  log(`unhandledRejection ${error?.stack || error}`);
});
process.on('exit', (code) => {
  log(`exit code=${code}`);
});

const server = http.createServer(async (req, res) => {
  try {
    const url = new URL(req.url || '/', `http://${req.headers.host}`);
    if (req.method === 'GET' && url.pathname === '/') {
      return sendFile(res, path.join(__dirname, 'index.html'), 'text/html');
    }
    if (req.method === 'GET' && url.pathname === '/api/health') {
      return sendJson(res, {
        ok: true,
        amapConfigured: Boolean(config.amapKey),
        qweatherConfigured: Boolean(config.qweatherHost),
      });
    }
    if (req.method === 'POST' && url.pathname === '/api/plan') {
      const body = await readJson(req);
      const result = await runTravelAgent(String(body.query || ''));
      return sendJson(res, result);
    }
    if (req.method === 'POST' && url.pathname === '/api/chat') {
      const body = await readJson(req);
      const result = await runChatAgent({
        message: String(body.message || ''),
        history: Array.isArray(body.history) ? body.history : [],
        previousPlan: body.previousPlan || null,
      });
      return sendJson(res, result);
    }
    sendJson(res, { ok: false, error: 'Not found' }, 404);
  } catch (error) {
    sendJson(
      res,
      { ok: false, error: error instanceof Error ? error.message : String(error) },
      500,
    );
  }
});

server.listen(port, () => {
  log(`listen http://127.0.0.1:${port}`);
  console.log(`GoPlan Agent Debug: http://127.0.0.1:${port}`);
});

function readLocalConfig() {
  const file = path.join(rootDir, 'lib', 'local_config.dart');
  const text = fs.existsSync(file) ? fs.readFileSync(file, 'utf8') : '';
  return {
    amapKey: readDartConst(text, 'localAmapWebServiceKey'),
    qweatherHost: readDartConst(text, 'localQWeatherApiHost'),
    deepSeekKey: readDartConst(text, 'localDeepSeekApiKey'),
  };
}

function log(message) {
  try {
    fs.mkdirSync(path.dirname(logFile), { recursive: true });
    fs.appendFileSync(logFile, `[${new Date().toISOString()}] ${message}\n`);
  } catch {
    // Logging must never break the debug server.
  }
}

function readDartConst(text, name) {
  const match = text.match(new RegExp(`const\\s+String\\s+${name}\\s*=\\s*'([^']*)'`));
  return match?.[1] || '';
}

async function runTravelAgent(query) {
  return runTravelAgentWithIntent(parseIntent(query));
}

async function runTravelAgentWithIntent(intent) {
  const searchTasks = buildSearchTasks(intent);
  const poiGroups = [];
  for (const task of searchTasks) {
    const pois = await searchAmapPois(task.keyword, task.city, task.types);
    poiGroups.push({ task, pois });
  }
  const candidates = rankPois(
    poiGroups.flatMap((group) =>
      group.pois.map((poi) => ({ ...poi, sourceKeyword: group.task.keyword, mustHave: group.task.mustHave || false })),
    ),
    intent,
  );
  const days = buildDailyPlan(candidates, intent);
  const checks = validatePlan(days, intent);

  return {
    ok: true,
    mode: 'rule-agent-v0',
    intent,
    searchTasks,
    candidateCount: candidates.length,
    days,
    checks,
    trace: [
      'parse_intent',
      'search_amap_pois',
      'rank_candidates',
      'assign_daily_routes',
      'validate_plan',
    ],
  };
}

async function runChatAgent({ message, history, previousPlan }) {
  let baseIntent;
  if (previousPlan?.intent) {
    // Use previous intent as the stable base state
    baseIntent = { ...previousPlan.intent };
  } else {
    const firstQuery = readPreviousQuery(history, null);
    baseIntent = parseIntent(firstQuery || message);
  }
  const delta = parseIntentDelta(message);
  const mergedIntent = mergeIntent(baseIntent, delta);
  const plan = await runTravelAgentWithIntent(mergedIntent);
  const actions = summarizeActions(delta);
  return {
    ok: true,
    reply: buildAgentReply(plan, actions),
    userMessage: message,
    mergedIntent,
    delta,
    actions,
    plan,
  };
}

function readPreviousQuery(history, previousPlan) {
  if (previousPlan?.intent?.query) return previousPlan.intent.query;
  for (let i = history.length - 1; i >= 0; i--) {
    const item = history[i];
    if (item?.role === 'user' && item.content) return String(item.content);
  }
  return '';
}

function parseIntentDelta(message) {
  const delta = {
    addPreferences: [],
    removePreferences: [],
    addRequiredCategories: [],
    addAvoidCategories: [],
    addLandmarks: [],
    paceOverride: null,
    dayOverride: null,
    maxJumpKmOverride: null,
    stopsPerDayOverride: null,
  };

  // ---- Remove / reduce categories ----
  if ((message.includes('\u5c11') || message.includes('\u5220') || message.includes('\u4e0d\u8981')) && message.includes('\u5496\u5561')) {
    delta.removePreferences.push('coffee');
    delta.addAvoidCategories.push('coffee');
  }
  if ((message.includes('\u5c11') || message.includes('\u5220') || message.includes('\u4e0d\u8981')) && message.includes('\u8d2d\u7269')) {
    delta.removePreferences.push('shopping');
  }

  // ---- Add categories ----
  if (message.includes('\u535a\u7269\u9986')) {
    delta.addPreferences.push('museum');
    delta.addRequiredCategories.push('museum');
  }
  if (message.includes('\u7f8e\u98df')) delta.addPreferences.push('food');
  if (message.includes('\u81ea\u7136') || message.includes('\u516c\u56ed') || message.includes('\u5c71')) delta.addPreferences.push('nature');
  if (message.includes('\u62cd\u7167')) delta.addPreferences.push('photo');
  if (message.includes('\u5496\u5561') && !delta.addAvoidCategories.includes('coffee')) delta.addPreferences.push('coffee');
  if (message.includes('\u60c5\u4fa3') || message.includes('\u7ea6\u4f1a')) delta.addPreferences.push('couple');

  // ---- Pace overrides ----
  if (message.includes('\u5c11\u8d70\u8def') || message.includes('\u592a\u7d2f') || message.includes('\u6162\u4e00\u70b9')) {
    delta.paceOverride = 'slow';
    delta.maxJumpKmOverride = 8;
    delta.stopsPerDayOverride = 3;
  }
  if (message.includes('\u591a\u8d70\u8def') || message.includes('\u7d27\u51d1\u4e00\u70b9')) {
    delta.paceOverride = 'balanced';
    delta.maxJumpKmOverride = 12;
    delta.stopsPerDayOverride = 4;
  }
  if (message.includes('\u8f7b\u677e')) {
    delta.paceOverride = 'slow';
  }

  // ---- Day overrides ----
  const msgDays = readDays(message);
  if (msgDays >= 1 && msgDays <= 10) delta.dayOverride = msgDays;

  // ---- Landmarks ----
  const known = ['\u897f\u6e56', '\u7075\u9690\u5bfa', '\u6cb3\u574a\u8857', '\u5bbd\u7a84\u5df7\u5b50', '\u9752\u6d77\u6e56', '\u6c88\u9633\u6545\u5bab', '\u6d31\u6d77', '\u4e3d\u6c5f\u53e4\u57ce'];
  for (const name of known) {
    if (message.includes(name)) delta.addLandmarks.push(name);
  }

  // ---- Destination override (user changed city) ----
  const dest = readDestination(message);
  if (dest && dest !== '\u676d\u5dde') delta.destinationOverride = dest;

  return delta;
}

function mergeIntent(base, delta) {
  const merged = {
    query: base.query,
    destination: delta.destinationOverride || base.destination,
    days: delta.dayOverride || base.days,
    preferences: [...base.preferences],
    constraints: {
      avoidCategories: [...base.constraints.avoidCategories],
      requiredCategories: [...(base.constraints.requiredCategories || [])],
      categoryLimits: { ...(base.constraints.categoryLimits || {}) },
      maxJumpKm: base.constraints.maxJumpKm,
      mustHaveLandmarks: [...(base.constraints.mustHaveLandmarks || [])],
    },
    pace: delta.paceOverride || base.pace,
    stopsPerDay: delta.stopsPerDayOverride || base.stopsPerDay,
  };

  // Merge preferences
  for (const pref of delta.addPreferences) {
    if (!merged.preferences.includes(pref)) merged.preferences.push(pref);
  }
  for (const pref of delta.removePreferences) {
    const idx = merged.preferences.indexOf(pref);
    if (idx >= 0) merged.preferences.splice(idx, 1);
  }

  // Merge avoid categories
  for (const cat of delta.addAvoidCategories) {
    if (!merged.constraints.avoidCategories.includes(cat)) merged.constraints.avoidCategories.push(cat);
  }

  // Merge required categories
  for (const cat of delta.addRequiredCategories) {
    if (!merged.constraints.requiredCategories.includes(cat)) merged.constraints.requiredCategories.push(cat);
  }

  // Merge category limits
  for (const [cat, limit] of Object.entries(delta.addAvoidCategories.reduce((acc, c) => ({ ...acc, [c]: 0 }), {}))) {
    merged.constraints.categoryLimits[cat] = 0;
  }
  for (const cat of delta.addRequiredCategories) {
    merged.constraints.categoryLimits[cat] = Math.max(merged.constraints.categoryLimits[cat] || 1, 2);
  }

  // Merge must-have landmarks
  for (const name of delta.addLandmarks) {
    if (!merged.constraints.mustHaveLandmarks.includes(name)) {
      merged.constraints.mustHaveLandmarks.push(name);
    }
  }

  // Override limits
  if (delta.maxJumpKmOverride !== null) merged.constraints.maxJumpKm = delta.maxJumpKmOverride;
  if (delta.stopsPerDayOverride !== null) merged.stopsPerDay = delta.stopsPerDayOverride;

  return merged;
}

function summarizeActions(delta) {
  const name = (cat) => categoryLabel[cat] || cat;
  const actions = [];
  if (delta.paceOverride === 'slow' && delta.maxJumpKmOverride !== null) actions.push('\u8282\u594f\u66f4\u8f7b\u677e\u3001\u51cf\u5c11\u8d70\u8def');
  if (delta.addRequiredCategories.length) actions.push(`\u589e\u52a0 ${delta.addRequiredCategories.map(name).join('\u3001')} \u4f5c\u4e3a\u5fc5\u5230\u70b9`);
  if (delta.addAvoidCategories.length) actions.push(`\u4e0d\u518d\u5b89\u6392 ${delta.addAvoidCategories.map(name).join('\u3001')} \u7c7bPOI`);
  if (delta.removePreferences.length) actions.push(`\u53bb\u9664 ${delta.removePreferences.map(name).join('\u3001')} \u504f\u597d`);
  if (delta.addLandmarks.length) actions.push(`\u52a0\u5165 ${delta.addLandmarks.join('\u3001')} \u4f5c\u4e3a\u5fc5\u5230\u666f\u70b9`);
  return actions;
}

const categoryLabel = {
  coffee: '\u5496\u5561',
  museum: '\u535a\u7269\u9986',
  food: '\u7f8e\u98df',
  shopping: '\u8d2d\u7269',
  nature: '\u81ea\u7136\u666f\u89c2',
  photo: '\u62cd\u7167',
  couple: '\u60c5\u4fa3',
  slow: '\u8f7b\u677e',
  culture: '\u6587\u5316',
  other: '\u5176\u4ed6',
};

function buildAgentReply(plan, actions) {
  const dayCount = plan.days.length;
  const totalStops = plan.days.reduce((sum, d) => sum + d.stops.length, 0);
  const actionText = actions.length
    ? `\u5df2\u6309 \u201c${actions.join('\u3001')}\u201d \u66f4\u65b0\uff1a${dayCount}\u5929\u884c\u7a0b\u5171${totalStops}\u4e2a\u7ad9\u70b9`
    : `\u5df2\u751f\u6210${dayCount}\u5929\u884c\u7a0b\uff0c\u5171${totalStops}\u4e2a\u7ad9\u70b9`;
  const issueText = plan.checks.issues.length
    ? `\u3002\u53d1\u73b0 ${plan.checks.issues.length} \u4e2a\u53ef\u4f18\u5316\u70b9\uff0c\u53ef\u4ee5\u7ee7\u7eed\u8ba9\u6211\u8c03\u6574`
    : '\u3002';
  return `${actionText}${issueText}`;
}

function parseIntent(query) {
  const days = readDays(query);
  const destination = readDestination(query);
  const preferences = [];
  const addPreference = (keyword, value) => {
    if (query.includes(keyword) && !preferences.includes(value)) {
      preferences.push(value);
    }
  };

  addPreference('\u60c5\u4fa3', 'couple');
  addPreference('\u62cd\u7167', 'photo');
  addPreference('\u5496\u5561', 'coffee');
  addPreference('\u7f8e\u98df', 'food');
  addPreference('\u4eb2\u5b50', 'family');
  addPreference('\u535a\u7269\u9986', 'museum');
  addPreference('\u81ea\u7136', 'nature');
  addPreference('\u8f7b\u677e', 'slow');
  addPreference('\u4e0d\u8981\u592a\u7d2f', 'slow');
  addPreference('\u6bd5\u4e1a', 'graduation');
  if ((query.includes('\u5c11') || query.includes('\u5220')) && query.includes('\u5496\u5561')) {
    const index = preferences.indexOf('coffee');
    if (index >= 0) preferences.splice(index, 1);
  }

  return {
    query,
    destination,
    days,
    preferences: [...new Set(preferences)],
    constraints: parseConstraints(query),
    pace: preferences.includes('slow') ? 'slow' : 'balanced',
    stopsPerDay: preferences.includes('slow') || query.includes('\u5c11\u8d70\u8def') ? 3 : 4,
  };
}

function parseConstraints(query) {
  const avoidCategories = [];
  const requiredCategories = [];
  const categoryLimits = {};

  if ((query.includes('\u5c11') || query.includes('\u5220') || query.includes('\u4e0d\u8981')) && query.includes('\u5496\u5561')) {
    avoidCategories.push('coffee');
    categoryLimits.coffee = 0;
  } else if (query.includes('\u5496\u5561')) {
    categoryLimits.coffee = 1;
  }

  if (query.includes('\u535a\u7269\u9986')) {
    requiredCategories.push('museum');
    categoryLimits.museum = 2;
  }
  if (query.includes('\u5c11\u8d70\u8def') || query.includes('\u592a\u7d2f')) {
    categoryLimits.food = 1;
  }

  return {
    avoidCategories: [...new Set(avoidCategories)],
    requiredCategories: [...new Set(requiredCategories)],
    categoryLimits,
    maxJumpKm: query.includes('\u5c11\u8d70\u8def') || query.includes('\u592a\u7d2f') ? 8 : 12,
  };
}

function readDays(query) {
  const arabic = query.match(/(\d+)\s*[\u5929\u65e5]/);
  if (arabic) return clamp(Number(arabic[1]), 1, 10);
  const cnDigits = {
    '\u4e00': 1,
    '\u4e8c': 2,
    '\u4e24': 2,
    '\u4e09': 3,
    '\u56db': 4,
    '\u4e94': 5,
    '\u516d': 6,
    '\u4e03': 7,
    '\u516b': 8,
    '\u4e5d': 9,
    '\u5341': 10,
  };
  const cn = query.match(/([\u4e00\u4e8c\u4e24\u4e09\u56db\u4e94\u516d\u4e03\u516b\u4e5d\u5341])\s*[\u5929\u65e5]/);
  return cn ? cnDigits[cn[1]] || 2 : 2;
}

function readDestination(query) {
  const known = [
    '\u676d\u5dde',
    '\u6210\u90fd',
    '\u897f\u5b81',
    '\u9752\u6d77\u6e56',
    '\u5ddd\u897f',
    '\u4e0a\u6d77',
    '\u5317\u4eac',
    '\u5927\u7406',
    '\u4e3d\u6c5f',
    '\u4e91\u5357',
    '\u53a6\u95e8',
    '\u82cf\u5dde',
    '\u5357\u4eac',
  ];
  return known.find((name) => query.includes(name)) || query.slice(0, 8).trim() || '\u676d\u5dde';
}

function buildSearchTasks(intent) {
  const destination = intent.destination;
  const tasks = [
    { keyword: `${destination} \u666f\u70b9`, city: destination, types: '110000|110100|110200' },
    { keyword: `${destination} \u7f8e\u98df`, city: destination, types: '050000' },
  ];
  for (const landmark of readLandmarks(intent.query)) {
    tasks.unshift({ keyword: landmark, city: destination, types: '110000|110100|110200', mustHave: true });
  }
  for (const name of intent.constraints.mustHaveLandmarks || []) {
    tasks.unshift({ keyword: name, city: destination, types: '110000|110100|110200', mustHave: true });
  }
  if (intent.preferences.includes('coffee') && !intent.constraints.avoidCategories.includes('coffee')) {
    tasks.push({ keyword: `${destination} \u5496\u5561`, city: destination, types: '050500' });
  }
  if (intent.preferences.includes('museum') || intent.constraints.requiredCategories.includes('museum')) {
    tasks.push({ keyword: `${destination} \u535a\u7269\u9986`, city: destination, types: '140000' });
  }
  if (intent.preferences.includes('photo')) {
    tasks.push({ keyword: `${destination} \u62cd\u7167`, city: destination, types: '110000|050000' });
  }
  if (intent.preferences.includes('nature') || intent.constraints.requiredCategories.includes('nature')) {
    tasks.push({ keyword: `${destination} \u81ea\u7136\u98ce\u666f`, city: destination, types: '110000' });
  }
  return tasks;
}

function readLandmarks(query) {
  const known = [
    '\u897f\u6e56',
    '\u7075\u9690\u5bfa',
    '\u6cb3\u574a\u8857',
    '\u5bbd\u7a84\u5df7\u5b50',
    '\u9752\u6d77\u6e56',
    '\u6c88\u9633\u6545\u5bab',
    '\u6d31\u6d77',
    '\u4e3d\u6c5f\u53e4\u57ce',
  ];
  return known.filter((name) => query.includes(name));
}

async function searchAmapPois(keyword, city, types) {
  if (!config.amapKey) return [];
  const url = new URL('https://restapi.amap.com/v3/place/text');
  url.searchParams.set('key', config.amapKey);
  url.searchParams.set('keywords', keyword);
  url.searchParams.set('city', city);
  url.searchParams.set('types', types);
  url.searchParams.set('offset', '12');
  url.searchParams.set('page', '1');
  url.searchParams.set('extensions', 'all');
  url.searchParams.set('output', 'json');

  const response = await fetch(url, { signal: AbortSignal.timeout(8000) });
  if (!response.ok) return [];
  const data = await response.json();
  if (data.status !== '1' || !Array.isArray(data.pois)) return [];
  return data.pois.map(normalizePoi).filter(Boolean);
}

function normalizePoi(poi) {
  const [lng, lat] = String(poi.location || '')
    .split(',')
    .map((part) => Number(part));
  if (!poi.name || !Number.isFinite(lng) || !Number.isFinite(lat)) return null;
  const biz = typeof poi.biz_ext === 'object' && poi.biz_ext ? poi.biz_ext : {};
  const photos = Array.isArray(poi.photos)
    ? poi.photos.map((photo) => photo?.url).filter(Boolean)
    : [];
  return {
    id: String(poi.id || poi.name),
    name: String(poi.name),
    type: String(poi.type || ''),
    typecode: String(poi.typecode || ''),
    address: String(poi.address || poi.adname || ''),
    city: String(poi.cityname || ''),
    district: String(poi.adname || ''),
    location: { lng, lat },
    rating: Number(biz.rating || 0),
    cost: Number(biz.cost || 0),
    photos,
  };
}

function rankPois(pois, intent) {
  const seen = new Set();
  return pois
    .filter((poi) => !intent.constraints.avoidCategories.includes(categoryOf(poi)))
    .filter((poi) => {
      const key = poi.name + poi.address;
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    })
    .map((poi) => ({ ...poi, score: scorePoi(poi, intent) }))
    .sort((a, b) => b.score - a.score)
    .slice(0, intent.days * Math.max(intent.stopsPerDay + 2, 6));
}

function scorePoi(poi, intent) {
  let score = 10;
  const category = categoryOf(poi);
  if (poi.mustHave) score += 20;
  if (poi.rating) score += poi.rating * 3;
  if (poi.photos.length) score += 2;
  if (poi.type.includes('\u98ce\u666f') || poi.type.includes('\u666f\u70b9')) score += 3;
  if (intent.constraints.requiredCategories.includes(category)) score += 12;
  if (intent.preferences.includes('food') && poi.type.includes('\u9910\u996e')) score += 4;
  if (intent.preferences.includes('coffee') && poi.name.includes('\u5496\u5561')) score += 3;
  if (intent.preferences.includes('museum') && poi.name.includes('\u535a\u7269\u9986')) score += 6;
  if (intent.preferences.includes('photo') && poi.sourceKeyword?.includes('\u62cd\u7167')) score += 4;
  if (intent.preferences.includes('slow') && poi.type.includes('\u8d2d\u7269')) score -= 3;
  return score;
}

function buildDailyPlan(candidates, intent) {
  const days = [];
  const stopsPerDay = intent.stopsPerDay;
  let pool = [...candidates];

  // Extract must-have POIs first
  const mustHaves = [];
  pool = pool.filter((poi) => {
    if (poi.mustHave) {
      mustHaves.push(poi);
      return false;
    }
    return true;
  });

  for (let day = 1; day <= intent.days; day++) {
    // Prefer a must-have POI as day anchor
    const mustHaveAnchor = mustHaves.shift();
    const needed = intent.constraints.requiredCategories.find(
      (category) => !days.some((item) => item.stops.some((stop) => stop.category === category)),
    );
    const preferredAnchor = mustHaveAnchor
      ? mustHaveAnchor
      : needed
        ? pool.findIndex((poi) => categoryOf(poi) === needed)
        : -1;

    let anchor;
    if (mustHaveAnchor) {
      anchor = mustHaveAnchor;
    } else if (preferredAnchor >= 0) {
      anchor = pool.splice(preferredAnchor, 1)[0];
    } else {
      const idx = pool.findIndex((poi) => categoryOf(poi) !== 'food' && categoryOf(poi) !== 'coffee');
      anchor = idx >= 0 ? pool.splice(idx, 1)[0] : pool.shift();
    }

    const selected = anchor ? chooseDayStops(anchor, pool, stopsPerDay, intent) : [];
    const selectedIds = new Set(selected.map((poi) => poi.id));
    pool = pool.filter((poi) => !selectedIds.has(poi.id));
    days.push({
      day,
      theme: buildTheme(selected, intent, day),
      stops: selected.map((poi, index) => ({
        order: index + 1,
        name: poi.name,
        category: categoryOf(poi),
        type: poi.type,
        address: poi.address,
        city: poi.city,
        district: poi.district,
        location: poi.location,
        rating: poi.rating || null,
        photo: poi.photos[0] || null,
        durationMinutes: estimateDuration(poi, intent),
        reason: buildReason(poi, intent),
      })),
    });
  }
  return days;
}

function chooseDayStops(anchor, pool, stopsPerDay, intent) {
  const selected = [anchor];
  const limits = {
    scenic: 3,
    museum: 2,
    photo: 1,
    coffee: 1,
    food: 1,
    other: 1,
    ...intent.constraints.categoryLimits,
  };
  const counts = { [categoryOf(anchor)]: 1 };
  for (const poi of nearestPois(anchor, pool)) {
    if (selected.length >= stopsPerDay) break;
    const category = categoryOf(poi);
    if (intent.constraints.avoidCategories.includes(category)) continue;
    if (distanceKm(anchor.location, poi.location) > intent.constraints.maxJumpKm) continue;
    const limit = limits[category] ?? 1;
    if ((counts[category] || 0) >= limit) continue;
    selected.push(poi);
    counts[category] = (counts[category] || 0) + 1;
  }
  if (selected.length < stopsPerDay) {
    for (const poi of nearestPois(anchor, pool)) {
      if (selected.length >= stopsPerDay) break;
      if (selected.some((item) => item.id === poi.id)) continue;
      if (intent.constraints.avoidCategories.includes(categoryOf(poi))) continue;
      if (distanceKm(anchor.location, poi.location) > intent.constraints.maxJumpKm) continue;
      selected.push(poi);
    }
  }
  return selected;
}

function categoryOf(poi) {
  const text = `${poi.name} ${poi.type}`;
  if (text.includes('\u5496\u5561')) return 'coffee';
  if (text.includes('\u9910\u996e') || text.includes('\u7f8e\u98df')) return 'food';
  if (text.includes('\u535a\u7269\u9986')) return 'museum';
  if (text.includes('\u6444\u5f71') || text.includes('\u62cd\u7167')) return 'photo';
  if (text.includes('\u98ce\u666f') || text.includes('\u666f\u70b9')) return 'scenic';
  return 'other';
}

function nearestPois(anchor, pois) {
  return [...pois].sort(
    (a, b) => distanceKm(anchor.location, a.location) - distanceKm(anchor.location, b.location),
  );
}

function buildTheme(stops, intent, day) {
  if (!stops.length) return `Day ${day}`;
  if (intent.preferences.includes('slow')) return '\u8f7b\u677e\u6162\u6e38';
  if (intent.preferences.includes('photo')) return '\u62cd\u7167\u4e0e\u57ce\u5e02\u6f2b\u6b65';
  if (stops.some((poi) => poi.type.includes('\u98ce\u666f'))) return '\u7ecf\u5178\u98ce\u666f\u8def\u7ebf';
  return '\u7ecf\u5178\u57ce\u5e02\u8def\u7ebf';
}

function estimateDuration(poi, intent) {
  if (poi.type.includes('\u9910\u996e')) return 75;
  if (poi.type.includes('\u535a\u7269\u9986')) return 120;
  return intent.pace === 'slow' ? 120 : 90;
}

function buildReason(poi, intent) {
  if (intent.preferences.includes('coffee') && poi.name.includes('\u5496\u5561')) {
    return '\u7b26\u5408\u5496\u5561\u548c\u8f7b\u677e\u4f11\u606f\u504f\u597d';
  }
  if (intent.preferences.includes('photo')) {
    return '\u9002\u5408\u62cd\u7167\u548c\u6162\u901f\u6f2b\u6b65';
  }
  if (poi.rating) return '\u8bc4\u5206\u548c\u70ed\u5ea6\u8f83\u9ad8';
  return '\u4e0e\u672c\u6b21\u884c\u7a0b\u504f\u597d\u5339\u914d';
}

function validatePlan(days, intent) {
  const issues = [];
  for (const day of days) {
    if (day.stops.length > intent.stopsPerDay + 1) {
      issues.push({ level: 'warn', message: `Day ${day.day} has many stops` });
    }
    const jumps = [];
    for (let i = 1; i < day.stops.length; i++) {
      const km = distanceKm(day.stops[i - 1].location, day.stops[i].location);
      if (km > intent.constraints.maxJumpKm) {
        jumps.push({ from: day.stops[i - 1].name, to: day.stops[i].name, km });
      }
    }
    if (jumps.length) {
      issues.push({ level: 'warn', message: `Day ${day.day} has long jumps`, jumps });
    }
  }
  return {
    ok: issues.length === 0,
    issues,
  };
}

function distanceKm(a, b) {
  const rad = Math.PI / 180;
  const dLat = (b.lat - a.lat) * rad;
  const dLng = (b.lng - a.lng) * rad;
  const lat1 = a.lat * rad;
  const lat2 = b.lat * rad;
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  return 6371 * 2 * Math.asin(Math.sqrt(h));
}

function clamp(value, min, max) {
  return Math.min(max, Math.max(min, value));
}

function sendFile(res, file, contentType) {
  res.writeHead(200, { 'content-type': `${contentType}; charset=utf-8` });
  res.end(fs.readFileSync(file));
}

function sendJson(res, data, status = 200) {
  res.writeHead(status, { 'content-type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify(data, null, 2));
}

function readJson(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', (chunk) => {
      body += chunk;
      if (body.length > 1024 * 1024) {
        req.destroy(new Error('Request body too large'));
      }
    });
    req.on('end', () => {
      try {
        resolve(body ? JSON.parse(body) : {});
      } catch (error) {
        reject(error);
      }
    });
    req.on('error', reject);
  });
}
