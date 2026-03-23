Q:

我希望code review相关的command能够调用code-review相关的技能，我非常喜欢google codereview相关的指引，并且将其作为了submodule references/google-cr-guideline，里面包含了作为reviewer、author两种角色的指引，但是内容非常多。

我不确定我的command、skill应该怎么写，才是一种最佳实践。我相信llm里面可能已经训练了这google code review guideline的部分内容，毕竟这部分内容在github开源的。但是我希望code review过程能够严格按照这个过程来执行。特别是希望AI能参考人类review的方式来进行的时候。

而且google code review guideline内容非常多，我不确定每次review都让其来阅读这个submodule下内容是不是一种好的实践，会不会特别消耗token、算力。

请结合ai agent的实现、llm训练和推理的工作逻辑，来谈谈，我应该如何优化现在的/review command以及相关的skill。

---



这是一个非常好的问题，涉及到 LLM 的训练知识、上下文窗口管理、token 成本优化等核心问题。让我先看看你现有的 command 和 skill 是怎么写的，然后给你一个深入的分析和建议。
现在让我读一下 reviewer 和 developer 指南的核心内容，了解总量：
现在我已经全面了解了你的 command、skill 以及 Google CR Guideline 的完整内容。让我给你一个深入的分析。

---

## 深度分析：如何优化 `/review` Command 和 Code-Review Skill

### 一、核心问题的本质

你面对的其实是 **LLM 应用中的经典"知识注入"问题**：

| 方式 | 优势 | 劣势 |
|------|------|------|
| **依赖 LLM 训练知识** | 零 token 成本，零延迟 | 知识可能不精确、不完整、无法强制执行 |
| **每次注入原文到上下文** | 严格精确 | 消耗大量 token（~15K tokens），增加推理成本和延迟 |
| **蒸馏摘要注入** | 平衡精确性和成本 | 需要人工维护摘要，可能丢失细节 |

### 二、LLM 训练知识 vs. 运行时注入——你需要理解的关键

#### 2.1 LLM 确实"学过"Google CR Guideline

Google Engineering Practices 在 GitHub 上是热门开源项目（星标极高），几乎可以肯定已被训练数据收录。这意味着：

- LLM **已经内化了核心原则**：如 "The Standard of Code Review"（只要改进了整体代码健康度就应该批准）、"Nit:" 前缀标记非关键问题、reviewer 关注 Design/Functionality/Complexity/Tests/Naming/Comments/Style/Documentation 等维度
- LLM 在回答 code review 相关问题时**会自然遵循这些原则**

#### 2.2 但"学过"≠"严格执行"

**关键区别**：

```
训练知识 = 概率性的"印象"，会被 prompt 中其他指令覆盖
上下文注入 = 确定性的"指令"，模型必须遵循
```

具体来说：
1. **训练知识会衰减和混淆**：LLM 可能把 Google 的和其他公司的 CR 指引混在一起
2. **训练知识缺乏强制力**：除非你在 prompt 中明确要求"按照 Google CR Guideline 执行"，否则 LLM 可能只用了其中一部分
3. **训练知识无法定制**：你无法指定"只用 reviewer 角色的指引"或"跳过 speed 章节"

#### 2.3 最佳实践：分层策略

```
┌─────────────────────────────────────────────────────┐
│ Layer 3: 完整原文（按需加载，极少使用）               │
│   → 争议性问题、用户明确要求"严格按照 Google 标准"     │
├─────────────────────────────────────────────────────┤
│ Layer 2: 蒸馏摘要（写入 skill，每次 review 都加载）   │
│   → 核心原则 + 决策框架 + 检查维度，~2K tokens        │
├─────────────────────────────────────────────────────┤
│ Layer 1: LLM 训练知识（免费，始终存在）               │
│   → 通过 skill 中的关键词"激活"模型的相关知识          │
└─────────────────────────────────────────────────────┘
```

### 三、具体优化建议

#### 3.1 Skill 的优化——"蒸馏"Google CR Guideline

你不需要每次都注入原文。正确的做法是：**把 Google CR Guideline 的核心决策逻辑"蒸馏"成一份精炼的审查框架**，嵌入到 skill 中。

这里的关键洞察是：

> **"激活"LLM 已有知识只需要关键词和框架，不需要原文。**

比如，你在 skill 中写：

```markdown
审查标准遵循 Google Engineering Practices - Code Review Guidelines：
- 核心原则：只要 CL 整体上改进了代码库健康度，即使不完美也应批准（continuous improvement > perfection）
```

这一句话就足以"激活"LLM 关于 `standard.md` 整篇文章的训练知识。

