# GoPlan API 接口设计文档

> 版本 v1.0 | 状态：设计阶段

## 1. 设计原则

- RESTful 风格，资源导向的 URL 设计
- 统一响应格式，所有接口返回 JSON
- JWT Token 认证，Authorization Header 传递
- 分页、排序、过滤参数标准化
- 版本号通过 URL 路径前缀管理（`/api/v1/`）

## 2. 通用规范

### 2.1 基础 URL

```
开发环境: https://dev-api.goplan.cn/api/v1
生产环境: https://api.goplan.cn/api/v1
```

### 2.2 通用请求头

| Header | 值 | 说明 |
|--------|-----|------|
| `Content-Type` | `application/json` | 请求体格式 |
| `Authorization` | `Bearer {token}` | 用户认证Token |
| `Accept-Language` | `zh-CN` | 语言偏好 |
| `X-Client-Version` | `1.0.0` | 客户端版本号 |

### 2.3 统一响应格式

```json
{
  "code": 0,
  "message": "success",
  "data": {},
  "timestamp": 1719705600000
}
```

### 2.4 错误码定义

| Code | 说明 |
|------|------|
| 0 | 成功 |
| 10001 | 参数错误 |
| 10002 | 未登录/Token过期 |
| 10003 | 权限不足 |
| 10004 | 资源不存在 |
| 10005 | 操作冲突（如重复创建） |
| 20001 | AI服务异常 |
| 20002 | AI生成失败 |
| 30001 | 地图服务异常 |
| 50001 | 服务器内部错误 |

### 2.5 分页规范

```json
{
  "page": 1,
  "page_size": 20,
  "total": 156,
  "total_pages": 8,
  "items": []
}
```

---

## 2.6 GoPlan 标准 AI 协议

P0-R2 起，App 与 AI/Agent 能力之间使用 GoPlan 标准领域协议。Dify、业务后端或自定义 Agent Adapter 必须输出 `AssistantResponse`，App 侧交互必须回传 `ClientEvent`。外部服务的原始 JSON 不得直接进入 Widget。

### AssistantResponse 示例

```json
{
  "schema_version": "1.0",
  "conversation_id": "conv_01JXYZ",
  "status": "need_input",
  "message": "请选择旅行日期",
  "missing_fields": ["start_date", "end_date"],
  "trip_state": {
    "destination": "云南",
    "duration_days": 6
  },
  "itinerary": null,
  "warnings": [],
  "ui_action": {
    "type": "request_date_range",
    "field": "travel_dates",
    "allow_custom_input": true,
    "options": []
  }
}
```

`conversation_id` 是 provider 无关的不透明 Assistant 会话标识。首轮响应可以带回新的 `conversation_id`，Controller 保存后在下一轮 `AssistantRequest.conversation_id` 中显式回传。客户端不生成 `conversation_id`，不向普通用户展示该值；它不是认证凭据，但日志仍应避免无必要完整输出。

### ClientEvent 示例

```json
{
  "type": "date_range_selected",
  "field": "date_range",
  "payload": {
    "start_date": "2026-07-15",
    "end_date": "2026-07-20"
  },
  "occurred_at": "2026-07-15T08:00:00.000"
}
```

`payload` 中的日期统一使用 `YYYY-MM-DD`。`occurred_at` 使用 ISO 8601。

### TravelAssistantGateway 输入输出

Gateway 输入为 `AssistantRequest`，输出为 `AssistantResponse`。`AssistantRequest` 必须显式携带 `user_id`、`trip_id`、可选 `conversation_id`、`query`、`event`、`trip_snapshot` 和 `timezone`。

首轮请求示例：

```json
{
  "user_id": "user_123",
  "trip_id": "trip_456",
  "query": "想去云南玩 6 天",
  "event": {
    "type": "chat_message",
    "field": "message",
    "payload": {
      "message": "想去云南玩 6 天"
    },
    "occurred_at": "2026-07-15T08:00:00.000"
  },
  "trip_snapshot": {},
  "timezone": "Asia/Shanghai"
}
```

后续请求示例：

```json
{
  "user_id": "user_123",
  "trip_id": "trip_456",
  "conversation_id": "conv_01JXYZ",
  "query": "",
  "event": {
    "type": "date_selected",
    "field": "date",
    "payload": {
      "date": "2026-07-20"
    },
    "occurred_at": "2026-07-15T08:02:00.000"
  },
  "trip_snapshot": {
    "destination": "云南"
  },
  "timezone": "Asia/Shanghai"
}
```

