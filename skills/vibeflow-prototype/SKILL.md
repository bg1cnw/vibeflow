---
name: vibeflow-prototype
description: "Prototype 阶段 — 把需求、设计、故事转成可交互原型 / UI 仿真 / 流程仿真。支持 ui / flow / skipped 三种模式。"
---

# VibeFlow Prototype

`prototype` 阶段位于 `stories` 之后、`tasks` 之前。

它不是生产实现 skill。它回答的是"**这些事在界面/流程上怎么跑、怎么点、怎么暴露问题**"。

## 定位

> 把需求、设计、故事，转成可交互原型 / UI 仿真 / 流程仿真

它要做的是：

- 能点
- 能走
- 能模拟关键流程
- 能提前暴露交互问题
- 能在编码前发现设计不合理

**启动宣告：** "正在使用 vibeflow-prototype — 交互合同阶段。"

## 输入文档

### 必需输入

- `docs/changes/<change-id>/brief.md`
- `docs/changes/<change-id>/design.md`
- `docs/changes/<change-id>/stories.md`

### 可选输入

- design tokens / theme 规则
- 组件规范
- 页面结构规范
- 路由或页面清单
- 现有原型/页面模板参考

### 输入原则

- 必须依赖 stories
- 必须依赖 design
- 不能绕过上游自己发明业务目标

## 输出文档 / 文件

### A. 原型本体

- 可交互页面
- 页面模板
- mock 数据
- 关键流程仿真
- loading / empty / error / success 状态
- 页面交互脚本

### B. 原型说明

- `docs/changes/<change-id>/prototype.md` 或 `docs/changes/<change-id>/ui-spec.md`
- 页面清单
- 页面状态说明
- 交互说明
- 状态切换说明
- 原型影响说明

可选的工程化目录结构：
```
docs/changes/<change-id>/prototype/
├── pages/
├── theme/
└── prototype.md
```

## prototype_mode

prototype 必须有明确模式字段：

- `ui` — 有明确用户交互面，生成可点击原型页面
- `flow` — 没有明显页面，但要做流程/状态/时序仿真
- `skipped` — 完全没必要做原型，跳过并记录原因

### 模式判定规则

#### 1. 有用户故事 + 有交互面

→ `prototype_mode = ui`

适合：
- 登录页
- 工作台
- 管理后台
- 表单流程
- 多步骤页面

#### 2. 没有用户故事，但有系统行为需要验证

→ `prototype_mode = flow`

适合：
- API 编排
- 服务状态流
- worker/job 流程
- 任务调度/回调/时序验证

#### 3. 没有原型价值

→ `prototype_mode = skipped`

适合：
- 纯后端
- 纯任务
- 纯同步逻辑
- 没有交互面也没有必要仿真的项目

## 实现方法参考

在生成原型页面和页面模板时，**必须**参考以下三个技能的实现方法，而非从零发明：

### web-design-engineer

提取以下方法用于原型页面构建：
- **Step 3: 先声明设计系统再写代码** — 在生成任何页面之前，先输出颜色/排版/间距/圆角/阴影/动效的完整 Token 声明，经用户确认后再开始
- **Step 4: v0 草稿先行** — 先产出带占位符的结构稿让用户纠正方向，避免做完才发现方向不对
- **Anti-Cliché 检查** — 避开通用的紫色渐变/Inter字体/左色条卡片/表情替代图标等 AI 模板味
- **Tweaks 面板** — 提供实时参数调整面板（主题色/字号/间距/深色模式等），让用户在原型阶段就能探索变化
- **Placeholder 哲学** — 缺图标用 `▢` 占位，缺图片用比例框占位，不造假数据
- **Pre-delivery Checklist** — 交付前逐项自查（无控制台报错、无颜色游离、状态覆盖完整）

### frontend-design

提取以下方法用于页面美学设计：
- **设计思维前置** — 每个页面先明确 Purpose / Tone / Constraints / Differentiation
- **排版** — 选独特字体，避免 Inter/Roboto/Arial；display font 与 body font 分工明确
- **空间构成** — 不对称布局、重叠、对角线、破网格元素、充裕留白
- **背景与视觉细节** — 渐变网格、噪点纹理、几何图案、分层透明、戏剧化阴影
- **动效** — 高冲击时刻的编排入场动画（staggered reveal + animation-delay），优于散落微交互

### web-artifacts-builder

提取以下方法用于复杂原型构建：
- **技术栈参考** — React 18 + TypeScript + Vite + Tailwind CSS + shadcn/ui 组件体系
- **单文件打包** — Parcel 打包 + html-inline 产物化，产出可独立分享的单 HTML 文件
- **shadcn/ui 组件** — 40+ 预装组件可直接用于高保真原型页面

### 使用原则