#### 3.2 应该蒸馏哪些内容

Google CR Guideline 中，**真正对 AI Code Review 有价值的部分**和**只对人类流程有价值的部分**是不同的：

| 内容 | 对 AI Review 的价值 | 处理方式 |
|------|---------------------|----------|
| **What to Look For** (looking-for.md) | ⭐⭐⭐ 核心 | 蒸馏审查维度到 skill |
| **The Standard** (standard.md) | ⭐⭐⭐ 核心 | 蒸馏核心原则到 skill |
| **How to Write Comments** (comments.md) | ⭐⭐⭐ 核心 | 蒸馏评论风格到 skill |
| **Navigate a CL** (navigate.md) | ⭐⭐ 有用 | 蒸馏审查顺序到 skill |
| **CL Descriptions** (cl-descriptions.md) | ⭐ 次要 | 不需要，AI 不写 CL description |
| **Speed of Reviews** (speed.md) | ❌ 不适用 | 跳过，这是人类流程问题 |
| **Handling Pushback** (pushback.md) | ❌ 不适用 | 跳过，AI 不存在人际冲突 |
| **Small CLs** (small-cls.md) | ⭐ 次要 | 蒸馏为"变更过大时建议拆分" |

#### 3.3 Command 和 Skill 的职责划分

当前你的 command 和 skill 有大量重复内容（报告格式、检查步骤都重复了一遍）。最佳实践是：

```
Command（/review）= 触发器 + 输入获取
  → "做什么"：获取 diff、调用 skill

Skill（code-review）= 完整的审查方法论 + 输出规范
  → "怎么做"：审查原则、检查维度、评论风格、报告格式
```

#### 3.4 关于 Token 成本的量化分析

| 方案 | 估算 Token 消耗 | 效果 |
|------|------------------|------|
| 每次注入 Google CR 原文全部 13 个 md | ~15,000 tokens（输入） | 100% 忠实，但浪费巨大 |
| 蒸馏摘要写入 skill | ~2,000 tokens（输入） | 95%+ 效果，成本降低 87% |
| 只靠 LLM 训练知识 | 0 extra tokens | ~70% 效果，行为不可控 |

**推荐方案**：蒸馏摘要（Layer 2），在 skill 中用 ~2K tokens 覆盖核心内容，用关键术语激活 LLM 的训练知识。

### 四、优化后的实现方案

基于以上分析，我建议按以下方式重构：

#### 4.1 优化后的 `/review` Command

```markdown
请对当前 git 变更执行 AI Code Review。

1. 执行 `git diff --staged` 获取暂存区变更
2. 执行 `git diff` 获取工作区已跟踪文件变更
3. 执行 `git ls-files --others --exclude-standard` 获取未跟踪文件，并用 `cat` 查看内容
4. 如果以上均无变更，执行 `git diff HEAD~1` 获取最近一次提交的变更
5. 合并所有变更，按照 code-review Skill 执行完整审查
```

Command 只负责"获取输入"，审查方法论全部交给 skill。

#### 4.2 优化后的 Code-Review Skill

核心改动：将 Google CR Guideline 蒸馏为**审查哲学 + 决策框架 + 评论规范**，融入现有 skill 结构：