Transport error 不属于标准响应 JSON。网络、超时、配置错误、鉴权失败、限流、取消或响应无法解析时，App 内应映射为 `TravelAssistantFailure`，并通过 `TravelAssistantException` 进入错误边界。可解析的业务错误仍然可以作为标准 JSON 返回，例如：

```json
{
  "schema_version": "1.0",
  "status": "error",
  "message": "当前行程缺少出发日期",
  "missing_fields": ["start_date"],
  "warnings": [],
  "ui_action": {
    "type": "request_start_date",
    "field": "start_date",
    "allow_custom_input": true,
    "options": []
  }
}
```

### Dify `/chat-messages` Adapter 请求

P0 阶段 Dify Gateway 使用 blocking 模式调用 `/chat-messages`。请求示例：

```json
{
  "inputs": {
    "trip_id": "trip_456",
    "user_id": "user_123",
    "timezone": "Asia/Shanghai",
    "client_event": "date_range_selected",
    "client_field": "date_range",
    "backend_snapshot": "{\"destination\":\"云南\"}",
    "client_event_payload": "{\"start_date\":\"2026-08-03\",\"end_date\":\"2026-08-09\"}",
    "start_date": "2026-08-03",
    "end_date": "2026-08-09"
  },
  "query": "用户已选择旅行日期范围",
  "response_mode": "blocking",
  "user": "user_123",
  "conversation_id": "conv_01JXYZ"
}
```

规则：

- `inputs.trip_id`、`inputs.user_id`、`inputs.timezone`、`inputs.client_event`、`inputs.backend_snapshot` 为固定字段。
- `backend_snapshot` 是 JSON 字符串，不是嵌套对象。
- `ClientEvent.payload` 会展平到 `inputs`；其中 Map/List 会转换为 JSON 字符串。
- payload 不得覆盖保留字段：`trip_id`、`user_id`、`timezone`、`client_event`、`backend_snapshot`、`client_field`。
- `client_event_payload` 保存完整 payload JSON 字符串，便于 Dify workflow 兜底读取。
- `conversation_id` 只出现在 Dify 顶层；为空时不输出。
- `query` 非空时使用用户文本；为空时按 `ClientEventType` 生成安全 fallback，不暴露完整 payload。

HTTP 错误映射：

| HTTP 状态 | Failure type | retryable |
| --- | --- | --- |
| 400, 422 | `invalidRequest` | false |
| 401, 403 | `unauthorized` | false |
| 429 | `rateLimited` | true |
| 500, 502, 503, 504 | `serviceUnavailable` | true |
| 其他 400-499 | `invalidRequest` | false |
| 其他 500-599 | `serviceUnavailable` | true |
| 其他非 2xx | `unknown` | false |

重试规则：仅 `network`、`timeout`、`rateLimited`、`serviceUnavailable` 会有限重试；默认最多 3 次，延迟为 700ms、1400ms。`invalidResponse`、`unauthorized`、`invalidRequest` 不重试。

### TravelAssistantController 请求编排

P0-R4 起，页面后续接入 AI 能力时应通过 `TravelAssistantController` 构造标准 `AssistantRequest`。Controller 是纯 Dart 应用层状态机，不创建 Dify Gateway、不读取 API Key、不依赖 Widget、BuildContext、http 或任何地图/天气 SDK。

`sendMessage(text)` 规则：

- `text.trim()` 为空时不创建消息、不调用 Gateway，返回 null。
- 非空文本会创建 `ClientEvent.chatMessage` 等价事件，并添加一条 user message。
- `AssistantRequest.userId`、`tripId`、`conversationId`、`timezone` 来自当前 Controller state。
- `query` 使用 trim 后文本。
- `tripSnapshot` 使用当前 `TripState.toJson()`；当前无 `TripState` 时使用空对象。
- 请求期间 phase 为 `sending`；同一 Controller 在 `sending` 时拒绝第二个请求。

`submitEvent(event, query, displayText)` 规则：

- 用于日期、选项、数字、确认等结构化 UI 事件回传。
- Controller 不展开 `ClientEvent.payload`，也不转换为 Dify inputs。
- `displayText` 只用于 user message 展示；未提供时使用稳定安全 fallback 文案，不输出完整 payload。
- `query` 可以为空，由具体 Gateway/Adapter 在需要时生成 provider fallback。

