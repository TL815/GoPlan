# GoPlan 开发规范

> 版本 v1.0 | 适用于项目全体开发人员

## 1. 代码规范

### 1.1 Flutter/Dart 规范

- 严格遵循 [Effective Dart](https://dart.dev/guides/language/effective-dart) 指南
- 使用 `flutter_lints` 进行静态分析
- 所有 public API 必须有文档注释（`///`）
- Widget 文件命名：小写下划线（`home_page.dart`、`plan_card.dart`）
- Class 命名：大驼峰（`HomePage`、`PlanCard`）
- 变量/函数命名：小驼峰（`userPlans`、`fetchPlans()`）
- 常量命名：小驼峰或大写下划线（`appPrimaryColor`、`API_BASE_URL`）

### 1.2 代码组织

```
lib/
├── main.dart                  # 应用入口
├── app.dart                   # MaterialApp 配置
├── core/                      # 核心模块
│   ├── theme/                 # 主题配置
│   ├── network/               # 网络层（Dio配置）
│   ├── storage/               # 本地存储
│   └── utils/                 # 工具函数
├── models/                    # 数据模型
│   ├── plan.dart
│   ├── poi.dart
│   └── user.dart
├── services/                  # 业务服务
│   ├── auth_service.dart
│   ├── plan_service.dart
│   └── ai_service.dart
├── pages/                     # 页面
│   ├── home/
│   ├── explore/
│   ├── plan_detail/
│   ├── ai_chat/
│   └── profile/
├── widgets/                   # 公共组件
│   ├── plan_card.dart
│   ├── bottom_dock.dart
│   └── map/                   # 地图相关组件
└── native/                    # 原生桥接
```

### 1.3 状态管理

- 推荐使用 Provider 或 Riverpod
- 页面级状态使用 StatefulWidget
- 跨页面共享状态使用 Provider/Riverpod
- 避免在 build 方法中执行耗时操作

### 1.4 后端规范

- 项目结构遵循标准 Go 项目布局
- API Handler → Service → Repository 三层架构
- 所有数据库操作使用参数化查询
- 错误统一通过 middleware 处理
- 日志使用结构化日志（zerolog/logrus）

---

## 2. Git 规范

### 2.1 分支策略

```
main                    # 生产分支，只接受 release/* 合并
├── develop             # 开发主分支
│   ├── feature/*       # 功能分支（feature/ai-chat、feature/map-integration）
│   ├── bugfix/*        # 修复分支
│   └── hotfix/*        # 紧急修复分支
└── release/*           # 发布分支（release/v1.0.0）
```

### 2.2 提交信息规范

遵循 [Conventional Commits](https://www.conventionalcommits.org/)：

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

类型（type）：
- `feat`: 新功能
- `fix`: 修复Bug
- `docs`: 文档变更
- `style`: 代码格式（不影响功能）
- `refactor`: 重构
- `perf`: 性能优化
- `test`: 测试相关
- `chore`: 构建/工具变更

示例：
```
feat(ai): 添加攻略链接解析功能
fix(map): 修复iOS高德地图marker点击无响应
docs: 更新API接口文档
```

### 2.3 Code Review

- 所有合并到 develop 的代码必须通过 PR + 至少1人Review
- Review 关注点：功能正确性、代码规范、安全风险、性能影响
- 不允许直接 push 到 develop 或 main

---

## 3. 测试规范

### 3.1 测试层级

| 层级 | 范围 | 工具 | 覆盖率目标 |
|------|------|------|-----------|
| 单元测试 | Service/Model/Utils | flutter_test / go test | ≥ 80% |
| Widget测试 | UI组件 | flutter_test | ≥ 60% |
| 集成测试 | 关键用户流程 | flutter integration_test | ≥ 5个核心流程 |
| API测试 | 后端接口 | Postman/go test | 100% 接口覆盖 |

### 3.2 测试命名

```
describe('PlanService', () => {
  test('should return user plans when called with valid userId', () => {});
  test('should throw error when called with invalid userId', () => {});
});
```

---

## 4. 安全规范

### 4.1 密钥管理

- 高德 Key 从环境变量或 CI Secret 注入，禁止硬编码
- API Secret Key 使用 vault/CI Secret 管理
- `.env` 文件加入 `.gitignore`
- 发布前轮换所有已暴露的Key

### 4.2 数据安全

- 用户密码使用 bcrypt 哈希存储
- JWT Token 有效期 ≤ 24小时
- Refresh Token 有效期 ≤ 30天
- API传输全程 HTTPS
- 敏感日志脱敏（手机号掩码为 138****8000）
- SQL注入防护：所有查询使用参数化

### 4.3 客户端安全

- Release 构建启用代码混淆（`flutter build apk --obfuscate`）
- 禁止在客户端存储敏感Key
- 使用 flutter_secure_storage 存储 Token

---

## 5. 性能规范

### 5.1 客户端性能

- 首屏加载时间 ≤ 1.5s
- 页面切换动画 60fps
- 列表使用 `ListView.builder` 懒加载
- 图片使用 `cached_network_image` 缓存
- 大图使用缩略图占位
- 地图POI标记 > 50个时启用聚合

### 5.2 后端性能

- API响应时间 P99 ≤ 500ms
- 数据库查询添加合适索引
- 热点数据使用 Redis 缓存
- AI生成行程：30秒超时，异步处理

---

## 6. 设计还原规范

### 6.1 设计稿对接

- 默认基于 375pt 宽度（iPhone 6/7/8）设计
- 颜色使用设计规范中定义的色值 Token
- 间距遵循 4px 基准网格系统
- 圆角使用规范中定义的 Token
- 字体大小/字重严格按设计规范

### 6.2 设计还原验收

- 像素级对比目标：还原度 ≥ 90%
- 验收工具：截图叠加对比
- 必须通过设计负责人 Review

---

## 7. 依赖管理

### 7.1 Flutter 依赖

```yaml
dependencies:
  # 网络
  dio: ^5.4.0
  # 状态管理
  provider: ^6.1.0
  # 路由
  go_router: ^14.0.0
  # 本地存储
  shared_preferences: ^2.2.0
  flutter_secure_storage: ^9.0.0
  # 地图
  amap_flutter_map: ^3.0.0     # 高德地图 Flutter 插件
  # 图片
  cached_network_image: ^3.3.0
  # 序列化
  json_annotation: ^4.8.0
  # WebSocket
  web_socket_channel: ^2.4.0
```

### 7.2 依赖更新原则

- 安全漏洞修复：24小时内更新
- 小版本更新：评估后批量更新
- 大版本更新：需要技术评审
- 新增依赖：需要负责人审批

---

## 8. 发布流程

### 8.1 提测流程

1. 功能开发完成 → 自测通过
2. 创建 PR → Code Review → 合并 develop
3. CI 自动构建测试包
4. QA 验收（功能测试 + 回归测试）
5. Bug修复 → 重复步骤1-4
6. QA 签字放行

### 8.2 发布Checklist

- [ ] 所有 P0 Bug 已关闭
- [ ] 单元测试通过率 100%
- [ ] Flutter analyze 无 Error
- [ ] 高德 Key 已轮换为生产Key
- [ ] 隐私政策已更新
- [ ] 应用商店截图已准备
- [ ] 版本号已更新
- [ ] Release Notes 已编写
- [ ] 后向兼容性已验证

---

## 9. 沟通规范

- 每日站会（15分钟）：同步进展、阻塞、计划
- 需求变更：通过 PRD 更新 + 团队评审
- 技术决策：ADR（Architecture Decision Record）记录
- Bug追踪：统一使用项目管理工具（可接入飞书/Notion等）
