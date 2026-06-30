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
