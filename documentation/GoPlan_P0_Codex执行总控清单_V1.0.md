# GoPlan P0 Codex 执行总控清单 V1.0

> 仓库：`TL815/GoPlan`  
> 分支基线：`main`  
> 核心原则：一次只做一个任务；UI 不直接依赖 Dify；组件由 `ui_action` 驱动；操作以 `ClientEvent` 回传。

## 1. 固定主线

```text
需求收集 → 补齐参数 → 生成与校验 → 行程/地图展示 → 局部修改 → 保存与继续
```

P0 完成前不做多人协作、攻略导入、实时执行、PDF 分享等 P1/P2 功能。

## 2. 依赖方向

```text
Presentation
    ↓
Application / Controller
    ↓
Domain + Gateway interfaces
    ↓
Dify / Backend / AMap / Weather / Storage adapters
```

禁止：

- UI import `dify_travel_agent.dart`
- 页面解析 `replyText`、`planDraft`、`missing_slots`
- 根据 AI 文案猜日历或其他组件
- 组件把日期只拼成自然语言发送
- 客户端保存 Dify Key、和风私钥、高德 Web Service Key

## 3. P0 执行顺序

| 阶段 | 任务 | 验收重点 |
|---|---|---|
| R0 | 基线冻结与安全检查 | analyze/test/截图/凭证确认 |
| R1 | 拆分 `main.dart` | 行为不变，入口文件最小化 |
| R2 | Domain + 标准协议 | AssistantResponse / UiAction / ClientEvent |
| R3 | Dify Adapter | UI 不认识 Dify 原始字段 |
| R4 | UiActionDispatcher | 日期、范围、选项、数字、确认、冲突 |
| R5 | ClientEvent 回传 | ISO 日期、复用 conversation_id |
| R6 | 会话与旅行持久化 | 重启可恢复，一个会话持续追加 |
| R7 | 真实行程驱动 UI | days/budget/warnings 进入现有页面 |
| R8 | 地图真实路线 | Marker、Polyline、卡片联动 |
| R9 | 局部修改 | 换景点、轻松一点、降低预算 |
| R10 | 清理与文档 | 密钥、测试、README、架构同步 |

## 4. 第一项任务卡：P0-R1

```text
任务名称：P0-R1 拆分 main.dart（行为保持不变）

目标：
- 将首页、聊天页、行程详情、探索页拆到独立模块。
- 不改变视觉、交互、Dify 请求和地图行为。

允许修改：
- lib/main.dart
- lib/app/**
- lib/features/**
- test/**

禁止修改：
- Dify 工作流协议
- Android/iOS 原生地图实现
- UI 视觉参数
- pubspec 依赖（除非先说明理由）

验收条件：
1. main.dart 只保留初始化和 runApp。
2. flutter analyze 通过。
3. flutter test 通过。
4. 启动页、首页、聊天、计划详情与重构前一致。
5. 给出移动文件清单和风险说明。

执行要求：
- 先列出移动顺序再修改。
- 小步提交，不一次重写全部代码。
- 不确定时停止并说明，不自行改变产品逻辑。
```

## 5. 每个功能的任务模板

```text
任务名称：
用户场景：
输入：
输出：
UiAction：
ClientEvent：
允许修改：
禁止修改：
成功场景：
失败场景：
自动化测试：
人工验收：
```

## 6. 每次提交前检查

- [ ] 只完成一个任务
- [ ] `flutter analyze` 通过
- [ ] `flutter test` 通过
- [ ] Android 模拟器关键场景通过
- [ ] 无 Dify 原始字段进入 UI
- [ ] 无密钥进入仓库
- [ ] 文档和状态清单已更新
- [ ] 提交中没有无关格式化或重构

## 7. P0 最终验收

- [ ] `main.dart` 仅保留启动入口
- [ ] Dify 可替换，UI 仅依赖 `TravelAssistantGateway`
- [ ] `ui_action.type` 控制组件
- [ ] 日期和选项以 `ClientEvent` 结构化回传
- [ ] `conversation_id`、`trip_id`、版本可恢复
- [ ] 真实行程驱动聊天卡片、计划详情和地图
- [ ] 支持局部修改并更新版本
- [ ] 客户端不保存服务端密钥
- [ ] 文档与代码一致
