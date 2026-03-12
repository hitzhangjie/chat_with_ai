# 03 — 人机协作工作流设计：Rules / Skills / Commands

> "Rules 是给 AI 的规矩，Skills 是给 AI 的手册，Commands 是给人的快捷键。"

## 一、整体架构

```
┌────────────────────────────────────────────────────────────────────────┐
│                        人机协作工作流架构                                │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│  开发者日常工作                                                         │
│  ┌──────────────────────────────────────────────────────────────┐      │
│  │  需求理解 → 方案设计 → 编码实现 → 测试 → Review → 交付       │      │
│  └──────┬───────┬──────────┬────────┬──────┬──────┬─────────────┘      │
│         │       │          │        │      │      │                    │
│  AI辅助 ▼       ▼          ▼        ▼      ▼      ▼                    │
│  ┌──────────┬──────────┬──────────┬──────┬──────┬──────────┐          │
│  │ Skill:   │ Skill:   │ Rules:   │Rule: │Cmd:  │ Skill:   │          │
│  │ 需求分析 │ 方案设计 │ 编码规范 │测试  │review│ 交付检查 │          │
│  └──────────┴──────────┴──────────┴──────┴──────┴──────────┘          │
│         │       │          │        │      │      │                    │
│         └───────┴──────────┴────────┴──────┴──────┘                    │
│                            │                                           │
│                     ┌──────┴──────┐                                    │
│                     │  MCP Server │                                    │
│                     │ 内部API文档  │                                    │
│                     │ Jira/需求   │                                    │
│                     │ DB Schema   │                                    │
│                     └─────────────┘                                    │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 二、Rules 设计指南

### 2.1 Rules 设计原则

| 原则 | 说明 | 反模式 |
|------|------|--------|
| **具体可执行** | 规则必须具体到 AI 可以直接执行 | ❌ "写好代码" → ✅ "函数不超过 50 行" |
| **有理有据** | 每条规则附带原因和示例 | ❌ 只给规则不给原因 |
| **正反例对照** | 给出正确和错误示例 | ❌ 只有规则没有示例 |
| **适度约束** | 规则不宜过多过细，保留灵活性 | ❌ 100 条细枝末节的规则 |
| **持续演进** | 基于实际使用效果迭代 | ❌ 写完就不管了 |

### 2.2 Rules 文件结构模板

```markdown
---
description: [规则的简要描述，AI 用来判断是否需要加载]
globs: [适用的文件匹配模式，如 "**/*.go"]
alwaysApply: [true/false]
---

# 规则名称

## 目标
[这条规则要达成什么目标]

## 规则

### 必须遵守（MUST）
- [规则 1]
- [规则 2]

### 应当遵守（SHOULD）
- [规则 1]

### 禁止（MUST NOT）
- [规则 1]

## 示例

### ✅ 正确
```code
// 正确示例
```

### ❌ 错误
```code
// 错误示例
```

## 原因
[为什么制定这条规则]
```

### 2.3 核心 Rules Demo

#### Rule 1：Go 编码规范 (`go-code-style.rule`)

```markdown
---
description: Go 语言编码规范，适用于所有 Go 源代码文件
globs: "**/*.go"
alwaysApply: true
---

# Go 编码规范

## 目标
确保团队 Go 代码风格统一、可读性强、易于维护。

## 规则

### 命名规范（MUST）
- 包名：小写单词，不使用下划线，不使用驼峰。如 `userservice`，不是 `user_service`
- 导出标识符：PascalCase，如 `UserService`
- 非导出标识符：camelCase，如 `userName`
- 接口名：以 `-er` 后缀命名单方法接口，如 `Reader`、`Writer`、`Closer`
- 缩写词全大写或全小写：`HTTPClient`（导出）或 `httpClient`（非导出），不是 `HttpClient`
- 避免包名与导出符号重复：`user.User` 不好，`user.Info` 或 `user.Profile` 更好

### 函数设计（MUST）
- 函数体不超过 50 行（不含注释和空行）。超过时必须拆分子函数
- 函数参数不超过 5 个。超过时使用 Option 结构体或 Functional Options 模式
- 返回值：正常值在前，error 在最后
- 如果函数可能失败，必须返回 error，不能 panic

