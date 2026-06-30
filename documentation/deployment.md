# GoPlan 部署与发布指南

> 版本 v1.0 | 最后更新 2026-06

## 1. 开发环境搭建

### 1.1 前置要求

| 工具 | 版本要求 | 说明 |
|------|---------|------|
| Flutter SDK | ≥ 3.12 | 跨平台框架 |
| Dart SDK | ≥ 3.12 | 编程语言 |
| Android Studio | Hedgehog+ | Android开发环境 |
| Xcode | 16+ | iOS开发（仅macOS） |
| JDK | 17 | Android构建依赖 |
| Go | 1.22+ | 后端开发 |
| PostgreSQL | 16+ | 数据库 |
| Redis | 7+ | 缓存 |

### 1.2 Flutter 项目初始化

```powershell
# 克隆项目
git clone <repo-url>
cd GoPlan-flutter

# 安装依赖
flutter pub get

# 验证环境
flutter doctor

# 运行分析
flutter analyze

# 运行测试
flutter test
```

### 1.3 Android 配置

1. 获取高德地图 Android Key（高德开放平台 → 应用管理 → 添加Key）
2. 配置 Key（二选一）：
   - **方式A**（推荐）：通过环境变量
     ```powershell
     $env:AMAP_API_KEY="your_android_key"
     ```
   - **方式B**：向 `android/gradle.properties` 添加
     ```properties
     AMAP_API_KEY=your_android_key
     ```
3. 运行
   ```powershell
   flutter run -d android
   ```

### 1.4 iOS 配置

1. 获取高德地图 iOS Key
2. 配置 `ios/Flutter/AMap.xcconfig`
3. 安装 CocoaPods 依赖：
   ```bash
   cd ios && pod install && cd ..
   ```
4. 运行：
   ```bash
   flutter run -d ios
   ```

### 1.5 后端配置

```bash
# 环境变量
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=goplan
export DB_USER=goplan
export DB_PASSWORD=xxx
export REDIS_URL=redis://localhost:6379
export JWT_SECRET=your_jwt_secret
export LLM_API_KEY=your_llm_key
export AMAP_API_KEY=your_amap_key

# 数据库迁移
go run cmd/migrate/main.go up

# 启动服务
go run cmd/server/main.go
```

---

## 2. Android 构建与发布

### 2.1 Debug APK

```powershell
flutter build apk --debug
# 输出: build/app/outputs/flutter-apk/app-debug.apk
```

### 2.2 Release APK

```powershell
# 带高德Key
flutter build apk --release --dart-define=AMAP_API_KEY=$env:AMAP_API_KEY

# 代码混淆
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

### 2.3 AAB（Google Play）

```powershell
flutter build appbundle --release
# 输出: build/app/outputs/bundle/release/app-release.aab
```

### 2.4 安卓应用市场上架

| 市场 | 说明 |
|------|------|
| Google Play | 上传AAB，需签名证书 |
| 华为应用市场 | 上传APK |
| 小米应用商店 | 上传APK |
| OPPO软件商店 | 上传APK |
| vivo应用商店 | 上传APK |
| 应用宝 | 上传APK |

**签名配置**：
```properties
# android/key.properties
storePassword=xxx
keyPassword=xxx
keyAlias=upload
storeFile=../upload-keystore.jks
```

---

## 3. iOS 构建与发布

### 3.1 构建 IPA

```bash
# Archive
flutter build ipa

# 输出: build/ios/ipa/goplan.ipa
```

### 3.2 App Store 上架

1. Xcode → Product → Archive
2. Organizer → Distribute App → App Store Connect
3. 在 App Store Connect 填写信息
4. 提交审核

### 3.3 TestFlight 内测

```bash
# 构建并上传到 TestFlight
flutter build ipa --export-method ad-hoc
# 或通过 Xcode Archive → Distribute → TestFlight
```

---

## 4. CI/CD 配置

### 4.1 GitHub Actions（示例）

```yaml
name: GoPlan CI

on:
  push:
    branches: [develop]
  pull_request:
    branches: [develop]

jobs:
  flutter-analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze

  flutter-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test

  build-android:
    runs-on: ubuntu-latest
    needs: [flutter-analyze, flutter-test]
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build apk --debug
      - uses: actions/upload-artifact@v4
        with:
          name: android-debug-apk
          path: build/app/outputs/flutter-apk/app-debug.apk
```

---

## 5. 后端部署

### 5.1 Docker 部署（推荐）

```dockerfile
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY . .
RUN go build -o server cmd/server/main.go

FROM alpine:latest
RUN apk add --no-cache ca-certificates
COPY --from=builder /app/server /app/server
EXPOSE 8080
CMD ["/app/server"]
```

```bash
docker build -t goplan-api .
docker run -d -p 8080:8080 \
  -e DB_HOST=host.docker.internal \
  -e JWT_SECRET=xxx \
  goplan-api
```

### 5.2 服务部署检查清单

- [ ] 数据库已创建并迁移
- [ ] Redis 已启动并连接正常
- [ ] SSL证书已配置（生产环境HTTPS）
- [ ] 域名已解析（api.goplan.cn）
- [ ] 环境变量已配置（禁止硬编码）
- [ ] 健康检查端点 `/health` 可访问
- [ ] 日志收集已配置
- [ ] 异常监控已接入（Sentry）

---

## 6. 环境配置对照表

| 配置项 | 开发 | 测试 | 生产 |
|--------|------|------|------|
| API Base URL | `http://localhost:8080` | `https://test-api.goplan.cn` | `https://api.goplan.cn` |
| 数据库 | 本地PostgreSQL | 测试实例 | RDS |
| 缓存 | 本地Redis | 测试实例 | ElastiCache |
| 日志级别 | DEBUG | INFO | WARN |
| Mock地图 | `true` | `false` | `false` |
| 崩溃上报 | 关闭 | 开启 | 开启 |
| 性能监控 | 关闭 | 开启 | 开启 |

---

## 7. 常见问题

### Q1: Android 模拟器地图白屏
A: x86_64 模拟器不支持高德 native so，设置 `_useMockMapPreview = true` 或使用 ARM 模拟器。

### Q2: iOS pod install 失败
A: 确保已安装 CocoaPods 并在 `ios/` 目录运行 `pod install --repo-update`。

### Q3: 高德地图 Key 不生效
A: 检查 Key 的包名/Bundle ID 绑定是否正确，Key 的服务类型是否包含"Android地图SDK"或"iOS地图SDK"。

### Q4: flutter analyze 报错
A: 确保代码符合 `analysis_options.yaml` 规则，运行 `flutter pub get` 更新依赖。

### Q5: Release APK 闪退
A: 检查是否需要添加混淆规则（`proguard-rules.pro`），确认高德地图Key在生产环境下有效。