`retryLast()` 规则：

- 仅当最近一次失败存在且 `lastFailure.retryable == true` 时执行。
- 重试不会重复添加上一条 user message。
- 重试保存原始 `query`、`ClientEvent` 和 `displayText`，但重新使用当前 state 中最新的 `conversationId`、`tripState` 和 `timezone` 构造请求。
- Gateway automatic retry 是一次请求内部的传输重试；Controller `retryLast()` 表示用户主动再次发起上一操作。

响应合并规则：

- `response.conversationId` 非空时更新；为空时保留当前值。
- `response.tripState` 非空时替换当前 `TripState`；为空时保留当前值。
- `response.itinerary` 非空时替换当前 `Itinerary`；为空时保留当前值。
- `response.warnings` 总是替换当前 warnings，空列表表示清除旧 warning。
- `response.uiAction` 总是替换当前 uiAction，`UiAction.none()` 表示清除旧交互动作。
- `assistantStatus` 更新为 `response.status`，`lastResponse` 更新为当前 response，`lastFailure` 清空。
- `AssistantResponse.status == error` 是业务 error，Controller phase 仍为 `ready`。

失败合并规则：

- Gateway 抛出的 `TravelAssistantException` 被 Controller 捕获，不继续抛给 UI。
- phase 更新为 `failure`，`lastFailure` 设置为 exception.failure。
- 不添加虚假的 assistant success message。
- 保留已有 `conversationId`、`TripState`、`Itinerary`、`warnings`、`uiAction`、`assistantStatus` 和 `lastResponse`。
- 非 `TravelAssistantException` 会转为 `TravelAssistantFailureType.unknown`，message 使用安全通用文案，不包含原异常完整字符串。

### UiActionDispatcher 事件映射

P0-R5 起，结构化 `ui_action` 由 `UiActionDispatcher` 分派到 `UiActionInteractionPort`。Dispatcher 不创建 Flutter 组件，不读取 Dify 原始 JSON，不保存 `conversationId`，只在用户完成交互后调用 `TravelAssistantController.submitEvent()`。

映射表：

| UiActionType | ClientEventType | 默认 field | displayText | query |
| --- | --- | --- | --- | --- |
| `requestStartDate` | `dateSelected` | `start_date` | `Start date: YYYY-MM-DD` | 空字符串 |
| `requestDateRange` | `dateRangeSelected` | `travel_dates` | `Travel dates: YYYY-MM-DD to YYYY-MM-DD` | 空字符串 |
| `selectOption` | `optionSelected` | `option` | option.label | 空字符串 |
| `inputNumber` | `numberSubmitted` | `number` | 按 field 生成安全文案 | 空字符串 |
| `confirm` | `confirmationSubmitted` | `confirmation` | `Confirmed` 或 `Confirmation declined` | 空字符串 |
| `confirmDateConflict` | `dateConflictResolved` | `date_conflict` | option.label | 空字符串 |
| `showItinerary` / `showMap` / `showBudget` | 无 | 无 | 无 | 无 |
| `none` / `unknown` | 无 | 无 | 无 | 无 |

事件示例：

```json
{
  "type": "date_selected",
  "field": "start_date",
  "payload": {
    "start_date": "2026-08-03"
  },
  "occurred_at": "2026-07-15T09:30:00.000"
}
```

```json
{
  "type": "date_range_selected",
  "field": "travel_dates",
  "payload": {
    "start_date": "2026-08-03",
    "end_date": "2026-08-09"
  },
  "occurred_at": "2026-07-15T09:30:00.000"
}
```

```json
{
  "type": "option_selected",
  "field": "option",
  "payload": {
    "option_id": "slow",
    "value": "slow",
    "label": "Slow pace"
  },
  "occurred_at": "2026-07-15T09:30:00.000"
}
```

```json
{
  "type": "number_submitted",
  "field": "traveler_count",
  "payload": {
    "value": 3
  },
  "occurred_at": "2026-07-15T09:30:00.000"
}
```

```json
{
  "type": "confirmation_submitted",
  "field": "confirmation",
  "payload": {
    "confirmed": false
  },
  "occurred_at": "2026-07-15T09:30:00.000"
}
```

```json
{
  "type": "date_conflict_resolved",
  "field": "date_conflict",
  "payload": {
    "option_id": "keep",
    "value": "keep_selected_dates",
    "label": "Keep selected dates"
  },
  "occurred_at": "2026-07-15T09:30:00.000"
}
```