### 错误处理（MUST）
- 绝不忽略 error：`_ = doSomething()` 是禁止的
- 使用 `fmt.Errorf("context: %w", err)` 包装错误，提供上下文
- 在包边界处使用自定义错误类型或 sentinel error
- 错误信息小写开头，不以句号结尾

### 并发（MUST）
- 启动 goroutine 必须有明确的退出机制（context cancel / done channel）
- 共享可变状态必须加锁或使用 channel
- 不要在 goroutine 中引用循环变量（Go < 1.22 时需注意）

### 注释（MUST）
- 所有导出的 type、func、const、var 必须有 godoc 格式注释
- 注释以被注释对象的名字开头：`// UserService manages user operations.`
- 包注释放在 `doc.go` 文件中

### 导入（MUST）
- 使用 goimports 自动管理
- 分三组：标准库 / 第三方 / 本项目，空行分隔

## 示例

### ✅ 正确

// 包结构
package userservice

import (
    "context"
    "fmt"

    "github.com/redis/go-redis/v9"

    "github.com/company/project/internal/model"
)

// UserService 管理用户相关的业务逻辑。
type UserService struct {
    repo UserRepository
    cache *redis.Client
}

// GetUser 根据用户ID获取用户信息。
// 优先从缓存获取，缓存未命中时查询数据库。
func (s *UserService) GetUser(ctx context.Context, userID string) (*model.User, error) {
    user, err := s.getFromCache(ctx, userID)
    if err == nil {
        return user, nil
    }

    user, err = s.repo.FindByID(ctx, userID)
    if err != nil {
        return nil, fmt.Errorf("get user %s: %w", userID, err)
    }

    _ = s.setCache(ctx, userID, user) // 缓存写入失败可以容忍
    return user, nil
}

### ❌ 错误

// 包名用了下划线
package user_service

// 没有注释、函数名和包名重复
func (s *Service) GetUserService(id string) *User {
    // 忽略了错误
    user, _ := s.db.Query(id)
    // 没有错误处理
    return user
}

## 原因
统一的编码风格降低了代码审查的认知负担，使团队成员可以快速理解彼此的代码。
Go 社区有成熟的编码规范（Effective Go、Google Go Style Guide、Uber Go Guide），
遵循社区标准可以降低新人上手成本。
```

#### Rule 2：Go 测试规范 (`go-test.rule`)

```markdown
---
description: Go 测试编写规范，适用于所有测试文件
globs: "**/*_test.go"
alwaysApply: true
---

# Go 测试规范

## 目标
确保测试代码质量，提高测试覆盖率和可维护性。

## 规则

### 测试结构（MUST）
- 使用 Table-driven tests 作为默认测试模式
- 测试函数命名：`TestXxx` （单元测试）、`TestIntegration_Xxx`（集成测试）
- 每个测试用例必须有 `name` 字段，描述测试场景
- 使用 `t.Run(tt.name, func(t *testing.T) {...})` 创建子测试
- 测试用例必须覆盖：正常路径 + 错误路径 + 边界条件

### 测试隔离（MUST）
- 测试之间不能有执行顺序依赖
- 不能依赖全局状态
- 外部依赖（数据库、HTTP、MQ）必须 Mock
- 使用接口 + 依赖注入实现可测试性

### Mock（MUST）
- 优先使用接口 Mock，避免 monkey patching
- Mock 对象放在测试文件中或 `_test.go` 专用文件中
- Mock 的行为必须与真实实现的契约一致

### 断言（SHOULD）
- 使用 `testify/assert` 或 `testify/require` 简化断言
- 错误消息要有意义：`assert.Equal(t, expected, got, "user name should match")`
- 对于必须成功的前置条件，使用 `require`（失败时立即停止）

### 性能测试（SHOULD）
- 性能敏感的代码必须有 Benchmark 测试
- Benchmark 函数命名：`BenchmarkXxx`
- 在 PR 中附带 Benchmark 对比结果

## 示例

### ✅ 正确

