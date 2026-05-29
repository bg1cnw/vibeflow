---
name: vibeflow-tasks
description: "Tasks 阶段 — 基于 brief、design、stories 与 prototype 产出 execution-grade tasks.md，作为 Build 的正式交接输入。"
---

# VibeFlow Tasks

`tasks` 阶段位于 `prototype` 之后、`build` 之前。

它回答的不是”做什么”，而是”**具体按什么顺序执行**”。

## 输入

- `docs/changes/<change-id>/stories.md`
- `docs/changes/<change-id>/prototype.md`

- `docs/changes/<change-id>/brief.md`
- `docs/changes/<change-id>/design.md`
- `docs/changes/<change-id>/ucd.md`（如存在）
- `rules/`（如存在）
- `docs/templates/tasks-template.md`

## 输出

- `docs/changes/<change-id>/tasks.md`

## 硬要求

每个任务块都必须包含：

- `task_id`
- `feature_id`
- `goal`
- `exact_file_paths`
- `change_type`
- `depends_on`
- `steps`
- `verification_steps`
- `rollback_note`
- `expected_duration_min`

## 质量门

- 一个任务块只做一个明确动作
- 默认控制在 2-5 分钟粒度
- 超过 10 分钟必须拆分
- `exact_file_paths` 必须是仓库内精确路径
- `verification_steps` 必须是可执行验证
- `rollback_note` 必须说明最小撤销路径
- 每个任务块必须能追溯到 `feature_id`、`build_contract_ref`、`design_section` 中至少一个正式索引

## 生成流程

1. 运行 `python scripts/get-vibeflow-paths.py --json` 确认当前 change root
2. 读取 `brief.md`，提炼目标、范围、非目标、验收标准、约束
3. 读取 `design.md` 中的设计、评审结论与范围决策，提炼 feature、文件范围、依赖、验证策略
4. 读取 `stories.md`，提取行为合同与验收标准，确保任务覆盖所有 story
5. 读取 `prototype.md`，提取交互验证结论与流程约束
6. 如有 `rules/`，确保任务拆分不违背项目规则
7. 使用 `docs/templates/tasks-template.md` 生成 `tasks.md`
8. 保存后，等待进入 `build`

## 边界

- 不在这里重写设计
- 不在这里生成 `feature-list.json`
- 不在这里启动实现
- `tasks.md` 是 handoff plan，不是 another runtime

## 集成

**调用者：** vibeflow-router（tasks 阶段）
**依赖：** `docs/changes/<change-id>/brief.md`、`docs/changes/<change-id>/design.md`、`docs/changes/<change-id>/stories.md`、`docs/changes/<change-id>/prototype.md`
**链接到：** vibeflow-build-init（tasks 确认后）
**产出：** `docs/changes/<change-id>/tasks.md`

## 阶段审计（必须执行）

在用户确认前，必须对 Tasks 阶段产物进行自审计。使用 Agent 工具启动审计：

```
Agent: explore — 审计 Tasks 阶段产物
检查项：
1. tasks.md 是否存在且每个实现 feature 至少有一个任务块
2. 每个任务块是否包含全部必需字段（task_id/feature_id/goal/exact_file_paths/steps/verification_steps/rollback_note/expected_duration_min）
3. exact_file_paths 是否为仓库内精确路径（无"相关文件""必要时"等模糊词）
4. 每个任务块是否能追溯到 design.md 中的 feature_id/build_contract_ref/design_section
5. expected_duration_min 是否 ≤10 分钟（超过的必须拆分）
6. 任务依赖链（depends_on）是否有循环依赖
7. 里程碑/阶段是否覆盖 design.md 开发计划中的所有里程碑
8. 前后端任务是否按"后端→前端"配对排序
9. 版本号是否与上游文档一致
```

**审计规则**：
- 缺任务块 → 自己补上
- 字段不全 → 自己补上
- 路径模糊 → 自己修正为精确路径
- 依赖循环 → 自己调整顺序
- 补完后 → 再审计
- 直到全部通过 → 进入确认

## 完成标准

- `tasks.md` 已生成
- 每个实现 feature 至少有一个任务块
- 阶段审计全部通过
- Build 可以直接把它当作 execution planning input 使用
