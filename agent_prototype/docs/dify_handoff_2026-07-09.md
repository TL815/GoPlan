# GoPlan Dify Handoff

Last updated: 2026-07-09

## Purpose

This document is a restart/handoff note for future Codex or operator sessions.
It captures the current Dify workflow state for `GoPlan`, the intended next-step
canvas structure, and how that workflow fits into the larger `圆周旅迹` AI
implementation roadmap.

## Dify Workspace

- Product: `GoPlan`
- Dify page:
  `https://cloud.dify.ai/app/f826b386-3b4d-4311-993f-508399260786/workflow`
- Current editing target: Chatflow / workflow canvas

## Current Dify Goal

Replace the old direct chain:

```text
用户输入 -> GoPlan Agent v2 -> 直接回复
```

with a clearer layered travel-planning flow:

```text
用户输入 -> 参数提取器 -> 条件分支
IF needs_clarification contains yes -> 直接回复 2
ELSE -> GoPlan Agent v2 -> 直接回复
```

## What Has Already Been Configured

The following items were already completed in Dify:

1. Added `参数提取器` node.
2. Set the extractor model to `deepseek-v4-flash`.
3. Bound extractor input variable to `用户输入 / query`.
4. Added these extractor fields:
   - `intent`
   - `destination`
   - `duration_days`
   - `start_date`
   - `budget`
   - `preferences`
   - `missing_slots`
   - `needs_clarification`
   - `clarifying_question`
5. Filled the extractor instruction with this behavior:
   - Only extract from explicit user input.
   - Do not invent facts.
   - If `destination` or `duration_days` is missing, set
     `needs_clarification=yes`.
   - If the user is modifying, extending, or optimizing an existing itinerary,
     prefer the matching intent.
   - If nothing important is missing, set `missing_slots=empty`.
   - Ask only one highest-priority clarification question.
6. Added `条件分支` node.
7. Configured branch IF rule as:
   `参数提取器 / needs_clarification` contains `yes`.
8. Added `直接回复 2` node for missing-parameter follow-up.
9. Bound `直接回复 2` response content to:
   `参数提取器 / clarifying_question`.
10. Connected IF branch to `直接回复 2`.
11. Connected ELSE branch to existing `GoPlan Agent v2`.
12. Kept `GoPlan Agent v2` connected to the original `直接回复`.

## Suspected Canvas Cleanup Item

There may still be an extra bypass connection on the canvas:

```text
参数提取器 -> GoPlan Agent v2
```

This line is not desired in the target design.

Because Dify canvas selection can be finicky, a previous attempt to remove the
line risked selecting the wrong node or affecting nearby edges. Future sessions
should manually inspect the canvas and clean this edge carefully.

## Target Canvas State

The desired final structure for this stage is:

```text
用户输入 -> 参数提取器 -> 条件分支
条件分支 IF -> 直接回复 2
条件分支 ELSE -> GoPlan Agent v2
GoPlan Agent v2 -> 直接回复
```

Only those paths should remain for this MVP gate.

## Why This Structure Matters

This is the first real separation of responsibilities in Dify:

- `参数提取器` handles intent and slot extraction.
- `条件分支` decides whether enough information exists.
- `直接回复 2` handles missing-info clarification.
- `GoPlan Agent v2` focuses on itinerary generation or rewrite work only after
  required slots are present.

This reduces prompt overload inside a single agent and creates a more stable
travel-planning entry workflow.

## Relationship To The Larger 圆周旅迹 Roadmap

The full `圆周旅迹 AI 执行流程图` describes a much broader system than the
current Dify MVP. The current Dify workflow only covers the front part of the
roadmap.

### Stage Mapping

Current Dify work mainly belongs to:

1. `输入阶段`
2. `AI 意图理解`
3. The first decision gate before deeper planning

The broader roadmap still includes later layers:

1. Multi-input ingestion:
   - 攻略链接导入
   - 图片导入
   - 文本粘贴
   - 手动输入
2. Content parsing:
   - OCR / LLM parsing
   - Information extraction
   - Entity recognition
   - Structured organization
3. Place processing:
   - 地点标准化
   - POI 匹配
   - 信息补全
   - 分类标注
4. User selection:
   - 地点列表展示
   - 勾选去除
   - 地点收藏
   - 优先级设置
5. Route planning:
   - 路线优化
   - 时间分配
   - 交通计算
   - 行程平衡
6. Itinerary generation:
   - 行程详情生成
   - 交通建议
   - 餐饮推荐
   - 实用信息
7. Collaboration and optimization:
   - 多人协作
   - 实时同步
   - 智能优化建议
   - 动态调整

## Recommended Build Order

To keep the implementation stable, future sessions should continue in this
order:

1. Finish the current Dify branch cleanup and verify the canvas wiring.
2. Validate extractor behavior with sample inputs:
   - missing destination
   - missing duration
   - complete new trip request
   - itinerary rewrite / optimization request
3. Confirm `GoPlan Agent v2` receives only the cases that have enough required
   input.
4. After this gate is stable, consider adding later-stage capabilities such as:
   - structured place list extraction
   - POI normalization
   - route and daily plan generation

## Suggested Test Prompts

Use these prompts when continuing the Dify workflow work:

### Clarification expected

```text
帮我规划一个旅行
```

Expected:

- `needs_clarification=yes`
- returns exactly one critical follow-up question

### Missing duration

```text
我想去杭州玩，喜欢美食和自然风景
```

Expected:

- `destination=杭州`
- `needs_clarification=yes`
- asks about duration or trip length

### New plan, complete enough

```text
帮我规划杭州3天轻松游，预算3000左右，喜欢美食和自然风景
```

Expected:

- extractor fills major slots
- branch enters ELSE
- request goes to `GoPlan Agent v2`

### Rewrite / optimize existing itinerary

```text
我已经有一个杭州3天行程了，帮我优化路线，少走回头路
```

Expected:

- extractor should prefer a rewrite / optimize intent
- if key planning context is sufficient, branch enters ELSE

## Notes For Future Sessions

- Do not assume the current canvas is perfectly clean.
- Manually inspect whether `参数提取器 -> GoPlan Agent v2` still exists.
- Treat the current Dify workflow as an MVP orchestration layer, not the full
  travel system.
- The larger `圆周旅迹` roadmap should be implemented progressively rather than
  collapsed into one oversized prompt.
