# 02 — AI Coding 工具全景与选型

> 工欲善其事，必先利其器。选对 AI IDE，是人机协作的第一步。

## 一、AI IDE 全景图（2025-2026）

### 1.1 主流 AI IDE / 编辑器

| 工具 | 类型 | 底层编辑器 | 定价模式 | 主要面向 |
|------|------|-----------|---------|---------|
| **Cursor** | 独立 IDE | VS Code Fork | $20/月 Pro | 全栈开发者 |
| **GitHub Copilot** | 插件 | VS Code / JetBrains / Neovim | $10-39/月 | 企业级广泛使用 |
| **CodeBuddy (Tencent)** | 插件/IDE | VS Code | 免费/Pro | 腾讯生态 |
| **Windsurf (Codeium)** | 独立 IDE | VS Code Fork | $10/月 Pro | 注重体验 |
| **Augment Code** | 插件 | VS Code / JetBrains | $50/月 Pro | 大型代码库 |
| **Cline** | 插件 | VS Code | 开源免费 (自带 key) | 极客 / 高度定制 |
| **Aider** | CLI 工具 | 终端 | 开源免费 | 终端重度用户 |
| **Claude Code** | CLI 工具 | 终端 | API 按量计费 | Anthropic 生态 |
| **Gemini CLI** | CLI 工具 | 终端 | API 按量计费 | Google 生态 |
| **Trae** | 独立 IDE | VS Code Fork | 免费 | 字节跳动生态 |
| **JetBrains AI** | 内置 | JetBrains 全系 | JetBrains 订阅 | JetBrains 用户 |

### 1.2 核心能力矩阵

| 能力 | Cursor | Copilot | CodeBuddy | Windsurf | Cline | Claude Code |
|------|--------|---------|-----------|----------|-------|-------------|
| **Tab 补全** | ✅ 多候选 | ✅ | ✅ | ✅ | ❌ | ❌ CLI |
| **Chat 对话** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Inline Edit** | ✅ Cmd+K | ✅ | ✅ | ✅ | ❌ | ❌ |
| **Agent 模式** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ 原生 |
| **Multi-file Edit** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Rules 系统** | ✅ .cursorrules | ✅ .github/copilot | ✅ .codebuddy | ✅ .windsurfrules | ✅ .clinerules | ✅ CLAUDE.md |
| **Skills** | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ |
| **Custom Commands** | ✅ /commands | ✅ | ✅ | ❌ | ❌ | ✅ /commands |
| **MCP 支持** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **多模态** | ✅ 图片 | ✅ 图片 | ✅ 图片 | ✅ 图片 | ✅ | ✅ |
| **Worktree/分支** | ✅ | ✅ Git | ✅ | ❌ | ❌ | ✅ |
| **子代理(SubAgent)** | ✅ | ❌ | ✅ | ❌ | ❌ | ✅ |
| **上下文管理** | ✅ @file @folder | ✅ #file | ✅ @file | ✅ @file | ✅ | ✅ |
| **部分接受** | ✅ 逐词 | ✅ 逐词 | ✅ | ✅ | N/A | N/A |
| **Privacy Mode** | ✅ | ❌ | ❌ | ✅ | ✅ 本地 | ❌ |

---

## 二、核心概念解析

### 2.1 Rules 系统

Rules 是 AI IDE 最重要的人机协作基础设施。它告诉 AI "你应该怎么做"。

```
Rules 的本质：将人类的工程经验编码为 AI 可理解、可执行的指令。
```

**各 IDE 的 Rules 机制对比**：

| IDE | 文件位置 | 作用域 | 类型 |
|-----|---------|--------|------|
| Cursor | `.cursor/rules/*.mdc` | 项目级 | always / auto / manual / agent-requested |
| Copilot | `.github/copilot-instructions.md` | 项目级 | 全局生效 |
| CodeBuddy | `.codebuddy/rules/*.md` | 项目/用户级 | always / manual / requested |
| Windsurf | `.windsurfrules` | 项目级 | 全局生效 |
| Cline | `.clinerules` | 项目级 | 全局生效 |
| Claude Code | `CLAUDE.md` | 项目/目录级 | 全局生效 |