规则：

- `action.field` 非空时优先使用；为空字符串或 null 时使用映射表 fallback。
- 用户取消或关闭组件时不创建、不提交 `ClientEvent`。
- passive action 只提示 UI 可展示已有状态，不创建 `ClientEvent`。
- `displayText` 是用户消息气泡文案；`query` 保持空字符串，由 Gateway/Adapter 负责需要时的 provider fallback。
- Dispatcher 不把 `action.payload` 自动合并进 event payload。
- 复杂 option value 原样进入 payload，由 DifyRequestMapper 或后端 Adapter 负责后续请求转换。

### Flutter UiAction 交互字段约定

Flutter adapter 只读取 `UiAction` 中的展示与输入约束字段，不直接调用 Gateway，也不创建 `ClientEvent`。用户完成输入后，返回值由 Dispatcher 转换为标准 `ClientEvent`。

通用 UI 字段：

- `action.title`：组件标题；为空时使用组件 fallback。
- `action.description`：辅助说明；为空时不显示说明。
- Port 返回 `null` 表示用户取消、关闭或未提交。
- `confirm` 返回 `false` 表示用户明确否定，不等于取消。

选项交互：

- `options` 用于展示候选项。
- `allow_custom_input == true` 时，Flutter adapter 可展示自定义输入入口。
- 自定义输入会 trim；空文本不能提交。
- 自定义选项返回 `UiActionOption(id: "custom", label: text, value: text)`。
- 自定义选项不会写回 `action.options`。

日期 payload 建议字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `initial_date` | `YYYY-MM-DD` 或 DateTime | 单日期初始值 |
| `start_date` | `YYYY-MM-DD` 或 DateTime | 日期范围开始，或单日期兜底初始值 |
| `end_date` | `YYYY-MM-DD` 或 DateTime | 日期范围结束 |
| `first_date` | `YYYY-MM-DD` 或 DateTime | 可选最早日期 |
| `last_date` | `YYYY-MM-DD` 或 DateTime | 可选最晚日期 |

数字 payload 建议字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `min` | num 或数字字符串 | 最小值 |
| `max` | num 或数字字符串 | 最大值 |
| `initial_value` | num 或数字字符串 | 输入框初始值 |
| `prefix` | string | 输入框前缀展示 |
| `suffix` | string | 输入框后缀展示 |

确认按钮 payload 建议字段：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `confirm_label` | string | 确认按钮文案 |
| `cancel_label` | string | 否定按钮文案 |

## 3. 认证模块

### 3.1 发送验证码

```
POST /auth/send-code
```

**请求体**
```json
{
  "phone": "13800138000"
}
```

**响应**
```json
{
  "code": 0,
  "message": "验证码已发送",
  "data": { "expire_seconds": 300 }
}
```

### 3.2 登录/注册

```
POST /auth/login
```

**请求体**
```json
{
  "phone": "13800138000",
  "code": "123456"
}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "token": "eyJhbG...",
    "refresh_token": "eyJhbG...",
    "expires_in": 86400,
    "user": {
      "id": "u_abc123",
      "nickname": "旅行者张三",
      "avatar": "https://cdn.goplan.cn/avatars/abc123.webp",
      "phone": "138****8000",
      "created_at": "2026-01-01T00:00:00Z"
    }
  }
}
```

### 3.3 刷新Token

```
POST /auth/refresh
```

**请求体**
```json
{
  "refresh_token": "eyJhbG..."
}
```

### 3.4 登出

```
POST /auth/logout
```

---

## 4. 用户模块

### 4.1 获取用户信息

```
GET /users/me
```

**响应**
```json
{
  "code": 0,
  "data": {
    "id": "u_abc123",
    "nickname": "旅行者张三",
    "avatar": "https://cdn.goplan.cn/avatars/abc123.webp",
    "bio": "热爱山川湖海",
    "travel_count": 12,
    "plan_count": 5
  }
}
```

### 4.2 更新用户信息

```
PATCH /users/me
```

**请求体**
```json
{
  "nickname": "新昵称",
  "avatar": "https://...",
  "bio": "新的简介"
}
```

---

## 5. 行程模块

### 5.1 行程列表

```
GET /plans
```

**查询参数**

| 参数 | 类型 | 说明 |
|------|------|------|
| `page` | int | 页码 |
| `page_size` | int | 每页数量 |
| `status` | string | 筛选状态：planning/ongoing/completed |
| `sort` | string | 排序：created_at/start_date |

