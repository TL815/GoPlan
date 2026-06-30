# GoPlan 配置与密钥

## 配置清单

| 名称 | 使用方 | 范围 | 来源 | 轮换方式 | 风险 |
| --- | --- | --- | --- | --- | --- |
| `AMAP_API_KEY` | Android Manifest 中的高德地图 SDK 占位符 | 客户端 / App 包内 | `android/gradle.properties` 或 `-PAMAP_API_KEY=...` | 在高德控制台轮换并重新构建 App | 当前疑似已提交，应视为已暴露 |
| `AMAP_IOS_KEY` | iOS 高德地图接入配置 | 客户端 / App 包内 | `ios/Flutter/AMap.xcconfig` | 在高德控制台轮换并重新构建 App | 当前疑似已提交，应视为已暴露 |
| `_useMockMapPreview` | Flutter 地图渲染路径 | 客户端编译期常量 | `lib/main.dart` | 修改源码并重新构建 | 低风险；控制 Mock 地图与原生地图路径 |
| DeepSeek API Key | 未来 AI 对话模型调用 | 尚未实现；应放在服务端或安全代理中 | 尚未配置 | 在 DeepSeek 控制台轮换 | 接入时不能直接打包到 Flutter 客户端 |
| Flutter assets 配置 | Flutter 运行时 | 客户端 / App 包内 | `pubspec.yaml` | 不适用 | 低风险 |

## 客户端密钥说明

当前项目没有后端，因此不存在真正能保密的服务端密钥。任何打包进 Android/iOS/Flutter 的 Key 都应视为客户端可见。当前高德 Key 属于客户端 App Key，发布前应在高德控制台按包名、签名证书或 bundle id 做限制；如果这些 Key 是真实生产 Key，应先轮换。

## 上线前检查清单

- 轮换所有已经进入 Git 历史的高德 Key。
- 尽量移除 committed config 中的本地开发 Key。
- Android 高德 Key 需要按 package name 和签名证书限制。
- iOS 高德 Key 需要按 bundle identifier 限制。
- 明确 `_useMockMapPreview` 是否只在 debug/flavor 中开启。
- 接入 DeepSeek 前，确定 API Key 由后端或安全代理持有，避免写入 Flutter 客户端。
- 为 DeepSeek 接入补充超时、重试、限流、错误提示和日志策略。
- 在读取真实定位前补充运行时权限请求和用户解释。
- 只有在引入后端或受保护 provider secret 后，再建立 `.env` / CI secret 管理策略。

## 非密钥配置说明

- Android `applicationId` 是 `com.tl815.goplan`，位于 `android/app/build.gradle.kts`。
- Flutter package name 是 `goplan`，位于 `pubspec.yaml`。
- 静态演示数据写在 `lib/main.dart`，不应放入真实用户隐私数据。

