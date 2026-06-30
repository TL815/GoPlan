# GoPlan 关键流程

本文只记录涉及信任边界、平台权限、数据完整性或原生桥接的流程。纯展示型浏览流程不单独展开，除非它会影响原生平台状态。

## 流程 1：启动 App 并进入首页

| 字段 | 内容 |
| --- | --- |
| 参与者 | App 用户 |
| 前置条件 | App 已安装在 Android/iOS 或模拟器上 |
| 成功结果 | 加载页结束后进入首页，展示本地演示内容 |
| 受保护资源 | 无 |
| 授权检查 | 无；当前没有登录或权限系统 |

步骤：

1. `main()` 初始化 Flutter bindings，并启动 `GoPlanApp`。
2. `GoPlanShell` 初始状态为 `_showHome = false`，默认 tab 为 `AppTab.home`。
3. 首先展示 `LoadingPage`，随后切换到主界面。
4. `HomePage` 渲染静态用户信息、AI 对话组件入口、天气视觉元素、图片横排、筛选栏和 `demoPlans`。

状态变化与副作用：

- Flutter 本地 widget 状态从 loading 切换到 home。
- 没有文件写入、网络请求、后端调用或原生平台副作用。

信任边界：

- 无。

## 流程 2：探索页 POI 分类筛选与 Mock 地图预览

| 字段 | 内容 |
| --- | --- |
| 参与者 | App 用户 |
| 前置条件 | 用户进入探索页；`_useMockMapPreview = true` |
| 成功结果 | 点击分类后，地图上的 POI 点位随筛选结果变化 |
| 受保护资源 | 无 |
| 授权检查 | 无；所有 POI 都是 App 内置演示数据 |

步骤：

1. 用户通过底部导航切换到探索页。
2. `ExplorePage` 以 `_category = null` 初始化。
3. `pois` 从 `demoPois` 派生；点击 `_CategoryChip` 会切换 `_category`。
4. `NativeMapView` 接收筛选后的 POI 列表。
5. 因为 `_useMockMapPreview = true`，`NativeMapView` 返回 `_MockExploreMap`。
6. `_MockExploreMapPainter` 绘制地图底图、道路、绿地、水域和路线。
7. `_MockPoiMarker` 渲染筛选后的 POI 点位和标签。

状态变化与副作用：

- 只改变 Flutter 本地 widget 状态：设置或清空 `_category`。
- Mock 地图模式下不会调用原生地图、网络或本地存储。

信任边界：

- 当前 Mock 地图路径不跨信任边界。

负向情况：

- 暂无受保护操作，因此没有 deny case。

## 流程 3：首页 AI 对话组件

| 字段 | 内容 |
| --- | --- |
| 参与者 | App 用户 |
| 前置条件 | 用户位于首页，并点击顶部 AI 对话入口 |
| 成功结果 | 弹出 GoPlan AI 对话面板，用户可输入旅行想法并收到本地 Mock 回复 |
| 受保护资源 | 暂无；当前不调用外部模型、不读取真实用户数据 |
| 授权检查 | 无；当前是本地交互 |

步骤：

1. 用户点击 `_AiDialogBar`。
2. App 通过 `showModalBottomSheet` 打开 `_AiChatSheet`。
3. 用户可以点击建议 chip，或在 `TextField` 中输入旅行想法。
4. `_send()` 将用户消息加入本地 `_messages` 列表，并进入 `_isThinking = true` 状态。
5. `_mockDeepSeekReply()` 根据文本关键词返回本地模拟回复。
6. AI 回复加入 `_messages`，界面滚动到底部。

状态变化与副作用：

- 只改变 Flutter 本地 widget 状态：消息列表、输入框、思考状态。
- 当前没有网络请求、模型调用、日志写入或持久化。

信任边界：

- 当前不跨信任边界。
- 后续接入 DeepSeek 时会新增 `App -> DeepSeek API` 边界，需要记录请求字段、API Key 来源、错误处理、限流和审计策略。

负向情况：

- 空输入不会发送。
- AI 正在回复时禁用重复发送。

## 流程 4：将 POI 传给原生地图桥

| 字段 | 内容 |
| --- | --- |
| 参与者 | App 用户 |
| 前置条件 | `_useMockMapPreview = false`；设备支持 Android/iOS 平台视图 |
| 成功结果 | 原生地图收到 POI 标记和相机命令 |
| 受保护资源 | 原生地图视图与 MethodChannel |
| 授权检查 | 无；MethodChannel 由 App 内部 Flutter 代码调用 |

步骤：

1. `ExplorePage` 从 `demoPois` 生成筛选后的 POI 列表。
2. `NativeMapView` 根据平台选择 `AndroidView` 或 `UiKitView`。
3. Flutter 通过 `creationParams` 和 `StandardMessageCodec` 传递 POI 列表。
4. Android 在 `MainActivity.configureFlutterEngine` 中注册 `goplan/native_map_view`。
5. Android `NativeMapViewFactory.create()` 接收 `pois`，创建 `NativeMapPlatformView`。
6. 如果原生高德地图可用，`NativeMapPlatformView.setPois()` 将 POI 转成地图 marker，并调整相机范围。
7. 当 Flutter widget 更新时，`_syncMarkers()` 通过 `MethodChannel("goplan/native_map")` 调用 `setMarkers`。
8. Android `NativeMapCommandBus.handle()` 将 `setMarkers` 和 `moveCamera` 分发给当前 active native view。

状态变化与副作用：

- 原生地图 marker 被清空并重新添加。
- 原生地图相机可能移动到 marker bounds。
- 没有服务端写入或持久化本地写入。

信任边界：

| 边界 | 数据 | 控制 |
| --- | --- | --- |
| Flutter -> 原生 PlatformView | `creationParams` 中的 POI 列表 | Flutter 运行时内部传递 |
| Flutter -> 原生 MethodChannel | `setMarkers`, `moveCamera` payload | `NativeMapCommandBus` 对 method name 做白名单分发 |
| Android 原生 -> 高德 SDK | 坐标、marker 名称、分类 snippet | 高德 SDK 和 App Key |

负向情况：

- 未支持的 MethodChannel 方法返回 `notImplemented()`。
- 在 x86_64 Android 模拟器上，`supportsAmapNativeLibs()` 会避免加载不支持的高德 native so，并显示 fallback。

## 流程 5：地图/定位相关系统权限

| 字段 | 内容 |
| --- | --- |
| 参与者 | App 用户 / 操作系统 |
| 前置条件 | App 已安装 |
| 成功结果 | App 具备未来地图和定位能力所需的系统权限声明 |
| 受保护资源 | 设备网络与定位权限 |
| 授权检查 | 操作系统权限模型；当前 Flutter 层尚未实现运行时授权流程 |

步骤：

1. Android 声明 `INTERNET`、`ACCESS_NETWORK_STATE`、`ACCESS_FINE_LOCATION`、`ACCESS_COARSE_LOCATION`。
2. iOS 在 `Info.plist` 中声明定位使用说明。
3. 当前 Flutter UI 没有请求定位权限，也没有读取当前位置。
4. Android 原生地图设置了 `uiSettings.isMyLocationButtonEnabled = true`，但当前 Flutter 层没有显式运行时权限请求。

状态变化与副作用：

- 权限在平台配置层声明。
- 当前 demo 流程没有读取真实位置。

信任边界：

| 边界 | 数据 | 控制 |
| --- | --- | --- |
| App -> OS 权限系统 | 定位权限声明 | Android/iOS 平台权限模型 |

负向情况：

- 如果定位权限被拒绝或尚未请求，真实定位功能不应运行。该行为尚未实现，是当前缺口。