**响应**
```json
{
  "code": 0,
  "data": {
    "page": 1,
    "page_size": 20,
    "total": 5,
    "items": [
      {
        "id": "p_001",
        "title": "青甘大环线10天游",
        "cover": "https://cdn.goplan.cn/covers/p_001.webp",
        "destination": "青海·甘肃",
        "start_date": "2026-07-15",
        "end_date": "2026-07-25",
        "days": 10,
        "places_count": 15,
        "members_count": 4,
        "status": "planning",
        "countdown": 17,
        "accent_color": "#69A7FF",
        "created_at": "2026-06-01T00:00:00Z"
      }
    ]
  }
}
```

### 5.2 行程详情

```
GET /plans/{plan_id}
```

**响应**（关键字段）
```json
{
  "code": 0,
  "data": {
    "id": "p_001",
    "title": "青甘大环线10天游",
    "cover": "https://...",
    "destination": "青海·甘肃",
    "start_date": "2026-07-15",
    "end_date": "2026-07-25",
    "days": 10,
    "members": [
      { "id": "u_abc123", "nickname": "张三", "avatar": "https://...", "role": "owner" },
      { "id": "u_def456", "nickname": "李四", "avatar": "https://...", "role": "editor" }
    ],
    "days_schedule": [
      {
        "day": 1,
        "date": "2026-07-15",
        "weather": { "temp_high": 28, "temp_low": 15, "condition": "sunny" },
        "pois": [
          {
            "id": "poi_001",
            "poi_id": "poi_xining",
            "name": "西宁",
            "category": "transport",
            "latitude": 36.6171,
            "longitude": 101.7782,
            "order": 1,
            "start_time": "09:00",
            "duration_minutes": 0,
            "note": "集合出发点"
          }
        ]
      }
    ],
    "route": {
      "center": { "latitude": 38.0, "longitude": 98.0 },
      "zoom": 7,
      "stops": [
        { "name": "西宁", "latitude": 36.6171, "longitude": 101.7782, "order": 1, "is_start": true },
        { "name": "青海湖", "latitude": 36.9869, "longitude": 99.9064, "order": 2 },
        { "name": "张掖", "latitude": 38.9317, "longitude": 100.4555, "order": 5, "is_end": true }
      ]
    },
    "accent_color": "#69A7FF",
    "status": "planning"
  }
}
```

### 5.3 创建行程

```
POST /plans
```

**请求体**
```json
{
  "title": "青甘大环线10天游",
  "destination": "青海·甘肃",
  "start_date": "2026-07-15",
  "end_date": "2026-07-25",
  "accent_color": "#69A7FF"
}
```

### 5.4 更新行程

```
PATCH /plans/{plan_id}
```

支持更新的字段：`title`, `cover`, `start_date`, `end_date`, `accent_color`, `status`

### 5.5 删除行程

```
DELETE /plans/{plan_id}
```

### 5.6 添加/更新日行程POI

```
POST /plans/{plan_id}/days/{day}/pois
```

**请求体**
```json
{
  "poi_id": "poi_xining",
  "name": "西宁",
  "category": "transport",
  "latitude": 36.6171,
  "longitude": 101.7782,
  "order": 1,
  "start_time": "09:00",
  "note": "集合出发点"
}
```

### 5.7 调整POI顺序

```
PATCH /plans/{plan_id}/days/{day}/pois/reorder
```

**请求体**
```json
{
  "poi_ids": ["poi_003", "poi_001", "poi_002"]
}
```

### 5.8 删除日行程POI

```
DELETE /plans/{plan_id}/days/{day}/pois/{poi_id}
```

---

## 6. AI 行程生成模块

> 旧原型说明：本节保留早期后端 API 设想。P0-R2 后，面向 App 的 AI 输出应先转换为 `AssistantResponse`，用户结构化操作应以 `ClientEvent` 回传。
> P0-R6.2 清理：旧页面级 `AiTravelAgentReply` 协议，以及直接解析 `replyText` / `requestStartDate` 的路径，已从生产代码中废弃并移除。旧 Dify 响应兼容由 `DifyResponseMapper` 负责；Flutter 页面只消费 `AssistantResponse`、`TravelAssistantState` 和 `UiAction`。

### 6.1 AI对话生成行程

```
POST /ai/generate-plan
```