**Rules 的分类与最佳实践**：

| 类型 | 说明 | 适用场景 | 示例 |
|------|------|---------|------|
| **always** | 每次对话自动加载 | 核心编码规范 | `go-code-style.rule` |
| **auto/requested** | AI 判断是否需要加载 | 特定场景规范 | `proto-style.rule` |
| **manual** | 用户手动触发 | 架构设计讨论 | `microservice-design.rule` |

### 2.2 Skills 系统

Skills 是更复杂的、可复用的工作流程模板，包含多步骤指令。

```
Rule  ≈ 编码规范（Tell AI what to follow）
Skill ≈ 操作手册（Tell AI how to do a complex task step by step）
```

**Skills 的典型应用**：
- 需求分析：接收需求 → 拆解任务 → 输出任务清单
- TDD 工作流：写测试 → 写实现 → 重构
- Code Review：检查清单 → 生成报告 → 给出建议
- 架构评审：收集信息 → 分析 → 输出评审意见

### 2.3 Commands 系统

Commands 是快捷操作，通过 `/command` 触发预定义的 AI 操作。

```
Rule    ≈ 规矩（被动约束）
Skill   ≈ 教程（主动指导）
Command ≈ 快捷键（一键执行）
```

### 2.4 MCP (Model Context Protocol)

MCP 是 Anthropic 提出的标准协议，让 AI IDE 可以连接外部工具和数据源。

```
┌──────────────┐     MCP      ┌──────────────────┐
│   AI IDE     │ ◄──────────► │  MCP Server       │
│ (MCP Client) │              │  • 数据库查询      │
│              │              │  • Jira 集成       │
│              │              │  • 内部 API 文档   │
│              │              │  • CI/CD 触发      │
└──────────────┘              └──────────────────┘
```

**MCP 的价值**：
- 让 AI 获取项目特定的上下文（数据库 Schema、Jira 需求、内部文档）
- 让 AI 执行操作（触发构建、查询日志、操作数据库）
- 标准化的协议，各 AI IDE 通用

---

## 三、选型建议

### 3.1 选型决策树

```
                        你的团队情况？
                            │
                ┌───────────┼───────────┐
                ▼           ▼           ▼
           腾讯体系     已有 IDE 习惯    追求最新特性
                │           │              │
                ▼           ▼              ▼
           CodeBuddy    JetBrains?     Cursor / Claude Code
                        VS Code?
                            │
                     ┌──────┼──────┐
                     ▼      ▼      ▼
                  Copilot Cursor CodeBuddy
```

### 3.2 推荐组合

#### 方案 A：Cursor + Claude Code（最佳体验）

| 场景 | 工具 | 原因 |
|------|------|------|
| 日常编码 | Cursor | 最强 Tab 补全 + Rules 系统 + Agent |
| 复杂重构 | Claude Code | 终端 Agent，适合大规模代码操作 |
| Code Review | Cursor + GitHub Actions | AI 辅助 Review + CI 集成 |

#### 方案 B：CodeBuddy（腾讯体系最佳）

| 场景 | 工具 | 原因 |
|------|------|------|
| 全场景 | CodeBuddy | 腾讯内部集成好，支持 Rules/Skills/Commands |
| CI/CD | 内部流水线 | 内部生态集成 |
| 协作 | 内部工具链 | 统一体验 |

#### 方案 C：Copilot + VS Code（稳健选择）

| 场景 | 工具 | 原因 |
|------|------|------|
| 日常编码 | VS Code + Copilot | 最广泛的企业支持，稳定可靠 |
| 复杂任务 | Copilot Chat Agent Mode | 多文件编辑能力 |
| CI/CD | GitHub Actions | 深度集成 |

### 3.3 通用性策略

**核心观点**：不要 All-in 单一工具，建立**工具无关的工程规范**。