func TestUserService_GetUser(t *testing.T) {
    tests := []struct {
        name      string
        userID    string
        mockSetup func(*mockUserRepo)
        want      *model.User
        wantErr   bool
    }{
        {
            name:   "existing user",
            userID: "user-123",
            mockSetup: func(m *mockUserRepo) {
                m.users["user-123"] = &model.User{ID: "user-123", Name: "Alice"}
            },
            want:    &model.User{ID: "user-123", Name: "Alice"},
            wantErr: false,
        },
        {
            name:   "non-existing user",
            userID: "user-999",
            mockSetup: func(m *mockUserRepo) {
                // 不设置任何用户
            },
            want:    nil,
            wantErr: true,
        },
        {
            name:   "empty user ID",
            userID: "",
            mockSetup: func(m *mockUserRepo) {},
            want:    nil,
            wantErr: true,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            repo := newMockUserRepo()
            tt.mockSetup(repo)
            svc := NewUserService(repo)

            got, err := svc.GetUser(context.Background(), tt.userID)
            if tt.wantErr {
                assert.Error(t, err)
                return
            }
            require.NoError(t, err)
            assert.Equal(t, tt.want, got)
        })
    }
}

### ❌ 错误

// 没有使用 table-driven，没有测试错误路径
func TestGetUser(t *testing.T) {
    svc := NewUserService(realDB) // 依赖真实数据库
    user, _ := svc.GetUser(context.Background(), "user-123") // 忽略错误
    if user.Name != "Alice" {
        t.Fail()  // 没有有意义的错误消息
    }
}
```

#### Rule 3：Protobuf 规范 (`proto-style.rule`)

```markdown
---
description: Protobuf 文件编写规范
globs: "**/*.proto"
alwaysApply: true
---

# Protobuf 规范

## 目标
确保 Proto 文件规范、可演进、符合 Google API 设计指南。

## 规则

### 文件组织（MUST）
- 文件名：`snake_case.proto`
- 包名格式：`company.project.service.version`，如 `company.game.user.v1`
- go_package：`github.com/company/project/api/service/version;servicevN`
- 每个 proto 文件应聚焦单一 service 或相关的 message 集合

### 命名规范（MUST）
- Message：PascalCase，如 `UserProfile`
- Field：snake_case，如 `user_name`
- Enum：UPPER_SNAKE_CASE，如 `USER_STATUS_ACTIVE`
- Enum 零值：必须带 `_UNSPECIFIED` 后缀，如 `USER_STATUS_UNSPECIFIED = 0`
- Service：PascalCase，如 `UserService`
- RPC 方法：PascalCase，动词开头，如 `GetUser`、`ListUsers`、`CreateUser`

### 字段规范（MUST）
- 不复用已删除的字段编号（使用 `reserved`）
- 必须为每个 message 和 field 添加注释
- 时间戳使用 `google.protobuf.Timestamp`，不使用 int64
- 布尔字段不使用否定命名：✅ `is_active` ❌ `is_not_active`

### API 设计（MUST）
- Request/Response 成对出现：`GetUserRequest` → `GetUserResponse`
- 列表接口支持分页：`page_size` + `page_token`
- 更新接口使用 `FieldMask`
- 批量接口命名：`BatchGetUsers`、`BatchCreateUsers`

### 兼容性（MUST）
- 不修改已有字段的类型
- 不修改已有字段的编号
- 废弃字段使用 `deprecated = true` 选项
- 大版本变更新建 `v2` 包

## 示例

### ✅ 正确
参见 01 文档中的 Proto 示例

### ❌ 错误
- 枚举零值没有 UNSPECIFIED：`STATUS_ACTIVE = 0`
- 字段用驼峰：`userName` 而不是 `user_name`
- 没有注释
- 复用了删除字段的编号

## 原因
Protobuf 是服务间通信的契约，规范的 Proto 文件确保：
1. API 可演进而不破坏兼容性
2. 生成的代码在各语言中风格一致
3. 降低跨团队协作的沟通成本
```

#### Rule 4：可读性规范 (`readability.rule`)

```markdown
---
description: 代码可读性规范，适用于所有 Go 代码
globs: "**/*.go"
alwaysApply: true
---