**请求体**
```json
{
  "prompt": "想去云南玩7天，喜欢拍照和美食，不喜欢太赶的行程",
  "reference_links": [
    "https://www.xiaohongshu.com/explore/xxx"
  ],
  "preferences": {
    "style": "relaxed",
    "interests": ["photography", "food"],
    "budget": "medium"
  }
}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "session_id": "ai_sess_001",
    "plan_preview": {
      "title": "云南7日慢游·摄影美食之旅",
      "destination": "云南",
      "suggested_days": 7,
      "days_schedule": [
        {
          "day": 1,
          "theme": "抵达昆明，初探春城",
          "pois": [
            {
              "name": "昆明长水机场",
              "category": "transport",
              "latitude": 25.1019,
              "longitude": 102.9291,
              "suggestion": "抵达后前往市区"
            },
            {
              "name": "翠湖公园",
              "category": "scenic",
              "latitude": 25.0453,
              "longitude": 102.7056,
              "suggestion": "傍晚散步拍照，可拍红嘴鸥"
            }
          ]
        }
      ],
      "highlights": ["大理洱海日出拍摄", "丽江古城夜景", "野生菌火锅"],
      "tips": ["云南海拔差异大，注意衣物分层", "防晒必备", "7月为雨季，带雨具"]
    }
  }
}
```

### 6.2 攻略链接解析

```
POST /ai/parse-guide
```

**请求体**
```json
{
  "url": "https://www.xiaohongshu.com/explore/xxx"
}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "source": "xiaohongshu",
    "title": "云南7天6晚超详细攻略！拍照美食两不误",
    "extracted_pois": [
      { "name": "翠湖公园", "category": "scenic", "latitude": 25.0453, "longitude": 102.7056, "confidence": 0.95 },
      { "name": "大理古城", "category": "scenic", "latitude": 25.6820, "longitude": 100.1630, "confidence": 0.98 }
    ],
    "suggested_route": { "days": 7, "city_order": ["昆明", "大理", "丽江"] },
    "raw_text_summary": "这是一篇关于云南7日游的详细攻略..."
  }
}
```

### 6.3 行程优化建议

```
POST /ai/optimize-plan/{plan_id}
```

**请求体**
```json
{
  "optimize_type": "route_efficiency"
}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "suggestions": [
      {
        "type": "route",
        "severity": "info",
        "day": 3,
        "message": "建议将「苍山」调整到上午，下午阳光方向更利于「洱海」拍照",
        "affected_pois": ["poi_cangshan", "poi_erhai"]
      }
    ]
  }
}
```

---

## 7. 协作模块

### 7.1 邀请协作者

```
POST /plans/{plan_id}/members
```

**请求体**
```json
{
  "phone": "13900139000",
  "role": "editor"
}
```

### 7.2 移除协作者

```
DELETE /plans/{plan_id}/members/{user_id}
```

### 7.3 获取行程协作成员

```
GET /plans/{plan_id}/members
```

---

## 8. POI 搜索模块

### 8.1 POI 搜索

```
GET /pois/search
```

| 参数 | 类型 | 说明 |
|------|------|------|
| `keyword` | string | 搜索关键词 |
| `category` | string | scenic/food/hotel/shopping/transport |
| `latitude` | float | 中心纬度 |
| `longitude` | float | 中心经度 |
| `radius` | int | 搜索半径（米） |
| `page` | int | 页码 |

### 8.2 POI 详情

```
GET /pois/{poi_id}
```

### 8.3 POI 附近推荐

```
GET /pois/nearby
```

---

## 9. 旅行灵感Feed模块

### 9.1 灵感Feed列表

```
GET /inspirations
```

**查询参数**

| 参数 | 类型 | 说明 |
|------|------|------|
| `category` | string | destination/food/photo/hidden_gem |
| `page` | int | 页码 |

### 9.2 收藏目的地

```
POST /inspirations/{inspiration_id}/bookmark
```

---

## 10. 文件上传模块

### 10.1 上传图片

```
POST /files/upload
```

Content-Type: `multipart/form-data`

| 字段 | 说明 |
|------|------|
| `file` | 图片文件（≤10MB，jpg/png/webp） |
| `type` | avatar/cover/poi_photo/post |

**响应**
```json
{
  "code": 0,
  "data": {
    "url": "https://cdn.goplan.cn/uploads/2026/06/abc123.webp",
    "thumbnail_url": "https://cdn.goplan.cn/uploads/2026/06/abc123_thumb.webp"
  }
}
```

