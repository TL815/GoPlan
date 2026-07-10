# Dify Workflow Draft

App: GoPlan

Current status:

```text
Draft saved in Dify.
Not published yet.
```

## Workflow Shape

```text
Start
  -> GoPlan Agent v2: Plan / Rewrite / Validate
  -> Direct Reply
```

The current Dify draft keeps the canvas compact but upgrades the LLM node into a
multi-stage travel agent kernel. It returns strict JSON so the Flutter app or the
standalone Dart prototype can parse the response.

## LLM Node

Title:

```text
GoPlan Agent v2：规划/改写/校验
```

Description:

```text
多阶段旅行 Agent：意图识别、槽位抽取、缺参追问、行程生成/改写、质量自检、Flutter JSON 输出。
```

Model:

```text
deepseek-v4-pro
```

Internal stages:

```text
Intent Extractor
  -> Slot Extractor
  -> Completeness Gate
  -> Planner / Rewriter
  -> Quality Checker
  -> Flutter Adapter
```

The V2 JSON contract includes:

- `meta.agentVersion`
- `meta.intent`
- `meta.confidence`
- `replyText`
- `needClarification`
- `assumptions`
- `extractedSlots`
- `nextQuestions`
- `planDraft`
- `qualityReport`
- `uiHints`

## Smoke Tests

Clarification input:

```text
帮我规划一个旅行
```

Expected behavior:

- `meta.intent` is `clarify`.
- `needClarification` is `true`.
- `planDraft` is `null`.
- `nextQuestions` contains concrete questions about destination, days, people,
  and interests.

Plan input:

```text
我想去杭州玩3天，节奏轻松一点，喜欢美食和自然风景，请帮我规划。
```

Expected behavior:

- Returns strict JSON.
- Includes `replyText`, `assumptions`, and `planDraft`.
- Generates 3 days for Hangzhou.
- Includes daily routes, places, food, tips, budget tips, packing tips, and risk
  notes.

## Enabled App Features

Conversation opener:

```text
你好，我是 GoPlan 旅行规划助手。你可以告诉我想去哪里、玩几天、同行人、预算和偏好，我会帮你生成可执行的每日路线；如果信息还不够，我会先用几个问题帮你补齐。
```

Opening questions:

```text
帮我规划杭州3天轻松游，喜欢美食和自然风景
帮我做一个适合亲子或老人同行的低强度行程
帮我优化已有行程，让路线更顺、不要太赶
我有一份攻略，帮我整理成每天路线
```

Next-question suggestions:

```text
Enabled.
Mode: system default model.
```

File upload:

```text
Enabled.
Supported type: image.
Max upload count: 3.
```

Content moderation:

```text
Not configured.
```

Reason:

```text
The current Dify feature panel does not expose a usable moderation setup for this
app. Do not enable an empty moderation switch. Configure it later with a concrete
sensitive-word list or moderation provider.
```

Citation / attribution:

```text
Not configured.
```

Reason:

```text
There is no connected knowledge base or retrieval source yet.
```

## Next Improvements

- Split the single LLM node into real Dify workflow stages:
  `extract slots -> branch -> clarify or plan -> validate -> reply`.
- Add POI search, weather, and route tools after the prompt-only version is
  stable.
- Add explicit Dify structured output schema if the API consumer needs stricter
  server-side validation.
- Publish only after confirming the Flutter/API consumer is ready for this JSON
  response format.