- **原型阶段不引入构建工具链** — web-artifacts-builder 的 Vite+Parcel 栈仅在需要复杂交互原型时参考；简单页面模板直接用单 HTML 文件
- **设计系统必须从 design.md/ucd.md 提取** — 不自行发明风格，只在上游给定的 Token 范围内运用上述方法
- **原型本体仍是交互合同** — 不为"好看"而做完整业务逻辑，保持边界意识

---

## 生成流程

1. 运行 `python scripts/get-vibeflow-paths.py --json` 确认当前 change root
2. 读取 `brief.md`，了解产品目标和验收标准
3. 读取 `design.md`，提取设计决策、UI/UX 方案、组件规范、design tokens
4. 读取 `stories.md`，提取所有 story 的交互面、流程、状态
5. 判定 `prototype_mode`（ui / flow / skipped）
6. 按模式生成原型：
   - **ui 模式**：
     - 应用「实现方法参考」中的 web-design-engineer 流程（声明系统 → v0 → 完整构建）和 frontend-design 美学方法
     - 生成可交互 HTML 页面（每个关键页面一个）
     - 包含 loading / empty / error / success / edge 状态
     - 使用 mock 数据驱动展示
     - 关键流程可点击走通
   - **flow 模式**：
     - 生成流程仿真（时序图/状态机可执行版本）
     - mock 数据流和回调
     - 异常路径演练
   - **skipped 模式**：
     - 记录跳过原因
     - 说明为什么不需要原型
7. 生成 `prototype.md` 说明文档
8. 保存后，等待用户确认进入 tasks

## 修改分层规则

### A. 只改主题 / 配色 / 字体 / 圆角 / 阴影

- 只影响 prototype / theme 层
- 通常不回流 stories
- 通常不回流 design
- 通常也不回流 requirements

这正好满足：
> 改配色，不影响前面几个流程

### B. 改页面结构 / 状态 / 交互顺序

- 会影响 stories
- 会影响 design
- 会影响 tasks
- 会影响测试方案

### C. 改用户目标 / 主流程 / 业务边界

- 可能回流到 stories
- 可能回流到 design
- 甚至回流到 brief / requirements

## 硬要求

- `prototype_mode` 必须在文档开头明确声明
- 每个页面必须覆盖 loading / empty / error / success 四种状态
- 原型必须可直接在浏览器中打开（ui 模式）或可通过脚本运行（flow 模式）
- skipped 模式必须记录明确的跳过原因
- 原型本体和说明文档必须一起产出

## 边界

- 不做完整业务实现
- 不连真实后端
- 不做生产级性能优化
- 不替代 design 做视觉决策
- prototype 是交互合同，不是交付代码

## 系统-only 项目处理

### A. 只有系统故事的项目

stories 仍然要跑，但用 `story_mode=system`

然后：
- 如果需要流程验证 → `prototype_mode=flow`
- 如果不需要原型 → `prototype_mode=skipped`

### B. 极简项目

stories 用 `lite`，prototype 只做最小仿真，或者直接 `skipped`

### C. 真正有交互界面的项目

stories 用 `user`，prototype 用 `ui`

## 阶段审计（必须执行）

在用户确认前，必须对 Prototype 阶段产物进行自审计。使用 Agent 工具启动审计：

```
Agent: explore — 审计 Prototype 阶段产物
检查项：
1. prototype.md 是否存在且 prototype_mode 已声明
2. 原型页面是否覆盖 design.md/ucd.md 中列出的全部关键页面
3. 每个原型页面的所有内部链接是否可跳转（无 href="#" 死链）
4. 每个关键页面是否覆盖 loading/empty/error/success 四种状态
5. 关键用户流程是否可从头走到尾（页面间跳转链路完整）
6. 状态覆盖矩阵是否准确反映每个页面的状态实现情况
7. 版本号是否与上游文档（design.md/stories.md）一致
```

**审计规则**：
- 缺页面 → 自己补上
- 死链接 → 自己修复
- 流程断链 → 自己补全跳转
- 补完后 → 再审计
- 直到全部通过 → 进入确认

## 完成标准

- prototype 本体已生成（或 skipped 原因已记录）
- `prototype.md` 已生成
- `prototype_mode` 已声明
- 每个关键流程可走通（ui/flow 模式）
- 四种状态（loading/empty/error/success）已覆盖（ui 模式）
- 全部页面内部链接可跳转，无死链
- 阶段审计全部通过
- 用户已确认，可以进入 tasks

## 集成

**调用者：** vibeflow-router（prototype 阶段）
**依赖：** `docs/changes/<change-id>/brief.md`、`docs/changes/<change-id>/design.md`、`docs/changes/<change-id>/stories.md`
**可选依赖：** design tokens、组件规范、页面规范、路由清单
**方法参考：** web-design-engineer（设计系统声明/检查清单/Anti-Cliché）、frontend-design（排版/空间构成/视觉细节）、web-artifacts-builder（React+Tailwind+shadcn/ui 组件栈）
**链接到：** vibeflow-tasks（prototype 确认后）
**产出：** prototype 本体文件 + `docs/changes/<change-id>/prototype.md`