---

## 11. WebSocket 实时协作

### 11.1 建立连接

```
wss://api.goplan.cn/ws/plan/{plan_id}?token={jwt_token}
```

### 11.2 消息协议

**客户端→服务端**
```json
{
  "type": "poi_update",
  "payload": {
    "day": 2,
    "poi_id": "poi_005",
    "changes": { "start_time": "10:00" }
  }
}
```

**服务端→客户端（广播）**
```json
{
  "type": "poi_updated",
  "user_id": "u_def456",
  "user_name": "李四",
  "timestamp": 1719705600000,
  "payload": {
    "day": 2,
    "poi_id": "poi_005",
    "changes": { "start_time": "10:00" }
  }
}
```

---

## 12. 第三方服务集成

### 12.1 高德地图API

| 用途 | API | 说明 |
|------|-----|------|
| POI搜索 | `amap.poi.search` | 关键词+区域搜索 |
| 地理编码 | `amap.geocode` | 地址→坐标 |
| 逆地理编码 | `amap.regeocode` | 坐标→地址 |
| 路径规划 | `amap.direction` | 驾车/步行/公交路径 |
| 天气查询 | `amap.weather` | 目的地天气预报 |

### 12.2 攻略解析管道

```
用户粘贴链接 → 后端爬取内容 → NLP实体识别 → 高德POI匹配 → 时序推断 → 返回结构化行程
```

---

## 13. 限流策略

| 接口类别 | 限制 | 窗口 |
|---------|------|------|
| 发送验证码 | 1次/分钟，5次/天 | 按手机号 |
| AI生成行程 | 20次/天 | 按用户 |
| 攻略解析 | 30次/天 | 按用户 |
| 图片上传 | 50次/天 | 按用户 |
| 普通API | 100次/分钟 | 按用户 |

---

## 14. Conversation Store 本地 JSON Schema

P0-R6.0 使用带版本号的本地 JSON 文档作为临时 Assistant 会话缓存：

```json
{
  "schema_version": 1,
  "conversations": [
    {
      "id": "local_01",
      "user_id": "goplan-local-user",
      "trip_id": "goplan-local-trip",
      "conversation_id": "provider_conv_opaque",
      "title": "杭州周末",
      "created_at": "2026-07-16T09:00:00.000",
      "updated_at": "2026-07-16T10:00:00.000",
      "messages": [
        {
          "id": "message_1",
          "role": "user",
          "text": "帮我规划杭州周末",
          "created_at": "2026-07-16T09:00:00.000",
          "event": {
            "type": "chat_message",
            "field": "message",
            "payload": {
              "message": "帮我规划杭州周末"
            },
            "occurred_at": "2026-07-16T09:00:00.000"
          }
        }
      ],
      "trip_state": {},
      "itinerary": null,
      "warnings": [],
      "assistant_status": "draft"
    }
  ]
}
```

规则：

- `schema_version` 是整数。缺失版本号时，为兼容旧数据按版本 1 处理。
- 高于当前支持版本的文档会抛出 `unsupportedVersion`。
- 顶层 JSON 损坏会抛出 `invalidData`。
- 单条 conversation 记录损坏时跳过该记录，其他有效记录保留。
- `id` 是 GoPlan 本地会话 id。`conversation_id` 是 provider 会话 id，不能作为本地存储 key。
- Message snapshot 保存 `id`、`role`、`text`、`created_at` 和可选 `event`；不保存 `AssistantResponse`、Dify 原始 JSON、HTTP header、API Key、`failure.cause` 或待处理 `ui_action`。
- 恢复会话会初始化 controller messages 和业务状态，但不恢复 `lastResponse`、`lastFailure`、`TravelAssistantPhase` 或待处理 UiAction。

## 15. AI Chat 启动与持久化

`AiChatLaunchMode` 定义正式入口行为：

- `newConversation`：不读取 store，生成一个本地 conversation id，并以空 provider `conversationId` 启动。
- `resumeLatestForTrip`：读取 `ConversationStore.getLatestForTrip(userId, tripId)`。找到时恢复该 snapshot；否则创建新的本地 conversation id。
- `resumeById`：读取 `ConversationStore.getById(localConversationId)`。缺失时页面展示安全的恢复失败提示，而不是创建另一条会话。

每个新 runtime 生命周期只生成一次本地 conversation id，格式为 `goplan_conv_{timestamp}_{randomHex}`。它不会从 `tripId` 或 provider `conversationId` 派生。

