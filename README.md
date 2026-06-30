# GoPlan - AI 旅行攻略规划应用

GoPlan 是一款面向自由行用户的 AI 智能旅游攻略规划应用，基于 Flutter 跨平台框架构建。

## 项目状态

**当前版本：v0.1（原型阶段）**

- Flutter UI 原型已完成，包含品牌启动页、首页、探索页
- Android/iOS 原生地图桥接骨架已搭建
- Mock 地图模式用于 x86_64 模拟器开发

## 项目文档

完整项目文档在 [`documentation/`](documentation/README.md) 目录，涵盖：

- **产品需求文档** - 功能范围、目标用户、成功指标
- **UI/UX设计规范** - 基于 Dribbble 参考的色彩/字体/组件/动效规范
- **技术架构文档** - 技术栈、运行结构、数据流、信任边界
- **API接口设计** - RESTful API + WebSocket 协作协议
- **数据库设计** - PostgreSQL + PostGIS 表结构
- **测试计划** - 单元/Widget/集成/性能/安全测试用例
- **开发路线图** - 版本节奏 v0.5 → v1.0 → v1.1
- **开发规范** - 代码/Git/安全/发布流程规范
- **部署指南** - 环境搭建/构建/CI/CD/后端部署

## 快速开始

```powershell
# 安装依赖
flutter pub get

# 运行分析
flutter analyze

# 运行测试
flutter test

# 启动调试（Mock地图模式）
flutter run

# 构建Android APK
flutter build apk --debug
```

## 技术栈

| 层级 | 技术 |
|------|------|
| App UI | Flutter / Dart |
| Android 地图 | 高德地图 SDK (PlatformView) |
| iOS 地图 | 高德地图 SDK (PlatformView) |
| 后端 (规划中) | Go / PostgreSQL / Redis |
| AI | LLM API + NLP 攻略解析 |

## 竞品参考

- **圆周旅迹**：纯规划工具，跨平台攻略解析，无商业干扰
- **GoPlan 差异化**：Dribbble 级设计品质 + AI 对话优先 + 旅行灵感 Feed

## 目录结构

```
GoPlan/
├── lib/                    # Flutter 代码
│   └── main.dart           # 应用入口（当前所有代码）
├── assets/                 # 资源文件
│   ├── images/             # 图片资源
│   └── icons/              # 图标资源
├── android/                # Android 原生代码
├── ios/                    # iOS 原生代码
├── documentation/          # 项目文档
├── test/                   # 测试文件
└── pubspec.yaml            # Flutter 依赖配置
```