# 代码可读性规范

## 目标
让代码"自解释"，降低阅读和维护成本。

## 规则

### 代码组织（MUST）
- 函数体不超过 50 行
- 文件不超过 500 行（测试文件例外）
- 嵌套不超过 3 层。超过时使用 early return 或提取函数
- 相关的代码放在一起，用空行分隔逻辑块

### Early Return（MUST）
- 优先处理错误和边界条件，尽早 return
- 避免 if-else 深层嵌套

### 命名即文档（MUST）
- 变量名要表达含义：✅ `userCount` ❌ `n`（循环计数器除外）
- bool 变量用 is/has/can/should 开头：`isActive`、`hasPermission`
- 函数名要表达行为：✅ `SendEmail` ❌ `Process`

### 注释（MUST）
- 解释 WHY，不解释 WHAT（代码本身应该能说明 WHAT）
- 复杂算法必须有注释说明思路
- TODO 必须带负责人和日期：`// TODO(zhangsan, 2026-03): 优化查询性能`
- 删除注释掉的代码，不要保留"以防万一"

## 示例

### ✅ 正确（Early Return）

func (s *Service) ProcessOrder(ctx context.Context, order *Order) error {
    if order == nil {
        return ErrNilOrder
    }
    if order.Status != StatusPending {
        return fmt.Errorf("invalid order status: %s", order.Status)
    }
    if order.Amount <= 0 {
        return ErrInvalidAmount
    }

    // 核心逻辑（不在 if-else 深处）
    return s.repo.Save(ctx, order)
}

### ❌ 错误（深层嵌套）

func (s *Service) ProcessOrder(ctx context.Context, order *Order) error {
    if order != nil {
        if order.Status == StatusPending {
            if order.Amount > 0 {
                return s.repo.Save(ctx, order)
            } else {
                return ErrInvalidAmount
            }
        } else {
            return fmt.Errorf("invalid status")
        }
    } else {
        return ErrNilOrder
    }
}
```

---

## 三、Skills 设计指南

### 3.1 Skills 设计原则

| 原则 | 说明 |
|------|------|
| **目标明确** | 每个 Skill 解决一个明确的、可重复的复杂任务 |
| **步骤清晰** | 分步描述，每步有明确的输入和输出 |
| **可验证** | 每步完成后有检查点 |
| **可迭代** | 基于使用反馈持续优化 |

### 3.2 Skills 文件结构模板

```markdown
---
description: [Skill 的简要描述]
---

# Skill 名称

## 触发条件
[什么情况下应该使用这个 Skill]

## 前置条件
[使用这个 Skill 前需要准备什么]

## 步骤

### Step 1: [步骤名]
**输入**：[需要什么信息]
**操作**：[AI 应该做什么]
**输出**：[产出什么]
**检查点**：[如何验证完成质量]

### Step 2: [步骤名]
...

## 产出物
[最终交付什么]

## 注意事项
[需要特别注意的点]
```

### 3.3 核心 Skills Demo

#### Skill 1：需求分析与任务拆解 (`requirement-analysis.skill`)

```markdown
---
description: 将产品需求拆解为可执行的开发任务，包含方案设计和测试计划
---

# 需求分析与任务拆解

## 触发条件
当开发者收到新需求，需要将其拆解为开发任务时使用。

## 前置条件
- 需求文档或需求描述（文字/截图/Jira 链接）
- 相关系统的上下文信息

## 步骤

### Step 1: 需求理解与澄清
**输入**：原始需求描述
**操作**：
1. 提炼需求的核心目标（用一句话概括）
2. 识别关键实体和操作
3. 列出需求中的模糊点和假设
4. 向开发者确认模糊点

**输出**：需求理解文档
```markdown
## 需求理解
- **核心目标**：[一句话]
- **关键实体**：[实体列表]
- **关键操作**：[操作列表]
- **待确认事项**：[问题列表]
- **假设**：[假设列表]
```

**检查点**：开发者确认需求理解无误

