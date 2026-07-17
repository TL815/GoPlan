# GoPlan 配置与密钥

## 配置清单

| 名称 | 使用方 | 范围 | 来源 | 轮换方式 | 风险 |
| --- | --- | --- | --- | --- | --- |
| `AMAP_API_KEY` | Android Manifest 中的高德地图 SDK 占位符 | 客户端 / App 包内 | `android/gradle.properties` 或 `-PAMAP_API_KEY=...` | 在高德控制台轮换并重新构建 App | 当前疑似已提交，应视为已暴露 |
| `AMAP_IOS_KEY` | iOS 高德地图接入配置 | 客户端 / App 包内 | `ios/Flutter/AMap.xcconfig` | 在高德控制台轮换并重新构建 App | 当前疑似已提交，应视为已暴露 |
| `_useMockMapPreview` | Flutter 地图渲染路径 | 客户端编译期常量 | `lib/main.dart` | 修改源码并重新构建 | 低风险；控制 Mock 地图与原生地图路径 |
| `goplanAmapConfig.key` | Web 高德地图 JS API | Web 客户端 | `web/index.html` | 在高德控制台轮换；重新构建 Web | 必须使用 Web/JS API Key，不能复用 Android/iOS Key |
| `goplanAmapConfig.securityJsCode` | Web 高德 JS API 安全密钥 | Web 客户端，仅开发临时使用 | `web/index.html` | 在高德控制台轮换；重新构建 Web | 明文方式不适合生产环境 |
| `goplanAmapConfig.serviceHost` | Web 高德 JS API 安全代理地址 | Web 客户端 | `web/index.html` | 由后端/网关配置 | 生产推荐通过代理转发安全密钥 |
| `DIFY_API_KEY` | P0 Dify Gateway 调用 `/chat-messages` | 客户端临时测试 / 未来应迁移服务端 | `--dart-define=DIFY_API_KEY=...` 或 CI secret | 在 Dify 控制台轮换 | 不得写入仓库、截图或日志 |
| `DIFY_API_BASE` | P0 Dify Gateway API Base | 客户端临时测试 | `--dart-define=DIFY_API_BASE=...` | 不适用 | 默认 `https://api.dify.ai/v1` |
| `DIFY_USER_ID` | AI chat runtime user id | 客户端临时测试 | `--dart-define=DIFY_USER_ID=...` | 不适用 | 默认 `goplan-local-user`，不应包含真实个人标识 |
| `DIFY_TRIP_ID` | AI chat runtime trip id | 客户端临时测试 | `--dart-define=DIFY_TRIP_ID=...` | 不适用 | 默认 `goplan-local-trip`，不应包含真实行程隐私 |
| `GOPLAN_TIMEZONE` | AI chat runtime timezone | 客户端临时测试 | `--dart-define=GOPLAN_TIMEZONE=...` | 不适用 | 默认 `Asia/Shanghai` |
| DeepSeek API Key | 未来 AI 对话模型调用 | 尚未实现；应放在服务端或安全代理中 | 尚未配置 | 在 DeepSeek 控制台轮换 | 接入时不能直接打包到 Flutter 客户端 |
| Flutter assets 配置 | Flutter 运行时 | 客户端 / App 包内 | `pubspec.yaml` | 不适用 | 低风险 |

## 客户端密钥说明

当前项目没有后端，因此不存在真正能保密的服务端密钥。任何打包进 Android/iOS/Flutter 的 Key 都应视为客户端可见。当前高德 Key 属于客户端 App Key，发布前应在高德控制台按包名、签名证书或 bundle id 做限制；如果这些 Key 是真实生产 Key，应先轮换。

`DIFY_API_KEY` 只允许作为 P0 测试过渡方案通过 `--dart-define` 注入。正式阶段应由业务后端隐藏 Dify API Key，Flutter 客户端只访问 GoPlan 后端。不得把真实 Dify Key 写入仓库、截图、日志、异常 message 或文档示例。

`DIFY_USER_ID`、`DIFY_TRIP_ID` 和 `GOPLAN_TIMEZONE` 由 AI chat runtime 读取一次并传给 `TravelAssistantController`。空字符串会回退到默认值。页面不直接读取 `DIFY_API_KEY`，Dify API base/key 仍只由 `DifyGatewayConfig` 负责。文档和测试只使用占位值，不提供真实 key。正式阶段 Dify key 应迁移到后端。

P0-R6.2 已移除旧 `DifyTravelAgent`；它不再读取任何 Dify 环境变量。`DifyGatewayConfig` 是正式 Assistant 链路中唯一的 Dify 配置读取入口。

ConversationStore 本地持久化不读取任何 API Key 配置。`DIFY_API_KEY`、Authorization header、provider 原始响应以及地图/天气 key 都不得写入 `AssistantConversationSnapshot`、`ConversationJsonDocument` 或 `SharedPreferencesConversationStore`。

会话恢复只读取 `ConversationStore` 背后的本地版本化 JSON 文档。provider `conversationId` 可以存储，用于下一次 Assistant 请求继续 provider 会话，但它不是认证凭据，也不应显示在日志或 UI 中。

## 上线前检查清单

- 轮换所有已经进入 Git 历史的高德 Key。
- 尽量移除 committed config 中的本地开发 Key。
- Android 高德 Key 需要按 package name 和签名证书限制。
- iOS 高德 Key 需要按 bundle identifier 限制。
- Web 高德 Key 需要在高德控制台申请 JS API 类型，并配置域名白名单。
- 生产环境不要把 `securityJsCode` 明文写入 `web/index.html`，应使用 `serviceHost` 指向后端/网关代理。
- 明确 `_useMockMapPreview` 是否只在 debug/flavor 中开启。
- 接入 DeepSeek 前，确定 API Key 由后端或安全代理持有，避免写入 Flutter 客户端。
- 为 DeepSeek 接入补充超时、重试、限流、错误提示和日志策略。
- 在读取真实定位前补充运行时权限请求和用户解释。
- 只有在引入后端或受保护 provider secret 后，再建立 `.env` / CI secret 管理策略。

## 非密钥配置说明

- Android `applicationId` 是 `com.tl815.goplan`，位于 `android/app/build.gradle.kts`。
- Flutter package name 是 `goplan`，位于 `pubspec.yaml`。
- 静态演示数据写在 `lib/main.dart`，不应放入真实用户隐私数据。