```markdown
# AI 辅助 Code Review

## 审查哲学（基于 Google Engineering Practices - Code Review Guidelines）

### 核心标准
- **持续改进原则**：只要 CL 整体上改进了代码库健康度，即使不完美也应通过。追求 continuous improvement 而非 perfection。
- **不存在"完美"的代码，只有"更好"的代码。**
- 不能让不良代码"以后再清理"——经验证明"以后"几乎不会发生。

### 审查原则
- 技术事实和数据优先于个人观点和偏好
- Style Guide 是样式问题的最终裁判；Style Guide 未覆盖的，保持与现有代码一致
- 软件设计问题几乎不是纯样式问题，应基于工程原则评判
- 如果作者能证明多种方案同样有效，应尊重作者的选择

## 审查流程

### Step 1: 整体审视（Navigate a CL）
1. 阅读变更描述/commit message，理解变更目的
2. **先看主要变更文件**（逻辑变更最多的文件），建立整体理解
3. 如果发现重大设计问题，立即指出，不必继续细审
4. 如果变更过大（>400 行），建议作者拆分

### Step 2: 逐维度审查（What to Look For）
按优先级依次检查：

**Design（设计）**
- 各部分代码的交互是否合理？变更是否属于当前代码库（vs. 应该在 library 中）？
- 是否过度设计？开发者不应实现"未来可能需要"的功能，解决当下已知问题即可

**Functionality（功能）**
- 代码行为是否符合预期？对使用者（终端用户 + 其他开发者）是否友好？
- 特别关注：并发问题（死锁、竞态条件）、边界条件、用户可感知的影响

**Complexity（复杂度）**
- 代码能否被未来的开发者快速理解？
- 判断标准："读者无法快速理解" = 太复杂

**Tests（测试）**
- 是否随生产代码一起添加了测试？测试是否正确、有意义？
- 测试在代码被破坏时是否真的会失败？测试本身也是需要维护的代码，不接受不必要的复杂度

**Naming（命名）**
- 名称是否足够长以传达含义，又不过长影响可读性？

**Comments（注释）**
- 注释是否解释了 WHY 而不是 WHAT？如果需要解释 WHAT，说明代码本身需要简化
- 是否有可以清理的过时 TODO？

**Style（样式）**
- 是否符合项目 style guide？纯样式问题标记为 "Nit:"

**Documentation（文档）**
- 涉及构建/测试/交互方式变更时，是否同步更新了文档？

### Step 3: 安全检查（项目特定）
- [ ] SQL 注入、未校验用户输入
- [ ] 硬编码敏感信息（密钥、密码、Token）
- [ ] 不安全的并发操作（竞态条件）
- [ ] 不安全的加密使用

### Step 4: 性能检查（项目特定）
- [ ] 循环中不必要的分配
- [ ] 缺失的 context timeout
- [ ] 可预分配的 slice/map
- [ ] N+1 查询

## 评论风格（How to Write Review Comments）

### 分级标记（必须遵循）
- **🔴 Critical**：必须修改，影响正确性/安全性/设计
- **🟡 Suggestion**：建议修改，改善代码健康度但非阻塞
- **Nit:**：纯样式/微小改进，作者可选择忽略
- **🟢 Good**：值得肯定的实践（review 不应只关注问题）

### 评论原则
- 评论代码，不评论开发者（"The concurrency model adds complexity..." vs. "Why did you..."）
- 解释 WHY：不只说"改这里"，要说明为什么这样更好
- 平衡指导与自主：指出问题，让开发者决定方案；必要时才给出具体代码建议
- 对好的实践给予肯定——这对工程文化很重要

## 输出格式

### Code Review 报告

#### 变更摘要
- **目的**：[一句话概括]
- **变更范围**：[X 个文件，+Y/-Z 行]
- **涉及模块**：[模块列表]
- **变更类型**：feature / bugfix / refactor / config

#### 🔴 必须修改 (Critical)
- [文件:行号] [问题描述] → [修改建议]

#### 🟡 建议修改 (Suggestion)
- [文件:行号] [问题描述] → [修改建议]

#### Nit（可选改进）
- [文件:行号] [改进点]

#### 🟢 值得肯定 (Good)
- [亮点和好的实践]

#### 📊 统计
- 检查项：X 项 | Critical：X | Suggestion：X | Nit：X

## 注意事项
- AI Review 是辅助，不替代人工 Review
- AI 擅长：规范合规、已知模式的 bug、安全反模式检测
- 人类聚焦：业务逻辑正确性、架构演进方向、产品判断
- 对 Critical 问题必须修改后才能合入
```

### 五、总结

| 维度 | 当前做法 | 建议做法 |
|------|---------|---------|
| Google CR 知识注入 | 未注入 | **蒸馏摘要写入 skill**（~2K tokens） |
| Command 职责 | 包含审查流程和报告格式 | **只负责获取 diff** |
| Skill 职责 | 流程 + 格式 | **审查哲学 + 决策框架 + 评论规范 + 格式** |
| 重复内容 | Command 和 Skill 大量重复 | **消除重复，单一来源** |
| 原文使用 | N/A | **不需要每次加载；争议时可手动引用** |
| Nit 分级 | 只有 Critical/Suggestion/Good | **增加 Nit 层级**（Google 核心实践） |
| 肯定好的实践 | 有但不突出 | **强调正向反馈**（Google 核心实践） |
| 审查顺序 | 平铺检查 | **先整体再局部，先设计再细节** |

**核心结论**：不要每次读 submodule 原文（浪费 token），也不要完全依赖训练知识（不可控）。把 Google CR Guideline 的**决策框架和核心原则蒸馏成 ~2K tokens 的精炼摘要**，写入 skill，用关键术语激活 LLM 的训练知识，这是成本和效果的最优平衡。

---

要不要我帮你直接按这个方案更新 `review.md` command 和 `code-review.md` skill？
