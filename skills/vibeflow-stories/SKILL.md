---
name: vibeflow-stories
description: "Stories 阶段 — 把需求 + 设计文档转成后续流程可直接消费的行为合同。支持 user / system / lite 三种模式。"
---

# VibeFlow Stories

`stories` 阶段位于 `design` 之后、`prototype` 之前。

它回答的不是"长什么样"，而是"**应该发生什么**"。

## 定位

> 把需求 + 设计文档，转成后续流程可直接消费的行为合同

这个"行为合同"不只限于人类用户故事，也可以是：

- **User Story**：有人点、有人操作
- **System Story**：系统/服务/任务/调度器自己做事
- **Lite Story**：极简项目的最小行为合同

不是每个项目都必须写传统用户故事，但每个项目都应该有某种故事合同。

**启动宣告：** "正在使用 vibeflow-stories — 行为合同阶段。"

## 输入文档

### 必需输入

- `docs/changes/<change-id>/brief.md`
- `docs/changes/<change-id>/design.md`

### 可选输入

- `docs/changes/<change-id>/ucd.md`
- `docs/overview/*`
- `rules/*`
- `feature-list.json`
- 命名、状态、流程、验收约定

### 输入原则

- 不重新采集需求
- 不重新做视觉设计
- 只把上游已批准内容合同化

## 输出文档

### 主输出

- `docs/changes/<change-id>/stories.md`

### stories.md 必须包含

- `story_mode` 字段声明（user / system / lite）
- **actor / 角色**
- **目标 / JTBD**
- **主流程**
- **变体流程**
- **错误场景**
- **恢复策略**
- **验收标准**
- **UI / 页面 seed**（如适用）
- **测试 seed**
- **追溯矩阵**（story → feature_id / design_section 映射）

## story_mode

stories.md 必须明确一个模式字段：

- `user` — 有明确人机交互
- `system` — 系统/服务/任务/worker 为 actor
- `lite` — 项目很小，只需要最小合同

### 判定规则

- 用户故事很简单 → 走 `lite`
- 只有系统故事 → 走 `system`
- 有明确用户操作面 → 走 `user`

这样就不会把所有项目都硬套成人类用户故事。

## 生成流程

1. 运行 `python scripts/get-vibeflow-paths.py --json` 确认当前 change root
2. 读取 `brief.md`，提炼目标、范围、非目标、验收标准、用户画像
3. 读取 `design.md`，提炼 feature 清单、交互面、系统组件、数据流
4. 判定 `story_mode`（user / system / lite）
5. 按模式生成对应的行为合同：
   - **user 模式**：按角色 → 目标 → 主流程 → 变体 → 错误 → 恢复 → 验收 写完整用户故事
   - **system 模式**：按系统组件 → 触发条件 → 行为 → 输出 → 异常 → 恢复 写系统故事
   - **lite 模式**：精简为 核心流程 + 关键验收标准 + 边界条件
6. 建立追溯矩阵：每个 story 必须追溯到 design.md 中的 feature_id 或 design_section
7. 为每个 story 生成 UI seed 和测试 seed（供 prototype 和 test 阶段消费）
8. 保存 `stories.md` 后，等待用户确认进入下一阶段

## 修改分层规则

### A. 只改措辞 / 标题 / 顺序

- 只影响 stories.md
- 通常不回流上游

### B. 改流程 / 状态 / 边界 / 验收标准

- 会影响 Prototype
- 会影响 Tasks
- 会影响 Test
- 可能要回看 Design

### C. 改目标 / 范围 / 业务边界

- 要回流 Design
- 甚至回流 brief.md / requirements

## 硬要求

- 每个 story 必须有唯一标识（story_id）
- 每个 story 必须能追溯到至少一个 feature_id 或 design_section
- 每个 story 必须有可验证的验收标准
- story_mode 必须在文档开头明确声明
- stories.md 必须包含追溯矩阵

## 边界

- 不在这里重新设计
- 不在这里生成 feature-list.json
- 不在这里启动实现
- 不重新采集需求
- stories.md 是行为合同，不是设计文档

## 阶段审计（必须执行）

在用户确认前，必须对 Stories 阶段产物进行自审计。使用 Agent 工具启动审计：

```
Agent: explore — 审计 Stories 阶段产物
检查项：
1. stories.md 是否存在且 story_mode 已声明
2. 每个 design.md 中的 Feature 是否有至少一个对应 Story（追溯矩阵覆盖率 = 100%）
3. 追溯矩阵中每个 Story 的 Feature ID 是否在 design.md 中存在
4. 每个Story是否包含全部必需字段（Actor/Goal/Feature/主流程/错误/验收/UI seed/Test seed）
5. 系统故事（SYS-*）是否有明确的 Trigger 和 Feature 映射
6. 版本号是否与上游文档（design.md/ucd.md）一致
7. 故事计数是否与追溯矩阵统计自洽
```

**审计规则**：
- 缺 Story → 自己补上
- Feature 映射缺失 → 自己补上
- 版本号不一致 → 自己统一
- 补完后 → 再审计
- 直到全部通过 → 进入确认

## 完成标准

- stories.md 已生成
- story_mode 已声明
- 每个 feature 至少有一个对应 story
- 追溯矩阵完整
- 阶段审计全部通过
- 用户已确认，可以进入 prototype（或 tasks，如果 prototype 被跳过）

## 集成

**调用者：** vibeflow-router（stories 阶段）
**依赖：** `docs/changes/<change-id>/brief.md`、`docs/changes/<change-id>/design.md`
**可选依赖：** `docs/changes/<change-id>/ucd.md`、`docs/overview/*`、`rules/*`
**链接到：** vibeflow-prototype（stories 确认后）
**产出：** `docs/changes/<change-id>/stories.md`
