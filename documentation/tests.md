# GoPlan 测试覆盖地图

## 现有覆盖

| 用例 | 被验证的规则 | 期望行为 | 证据来源 | 状态 | 是否 CI 阻断 |
| --- | --- | --- | --- | --- | --- |
| Flutter 默认 counter 示例 | counter 从 0 增加到 1 | 与 GoPlan 无关；测试仍引用不存在的 `MyApp` | `test/widget_test.dart` | 已存在但失效 | 尚未发现 CI |

## 建议补充测试

| 用例 | 规则 | 期望行为 | 证据来源 | 测试类型 | 状态 |
| --- | --- | --- | --- | --- | --- |
| App 启动 | `GoPlanApp` 可以正常渲染 | pump `GoPlanApp` 后，先出现加载页，再进入首页 shell | `lib/main.dart` | 自动化 widget 测试 | 建议新增 |
| 首页 AI 对话入口 | 顶部圆角输入区是 AI 对话入口，不是搜索框 | 点击后打开 `_AiChatSheet`，不触发搜索行为 | `_AiDialogBar`, `_AiChatSheet` | 自动化 widget / 手动视觉检查 | 建议新增 |
| AI 本地对话 | 用户输入后收到 Mock 回复 | 输入旅行想法并发送后，消息列表出现用户消息和 AI 回复 | `_AiChatSheet._send()`, `_mockDeepSeekReply()` | 自动化 widget 测试 | 建议新增 |
| DeepSeek 接入保护 | API Key 不进入客户端包 | 接入真实模型时，Flutter 只调用后端或安全代理，不直接携带 DeepSeek Key | `variables.md` | 架构评审 / 自动化扫描 | 建议新增 |
| 首页行程卡片 | 演示行程卡片可正常展示 | `HomePage` 展示 `demoPlans` 的标题与路线预览 | `demoPlans`, `PlanCard` | 自动化 widget 测试 | 建议新增 |
| 探索页分类筛选 | 分类 chip 会过滤 POI | 点击分类后，POI 列表和 Mock 地图摘要数量变化 | `ExplorePage`, `poiCategories`, `demoPois` | 自动化 widget 测试 | 建议新增 |
| Mock 地图预览 | 模拟器无需高德 native so 也能看到地图效果 | `_useMockMapPreview = true` 时，`NativeMapView` 渲染 `_MockExploreMap` | `NativeMapView`, `_MockExploreMap` | 自动化 widget 测试 | 建议新增 |
| 原生地图桥 | POI 更新会调用 `setMarkers` | 关闭 mock 并 mock method channel 后，POI 更新触发 `setMarkers` | `NativeMapView._syncMarkers()` | 自动化 unit/widget 测试 | 建议新增 |
| Android 原生地图 fallback | x86_64 模拟器不会加载不支持的高德 so | x86 ABI 下 `supportsAmapNativeLibs()` 返回 false，并显示 fallback | `MainActivity.kt` | 手动 / Android instrumentation | 建议新增 |
| 定位权限 UX | 未授权时不读取真实定位 | 用户拒绝权限后，定位功能应停止并展示可理解的 fallback | `AndroidManifest.xml`, `Info.plist` | 手动 / 受控集成测试 | 建议新增 |
| 高德 Key 管理 | 不提交生产 Key | 静态扫描在发布前发现 committed provider key | `variables.md`, 平台配置 | 自动化仓库检查 | 建议新增 |

## 当前缺口

| 缺口 | 暴露面 | 风险 | 证据 |
| --- | --- | --- | --- |
| 当前 widget test 已过期 | 测试套件健康度 | `flutter analyze` 因 `MyApp` 不存在而失败 | `test/widget_test.dart` |
| 没有覆盖 App 启动和加载页切换 | 核心启动体验 | 首屏回归可能无法及时发现 | `GoPlanShell`, `LoadingPage` |
| 没有覆盖 AI 对话组件 | AI 交互入口 | 输入、发送、禁用重复发送和 Mock 回复可能回归 | `_AiChatSheet` |
| 没有覆盖探索页筛选 | 数据完整性 / UI 行为 | 分类筛选可能展示错误 POI | `ExplorePage` |
| 没有覆盖 MethodChannel schema | Flutter/原生桥接 | 错误 payload 可能静默失败或导致原生地图异常 | `NativeMapView`, `MainActivity.kt` |
| 没有覆盖定位权限拒绝行为 | OS 权限边界 | 未来定位功能在拒绝权限时可能表现错误 | `permissions.md`, 平台 manifest |
| 没有明确 CI 阻断规则 | 发布流程 | 测试或分析失败可能不会阻止合并 | 仓库中未发现 CI 配置 |