`AiChatSessionBootstrap` 是非 Widget 启动协调器。它只读取 `ConversationStore` 接口，不创建 gateway，不发送网络请求，也不保存数据。Store 读取失败会暴露为 bootstrap failure，而不是伪装成空历史。

`AiChatPersistenceCoordinator` 订阅 `TravelAssistantController.states`。默认保存 debounce 为 300 ms，通过 `TravelAssistantSessionMapper` 映射最新 controller state，跳过空会话，并确保同一时间最多一个 `ConversationStore.save()` 在运行。`flush()` 会取消 timer，保存最新待处理状态，等待活跃写入完成，并在 store 写入路径完成后返回。`dispose()` 会调用 `flush()`，且具备幂等性。

历史摘要来自 `ConversationStore.listForUser(userId)`，只暴露 `id`、`userId`、`tripId`、`title`、`destination`、`updatedAt`、`messageCount` 和 `hasItinerary`。不得暴露 provider `conversationId`、原始 events、完整消息文本或 API Key。

Store 失败和 Assistant 失败彼此独立。Assistant 失败通过 `TravelAssistantState.lastFailure` 表达；持久化失败以安全 UI 提示展示，不改变 controller phase。

## 16. Standard Itinerary UI 字段映射

P0-R7 的 Flutter 行程展示只消费标准 Domain，不读取 provider 原始字段，不修改 Domain 数据。

| Domain 字段 | UI 展示 |
| --- | --- |
| `Itinerary.title` | 摘要卡和详情页标题；为空时显示“旅行计划” |
| `Itinerary.destination` | 标题下方目的地；为空时隐藏 |
| `Itinerary.isDraft` | 显示“草案”标签 |
| `Itinerary.days` | 摘要卡最多展示前三天，详情页展示全部 days |
| `Itinerary.budgetSummary` | 预算卡和摘要预算 chip |
| `Itinerary.warnings` + `TravelAssistantState.warnings` | 全局 warning 卡，去重后展示 |
| `ItineraryDay.dayIndex` | “第 N 天”；非法值按列表位置 fallback |
| `ItineraryDay.date` | `2026年8月3日` |
| `ItineraryDay.title` | 日卡标题；为空时 fallback 到“第 N 天” |
| `ItineraryDay.summary` | 日卡摘要文本 |
| `ItineraryDay.estimatedCost` | 日预算 chip，不反推总预算 |
| `ItineraryDay.warnings` | 日内 warning 文本，放在对应 Day 卡片中 |
| `ItineraryItem.startTime/endTime` | `09:00–11:30`、单开始时间或“时间待定” |
| `ItineraryItem.title` | 项目标题；为空时使用 `Place.name` |
| `ItineraryItem.description` | 项目描述 |
| `ItineraryItem.place.name/category/address/city` | 可见地点信息；address 优先于 city |
| `ItineraryItem.transportMode/transportMinutes/durationMinutes/estimatedCost/tips` | chips 与简短提示列表 |

禁止展示字段：`Itinerary.id`、`tripId`、`version`、`ItineraryItem.id`、`Place.id`、`latitude`、`longitude`、`source`、provider `conversationId`、原始 JSON。

预算规则：

- `BudgetSummary.total` 存在时作为主数字。
- `perPerson` 与 transport/accommodation/food/tickets/other 仅展示非空字段。
- 不自动求和，不校验 total 与分类是否一致，不做汇率换算。
- CNY/RMB、USD、EUR、JPY 映射常见符号，未知 currency 显示为 `ABC 120`，空 currency 只显示数字。

Warning 规则：

- 空 message 不展示。
- id 非空时按 id 去重；id 为空时按 `type + message + dayIndex + itemId` 去重，并保持原顺序。
- severity 容错：critical/error/high/danger 为高风险，warning/medium 为中风险，info/low/notice/null/未知为提示。
- type 映射为用户可读标签：schedule、transport、weather、budget、closed、conflict；其他为“行程提示”。
- 不显示 `warning.id` 或 `itemId`。

Passive action 页面行为：

- `showItinerary`：当 `state.itinerary` 非空时滚动到聊天页行程摘要区域。
- `showBudget`：滚动到摘要卡预算 chip；不可见时 fallback 到行程摘要卡。
- `showMap`：P0-R7 不打开地图、不调用高德、不创建 `ClientEvent`，仅显示“地图路线将在后续版本中提供。”。