### Step 2: 技术方案设计
**输入**：确认后的需求理解
**操作**：
1. 分析现有系统架构（哪些服务受影响）
2. 设计数据模型变更（如有）
3. 设计 API 接口（Proto 定义）
4. 设计核心流程（流程图/时序图）
5. 识别风险点和依赖

**输出**：技术方案文档
```markdown
## 技术方案
### 影响范围
- 服务：[受影响的服务列表]
- 数据库：[表变更]
- API：[新增/修改的 API]

### 数据模型
[ER 图或表结构]

### API 设计
[Proto 定义]

### 核心流程
[流程描述/时序图]

### 风险与依赖
- [风险1]
- [依赖1]
```

**检查点**：开发者 Review 技术方案

### Step 3: 任务拆解
**输入**：技术方案
**操作**：
1. 将方案拆解为独立的、可测试的子任务
2. 每个子任务不超过 4 小时
3. 确定任务之间的依赖关系
4. 为每个任务定义验收标准

**输出**：任务清单
```markdown
## 任务清单
| # | 任务 | 预估时间 | 依赖 | 验收标准 |
|---|------|---------|------|---------|
| 1 | [任务描述] | [时间] | 无 | [标准] |
| 2 | [任务描述] | [时间] | T1 | [标准] |
```

**检查点**：任务拆解是否合理、粒度是否合适

### Step 4: 测试计划
**输入**：任务清单
**操作**：
1. 为每个任务设计测试用例
2. 覆盖正常路径、错误路径、边界条件
3. 明确单测和集成测试的范围

**输出**：测试计划
```markdown
## 测试计划
### 任务 1: [任务名]
- [ ] 单测：[测试描述]
- [ ] 单测：[错误路径测试]
- [ ] 集成测试：[测试描述]
```

## 产出物
完整的需求分析文档，包含：需求理解 → 技术方案 → 任务清单 → 测试计划

## 注意事项
- 方案设计阶段必须考虑对现有系统的影响
- 任务粒度以"可独立测试、可独立 Review"为标准
- 不确定的地方标记为待确认，不要自行假设
```

#### Skill 2：TDD 工作流 (`tdd-workflow.skill`)

```markdown
---
description: 测试驱动开发工作流，先写测试再写实现
---

# TDD 工作流

## 触发条件
当开发者需要实现一个功能并希望遵循 TDD 方式时使用。

## 步骤

### Step 1: 分析接口契约
**操作**：
1. 根据任务描述，确定要实现的函数/方法签名
2. 定义输入输出类型
3. 确定需要的接口（用于 Mock）

**输出**：接口定义代码

### Step 2: 编写测试（Red）
**操作**：
1. 编写 Table-driven 测试
2. 覆盖场景：
   - Happy path（正常流程）
   - Error path（各种错误场景）
   - Edge cases（边界条件：空值、零值、超大值）
3. 编写 Mock 实现
4. 运行测试确认全部失败（Red）

**检查点**：`go test` 运行，所有测试用例失败（预期的）

### Step 3: 最小实现（Green）
**操作**：
1. 编写最小代码使测试通过
2. 不追求完美，只追求通过测试
3. 运行测试确认全部通过（Green）

**检查点**：`go test -race` 全部通过

### Step 4: 重构（Refactor）
**操作**：
1. 在测试保护下重构代码
2. 应用编码规范（参照 go-code-style.rule）
3. 消除重复、改善命名、简化逻辑
4. 运行测试确认仍然全部通过

**检查点**：`go test -race` + `golangci-lint` 全部通过

### Step 5: 覆盖率检查
**操作**：
1. 运行 `go test -coverprofile=coverage.out`
2. 检查核心逻辑覆盖率 ≥ 80%
3. 如不足，补充测试用例

## 注意事项
- 每次只关注一个测试用例：写一个用例 → 让它通过 → 再写下一个
- 重构阶段不修改测试（除非测试本身有问题）
- 复杂函数先写核心 happy path 的测试，再逐步补充边界
```

#### Skill 3：Code Review (`code-review.skill`)

```markdown
---
description: AI 辅助代码审查，覆盖规范、安全、性能、可维护性
---

# AI 辅助 Code Review

## 触发条件
当开发者完成编码，需要进行代码审查时使用。