```
                    工具无关的核心层
    ┌───────────────────────────────────────┐
    │  工程素养 → Markdown 规范文档           │
    │  Rules → 通用 Markdown 格式            │
    │  Skills → 通用工作流描述               │
    │  SOP → 流程文档                        │
    └───────────────────────────────────────┘
                        │
            ┌───────────┼───────────┐
            ▼           ▼           ▼
     Cursor 适配层  Copilot 适配层  CodeBuddy 适配层
     .cursorrules   .github/       .codebuddy/
                    copilot/       rules/
```

**建议**：
1. **核心规范用通用 Markdown** 编写，存放在项目 `docs/ai-rules/` 目录
2. 各 IDE 的 Rules 文件引用或转换自这些通用规范
3. 团队成员可以使用不同 IDE，但遵循同一套规范
4. 定期同步各 IDE 的 Rules 文件

---

## 四、Harness Engineering vs Prompt Engineering

### 4.1 概念演进

```
Prompt Engineering (2023)
  "如何写好提示词让 AI 给出好回答"
        │
        ▼
Context Engineering (2024)
  "如何组织好上下文让 AI 理解完整信息"
        │
        ▼
Harness Engineering (2025-2026)
  "如何系统性地约束、引导、驾驭 AI 的完整行为"
```

### 4.2 Harness Engineering 的核心

| 维度 | 内容 | 对应落地 |
|------|------|---------|
| **Rules** | 行为规范、编码标准 | `.cursorrules` / `.codebuddy/rules/` |
| **Skills** | 复杂工作流编排 | Skill 文件 |
| **Context** | 项目知识、领域信息 | MCP / @docs / 知识库 |
| **Guardrails** | 质量门禁、安全边界 | CI/CD + Rules |
| **Feedback** | 人机交互反馈循环 | Review + PDCA |
| **Memory** | 跨会话记忆和学习 | Memory 系统 / MEMORY.md |

### 4.3 你提到的"给 AI 立规矩"

这正是 Harness Engineering 的核心思想：

> **资深工程师的价值** = 制定规矩的能力 + 判断规矩是否被正确执行的能力

- 初级工程师：写代码 → 被 AI 替代风险高
- 资深工程师：写规矩 → AI 时代价值更高
- 团队：规矩（Rules/Skills） → 集体智慧的沉淀

---

## 五、AI Code Review 的演进

### 5.1 你的疑问："AI 生成代码量很大后，AI Code Review 还有意义吗？"

**答案：不仅有意义，而且必须升级。**

| 阶段 | AI 编码占比 | Review 策略 |
|------|-----------|------------|
| **当前** | 20-40% | 人工 Review 为主 + AI 辅助检查 |
| **近期** | 40-70% | AI 初审 + 人工复审关键路径 |
| **未来** | 70%+ | AI Review + 人类仅审架构决策和业务逻辑 |

### 5.2 AI Code Review 的正确姿势

```
                    AI 生成代码
                        │
                        ▼
              ┌─── 自动化门禁 ───┐
              │  Lint ✓           │
              │  Tests ✓          │
              │  Security ✓       │
              │  Proto Check ✓    │
              └────────┬─────────┘
                       │
                       ▼
              ┌─── AI Review ───┐
              │  规范合规性       │
              │  常见 bug 模式   │
              │  性能隐患        │
              │  可读性评分       │
              └────────┬────────┘
                       │
                       ▼
              ┌─── 人工 Review ──┐
              │  业务逻辑正确性   │
              │  架构合理性       │
              │  设计意图理解      │
              │  边界 case 判断   │
              └─────────────────┘
```

**关键洞察**：
- AI Review 不是替代人工 Review，而是**过滤噪音，聚焦高价值审查**
- AI 擅长：格式、规范、已知 pattern 的 bug → 自动化
- 人类擅长：业务理解、架构判断、设计取舍 → 聚焦
- 即使 AI 生成的代码也需要 Review，因为 AI 可能"自信地写出错误代码"

---

> 📌 **下一步**：请继续阅读 [03 - Rules/Skills/Commands 设计](ai_best_practices_03_rules_skills_commands.md)，了解如何将工程素养和领域经验沉淀为 AI 可执行的规则。
