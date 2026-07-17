# GoPlan 项目文档

这个目录存放 GoPlan 的完整项目文档，涵盖需求、设计、开发、测试各个阶段。

## 文档索引

| 文档 | 用途 | 受众 |
|------|------|------|
| [prd.md](prd.md) | 产品需求文档：功能范围、目标用户、成功指标 | 全员 |
| [design-spec.md](design-spec.md) | UI/UX设计规范：色彩、字体、组件、布局、动效 | 设计/前端 |
| [architecture.md](architecture.md) | 技术架构：技术栈、运行结构、数据流、信任边界 | 开发 |
| [api-design.md](api-design.md) | API接口设计：认证、行程、AI、协作、POI搜索接口 | 前后端 |
| [database-design.md](database-design.md) | 数据库设计：ER图、表结构、索引、性能策略 | 后端 |
| [flows.md](flows.md) | 关键流程：涉及信任边界、权限、原生桥接的流程 | 开发/测试 |
| [permissions.md](permissions.md) | 权限模型：系统权限、角色、资源操作矩阵 | 开发/安全 |
| [variables.md](variables.md) | 配置与密钥：Key管理、环境变量、上线检查项 | 开发/DevOps |
| [test-plan.md](test-plan.md) | 测试计划：单元/Widget/集成/API/性能/安全测试用例 | QA |
| [roadmap.md](roadmap.md) | 开发计划与路线图：版本节奏、任务分解、风险评估 | 全员 |
| [dev-standards.md](dev-standards.md) | 开发规范：代码规范、Git规范、安全规范、发布流程 | 开发 |
| [deployment.md](deployment.md) | 部署指南：环境搭建、构建发布、CI/CD、后端部署 | 开发/DevOps |
| [screenshots/calendar_preview.png](screenshots/calendar_preview.png) | 日期组件视觉验收截图 | 设计/前端/QA |

## 快速导航

### 产品
- 想了解产品方向？→ [prd.md](prd.md)
- 想了解版本计划？→ [roadmap.md](roadmap.md)

### 设计
- 想查看设计规范？→ [design-spec.md](design-spec.md)

### 开发
- 想了解技术架构？→ [architecture.md](architecture.md)
- 想查看API接口？→ [api-design.md](api-design.md)
- 想了解数据库结构？→ [database-design.md](database-design.md)
- 想搭建开发环境？→ [deployment.md](deployment.md)
- 想知道编码规范？→ [dev-standards.md](dev-standards.md)

### 测试
- 想编写测试用例？→ [test-plan.md](test-plan.md)
- 想了解权限边界？→ [permissions.md](permissions.md)
- 想了解关键流程？→ [flows.md](flows.md)
- 想检查配置安全？→ [variables.md](variables.md)

## 当前项目状态

GoPlan v0.1：Flutter 原型已完成，包含启动页、首页（行程卡片+路线预览）、探索页（Mock地图+POI筛选）、底部导航、Android/iOS原生地图桥接骨架。

下一里程碑：v0.5 Alpha（AI对话能力 + 真实数据模型 + 后端API框架）
## UiAction Preview

```bash
flutter run -t lib/features/ai_chat/ui_action/preview/ui_action_preview_app.dart
```

## AI Chat Runtime

P0-R5.2 已将默认 AI 聊天页接入 `TravelAssistantController`、
`DifyTravelAssistantGateway` 以及 UiAction 监听/分发链路。
上方旧预览入口仍保留用于 P0-R5.1 组件检查。

本地运行示例仅使用占位值：

```bash
flutter run \
  --dart-define=DIFY_API_BASE=https://api.dify.ai/v1 \
  --dart-define=DIFY_API_KEY=replace-with-test-key \
  --dart-define=DIFY_USER_ID=goplan-local-user \
  --dart-define=DIFY_TRIP_ID=goplan-local-trip \
  --dart-define=GOPLAN_TIMEZONE=Asia/Shanghai
```

不要把真实 Dify Key 写入文档、源码、截图或日志。

## Conversation Store

P0-R6.0 新增本地 Assistant 会话缓存边界：

```text
TravelAssistantState -> AssistantConversationSnapshot -> ConversationStore
```

P0 实现通过数据层适配器使用 `shared_preferences`，存储带版本号的 JSON 文档。它仅用于本地测试和早期历史恢复；正式数据源后续应迁移到后端或数据库存储。

本地缓存只保存可见会话文本和 Assistant 规划状态，不保存 API Key、Authorization header、Dify 原始响应、`failure.cause` 或待处理 UiAction 数据。不要在文档中加入真实用户样例数据。

P0-R6.1 已将该缓存接入正式 AI 聊天流程。打开默认 AI 聊天入口时，会尝试恢复当前行程的最新本地会话；如果不存在，则创建新的本地会话。Controller 状态变化会 debounce 自动保存，页面退出前 runtime 会 flush。

首页探索历史区域现在从 `ConversationStore` 读取本地 Assistant 会话摘要。点击历史项会用 `resumeById` 打开正式 AI 聊天页，恢复消息与规划状态，后续发送继续走 `DifyTravelAssistantGateway`。

这仍是 P0 本地缓存。清空本地 App 存储会删除历史记录，正式生产链路应将会话同步迁移到后端。不要把真实用户会话复制到文档或 fixture 中。

P0-R6.2 已移除旧内存 `ConversationService`、`AiConversation` / `ConvMessage`、探索页旧聊天兼容块，以及未使用的 `AiTravelAgent` / `DifyTravelAgent` 文件。正式 AI 入口使用上方 runtime/controller/gateway 链路，历史记录使用 `ConversationStore`。

## 标准行程 UI

P0-R7 后，正式 AI 聊天页会展示标准 `Itinerary` 摘要卡：标题、目的地、天数、草案状态、总预算、风险提示数量和前三天概览。用户可以从摘要卡进入完整行程详情页。

完整详情页展示全部每日行程、时间线项目、地点名称、分类、地址或城市、交通方式、交通时间、停留时长、费用和 tips。预算使用 `BudgetSummary`，风险提示使用 `ItineraryWarning`，页面不会显示内部 id、坐标、source、conversationId 或原始 JSON。

当前地图路线尚未接入；`showMap` 只给出安全提示。标准 Place 坐标、地图 Marker 和每日路线将在 P0-R8 实现。