## 步骤

### Step 1: 变更概览
**操作**：
1. 分析变更文件列表和变更量
2. 理解变更的业务目的
3. 生成变更摘要

### Step 2: 规范检查
**操作**：逐项检查以下规范
- [ ] 命名规范（参照 go-code-style.rule）
- [ ] 错误处理（不忽略 error，正确包装）
- [ ] 注释完整性（导出符号有 godoc 注释）
- [ ] 函数长度（不超过 50 行）
- [ ] 嵌套深度（不超过 3 层）
- [ ] 导入分组（标准库/三方/项目）

### Step 3: 安全检查
- [ ] SQL 注入风险
- [ ] 未校验的用户输入
- [ ] 硬编码的敏感信息（密钥、密码）
- [ ] 不安全的并发操作

### Step 4: 性能检查
- [ ] 循环中的不必要分配
- [ ] 缺失的 context timeout
- [ ] 未使用 buffer 的 IO 操作
- [ ] 可以预分配的 slice/map

### Step 5: 可维护性检查
- [ ] 是否有重复代码可以提取
- [ ] 是否符合现有架构模式
- [ ] 新增依赖是否必要
- [ ] 是否有足够的测试覆盖

### Step 6: 生成 Review 报告
**输出格式**：

## Code Review 报告

### 变更摘要
[一句话概括变更内容]

### 🔴 必须修改 (Critical)
- [文件:行号] [问题描述] → [修改建议]

### 🟡 建议修改 (Suggestion)
- [文件:行号] [问题描述] → [修改建议]

### 🟢 值得肯定 (Good)
- [值得肯定的实践]

### 📊 统计
- 检查项：X 项
- Critical：X 项
- Suggestion：X 项
- 测试覆盖：X%
```

---

## 四、Commands 设计指南

### 4.1 Commands 设计原则

| 原则 | 说明 |
|------|------|
| **一键触发** | 命令名简短、好记 |
| **场景明确** | 每个命令对应一个具体场景 |
| **输出标准化** | 输出格式统一，方便后续处理 |

### 4.2 核心 Commands Demo

#### Command 1: `/check` — 代码质量一键检查

```markdown
---
description: 一键运行代码质量检查
---

请对当前项目执行以下检查，并汇总报告：

1. **格式检查**：运行 `gofmt -l .`，列出未格式化的文件
2. **静态分析**：运行 `go vet ./...`
3. **Lint 检查**：运行 `golangci-lint run ./...`
4. **测试**：运行 `go test -race -cover ./...`
5. **安全检查**：运行 `govulncheck ./...`

将结果整理为以下格式的报告：

## 代码质量报告
- ✅/❌ 格式检查：[结果]
- ✅/❌ 静态分析：[结果]
- ✅/❌ Lint 检查：[结果概要]
- ✅/❌ 测试：通过率 X%，覆盖率 X%
- ✅/❌ 安全检查：[结果]

如有失败项，列出具体问题和修复建议。
```

#### Command 2: `/gen-test` — 生成单元测试

```markdown
---
description: 为选中的函数生成 Table-driven 单元测试
---

请为当前选中的函数/文件生成单元测试，要求：

1. 使用 Table-driven tests 模式
2. 测试用例必须覆盖：
   - 正常路径（至少 2 个）
   - 错误路径（每种可能的错误至少 1 个）
   - 边界条件（空值、零值、极端值）
3. 外部依赖使用 Mock（基于接口）
4. 使用 testify/assert 和 testify/require
5. 遵循 go-test.rule 规范

生成测试文件后，运行 `go test -race -cover` 验证。
```

#### Command 3: `/gen-proto` — 生成规范的 Proto 文件

```markdown
---
description: 根据需求描述生成规范的 Proto 文件
---

请根据我的需求描述生成 Proto 文件，要求：

1. 遵循 proto-style.rule 规范
2. 包含完整的注释
3. 枚举零值使用 _UNSPECIFIED
4. Request/Response 成对出现
5. 列表接口包含分页字段
6. 使用 google/protobuf/timestamp.proto 表示时间
7. 生成后运行 `buf lint` 检查

