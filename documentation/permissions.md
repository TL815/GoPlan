# GoPlan 权限说明

## 当前访问模型

GoPlan 当前没有账号系统、登录、后端、角色、claim 或行级资源。所有可见数据都是打包在客户端里的演示数据。当前代码中真正涉及的权限主要是系统网络和定位权限，用于地图与未来位置能力。

## 角色与 Claim

| 角色 / Claim | 当前是否存在 | 来源 | 说明 |
| --- | --- | --- | --- |
| 匿名 App 用户 | 是 | 本地 App 会话 | 可以查看所有内置演示 UI 和数据 |
| 已登录用户 | 否 | 不适用 | 尚未接入认证服务或 session |
| 管理员 / 编辑者 | 否 | 不适用 | 尚无管理操作 |
| 服务端角色 | 否 | 不适用 | 尚无后端或服务端密钥上下文 |

## 资源操作矩阵

| 资源 | 操作 | 匿名用户 | 已登录用户 | 管理员 | 强制方式 |
| --- | --- | --- | --- | --- | --- |
| 首页演示计划 | 查看 | 允许 | 不适用 | 不适用 | 本地打包数据 |
| 探索页演示 POI | 查看 / 筛选 | 允许 | 不适用 | 不适用 | 本地打包数据 |
| Mock 地图预览 | 查看 | 允许 | 不适用 | 不适用 | Flutter UI |
| 原生地图 marker | 接收内置 POI | 允许 | 不适用 | 不适用 | App 内部 PlatformView 和 MethodChannel |
| 日程 / 我的页面 | 查看占位页 | 允许 | 不适用 | 不适用 | Flutter UI |
| 设备定位 | 读取当前位置 | 尚未实现 | 不适用 | 不适用 | 未来需要系统权限授权 |

## 平台权限

| 平台 | 权限 / 使用说明 | 用途 | 当前使用状态 |
| --- | --- | --- | --- |
| Android | `INTERNET` | 地图 SDK / 网络访问，以及 debug/profile 开发支持 | 已声明 |
| Android | `ACCESS_NETWORK_STATE` | 网络状态感知 | 已声明 |
| Android | `ACCESS_FINE_LOCATION` | 未来精准定位和地图能力 | 已声明；Flutter 层尚无运行时请求 |
| Android | `ACCESS_COARSE_LOCATION` | 未来粗略定位能力 | 已声明；Flutter 层尚无运行时请求 |
| iOS | `NSLocationWhenInUseUsageDescription` | 展示附近景点、路线和地图 | 已声明 |
| iOS | `NSLocationAlwaysAndWhenInUseUsageDescription` | 未来旅行中的路线和轨迹能力 | 已声明 |

## 行级安全与数据强制

当前没有数据库、API 或行级安全策略。

| 数据存储 | 是否有 RLS | 强制方式 |
| --- | --- | --- |
| Flutter 本地常量 | 不适用 | App bundle 可见 |
| 原生地图 SDK 状态 | 不适用 | 本地 App 进程 |
| 远程数据库 | 否 | 尚未实现 |

## 发布前权限缺口

| 缺口 | 为什么重要 | 证据 |
| --- | --- | --- |
| 已声明定位权限，但还没有运行时授权 UX | 启用定位后，用户可能遇到突兀的系统授权弹窗 | `AndroidManifest.xml`, `Info.plist` |
| 尚无用户自建行程的数据权限模型 | 一旦接入真实用户数据，需要所有权和访问控制 | 当前只有 `demoPlans` / `demoPois` |
| MethodChannel payload 当前默认可信 | 原型阶段可以接受；未来扩大原生能力后需要更严格 schema 校验 | `NativeMapCommandBus.handle()` |