输出包含：
- Proto 文件内容
- buf lint 检查结果
- 接口说明文档
```

#### Command 4: `/review` — 触发 Code Review

```markdown
---
description: 对当前变更执行 AI Code Review
---

请对当前 git 暂存区（staged）的变更执行 Code Review。

执行 `git diff --staged` 获取变更内容，然后按照 code-review.skill 的流程执行审查。

输出 Code Review 报告。
```

#### Command 5: `/design` — 技术方案设计

```markdown
---
description: 根据需求生成技术方案
---

请根据我描述的需求，按照 requirement-analysis.skill 的流程，输出完整的技术方案，包含：

1. 需求理解（一句话 + 关键实体 + 待确认事项）
2. 影响范围分析
3. 数据模型设计
4. API 设计（Proto 定义）
5. 核心流程（文字描述/伪代码）
6. 任务拆解（子任务 + 预估 + 验收标准）
7. 测试计划
8. 风险识别

请在输出后等待我确认，再进行下一步。
```

#### Command 6: `/explain` — 代码解释

```markdown
---
description: 解释选中的代码，帮助理解
---

请详细解释当前选中的代码：

1. **功能概述**：这段代码做了什么（一句话）
2. **详细解读**：
   - 逐段解释关键逻辑
   - 解释设计模式或惯用法（如果使用了的话）
   - 解释为什么这样写（设计意图）
3. **数据流**：输入 → 处理过程 → 输出
4. **注意事项**：
   - 潜在的坑
   - 性能特征
   - 错误处理逻辑
5. **改进建议**（如果有的话）

用初级工程师能理解的语言解释。
```

---

## 五、项目目录结构建议

```
project-root/
├── .cursor/
│   └── rules/
│       ├── go-code-style.mdc        # Go 编码规范
│       ├── go-test.mdc              # 测试规范
│       ├── go-error-handling.mdc    # 错误处理规范
│       ├── proto-style.mdc          # Proto 规范
│       ├── readability.mdc          # 可读性规范
│       ├── microservice-design.mdc  # 微服务设计（manual）
│       └── storage-design.mdc       # 存储设计（manual）
│
├── .cursor/
│   └── skills/
│       ├── requirement-analysis.md   # 需求分析
│       ├── tdd-workflow.md          # TDD 工作流
│       ├── code-review.md           # Code Review
│       └── arch-review.md           # 架构评审
│
├── .cursor/
│   └── commands/
│       ├── check.md                 # 代码质量检查
│       ├── gen-test.md              # 生成测试
│       ├── gen-proto.md             # 生成 Proto
│       ├── review.md                # Code Review
│       ├── design.md                # 技术方案
│       └── explain.md               # 代码解释
│
├── docs/
│   └── ai-rules/                    # 工具无关的通用规范（Markdown）
│       ├── go-code-style.md
│       ├── go-test.md
│       ├── proto-style.md
│       └── ...
│
└── ...
```

> **注意**：上述以 Cursor 为例，如果使用 CodeBuddy，将 `.cursor/` 替换为 `.codebuddy/`；使用 Copilot 则放在 `.github/copilot-instructions.md` 中。核心规范保持在 `docs/ai-rules/` 中，工具无关。

---

## 六、Rules/Skills/Commands 的迭代机制

### 6.1 贡献流程

```
团队成员发现问题 → 提出 Rule/Skill 改进建议
        │
        ▼
    提交 PR（修改 Rule/Skill 文件）
        │
        ▼
    Tech Lead Review
        │
        ▼
    合并 → 全团队自动生效
```

### 6.2 迭代节奏

| 频率 | 活动 |
|------|------|
| 每周 | 收集 AI 辅助编码中的问题案例 |
| 每两周 | Review 和更新 Rules，修复不合理的规则 |
| 每月 | 评审 Skills 和 Commands 的使用频率和效果 |
| 每季度 | 全面回顾，淘汰无效规则，新增必要规则 |

---

> 📌 **下一步**：请继续阅读 [04 - 需求到交付的完整 SOP](ai_best_practices_04_workflow_sop.md)，了解人机协作的标准流程。
