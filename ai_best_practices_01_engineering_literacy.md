# 01 — 程序员自我修养：工程素养体系

> "即使走向 Vibe Coding，工程素养也绝不是可以放弃的东西。人必须给 AI 立规矩。"

## 一、为什么 AI 时代仍然需要工程素养

### 1.1 AI 不是银弹

- AI 生成代码的**正确性取决于约束的质量**。没有规范约束的 AI，就像没有建筑规范的包工队。
- AI 可以极快地写出"能跑的代码"，但**能跑 ≠ 能维护 ≠ 能演进**。
- 代码最终要被人（或辅助人的 AI）读懂、调试、重构——工程素养决定了这些操作的成本。

### 1.2 工程素养的新角色

```
传统模式：                        AI 时代：
工程素养 → 直接约束人写的代码      工程素养 → Rules/Skills → 约束 AI 写的代码
                                              ↓
                                  同时通过 AI 的执行过程教育人
```

**关键洞察**：工程素养从"直接约束人"变为"通过 AI 间接传递"。这意味着：
1. 资深工程师的经验必须**可编码化**（编写为 Rules/Skills）
2. AI 成为**规范的执行者和传播者**
3. 初级工程师在使用 AI 的过程中**潜移默化地学习规范**

---

## 二、Go 语言工程素养完整清单

### 2.1 编码规范层

#### 2.1.1 Go 编码风格

| 类别 | 规范要点 | 参考标准 | AI Rule 映射 |
|------|---------|---------|-------------|
| **命名** | 驼峰命名、包名小写单词、接口 `-er` 后缀 | Effective Go / Google Go Style Guide | `go-naming.rule` |
| **包结构** | 按职责划分、避免循环依赖、internal 包保护 | Go Project Layout | `go-package.rule` |
| **错误处理** | `errors.New` / `fmt.Errorf` with `%w`、不忽略 error | Go Blog: Error Handling | `go-error-handling.rule` |
| **注释** | 包注释、导出符号注释、godoc 格式 | Effective Go | `go-comments.rule` |
| **格式化** | `gofmt` / `goimports` 强制格式化 | 官方标准 | IDE 自动配置 |

#### 2.1.2 Go 惯用模式（Idiomatic Go）

```go
// ✅ 好的实践：Table-driven tests
func TestAdd(t *testing.T) {
    tests := []struct {
        name     string
        a, b     int
        expected int
    }{
        {"positive", 1, 2, 3},
        {"negative", -1, -2, -3},
        {"zero", 0, 0, 0},
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            if got := Add(tt.a, tt.b); got != tt.expected {
                t.Errorf("Add(%d, %d) = %d, want %d", tt.a, tt.b, got, tt.expected)
            }
        })
    }
}

// ✅ 好的实践：Functional options pattern
type ServerOption func(*Server)

func WithPort(port int) ServerOption {
    return func(s *Server) { s.port = port }
}

func NewServer(opts ...ServerOption) *Server {
    s := &Server{port: 8080} // 默认值
    for _, opt := range opts {
        opt(s)
    }
    return s
}

// ✅ 好的实践：Context propagation
func (s *Service) GetUser(ctx context.Context, id string) (*User, error) {
    ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
    defer cancel()
    return s.repo.FindByID(ctx, id)
}
```

### 2.2 工具链层

| 工具 | 用途 | 使用时机 | 集成方式 |
|------|------|---------|---------|
| `go vet` | 静态分析，发现常见错误 | 每次提交前 | CI + pre-commit hook |
| `golangci-lint` | 聚合 lint 工具 | 每次提交前 | CI + IDE 实时检查 |
| `go vulncheck` | 依赖安全漏洞检查 | 每周 / 每次依赖变更 | CI 定时任务 |
| `go build -race` | 编译时启用竞态检测 | 开发 / CI 环境 | CI Pipeline |
| `go test -race` | 测试时竞态检测 | 每次测试 | CI Pipeline |
| `go test -fuzz` | 模糊测试，发现边界 case | 核心逻辑 | 专项测试任务 |
| `go test -bench` | 性能基准测试 | 性能敏感代码变更 | PR 关联 |
| `go test -cover` | 测试覆盖率 | 每次提交 | CI + 覆盖率报告 |
| `mockgen` / `gomock` | Mock 测试 | 依赖外部服务的单测 | 开发时按需 |
| `buf` / `protocheck` | PB 规范检查 | PB 文件变更时 | CI + pre-commit |

#### 工具链一键集成脚本（示例）

```bash
#!/bin/bash
# check.sh - 本地开发一键检查

set -e

echo "🔍 Running gofmt check..."
if [ -n "$(gofmt -l .)" ]; then
    echo "❌ gofmt issues found:"
    gofmt -d .
    exit 1
fi

echo "🔍 Running go vet..."
go vet ./...

echo "🔍 Running golangci-lint..."
golangci-lint run ./...

echo "🔍 Running go vulncheck..."
govulncheck ./...

echo "🧪 Running tests with race detection..."
go test -race -cover ./...

echo "✅ All checks passed!"
```

### 2.3 测试素养层

#### 2.3.1 测试金字塔

```
                    ┌─────┐
                    │ E2E │  少量，验证关键路径
                   ─┤     ├─
                  / └─────┘ \
                 /   集成测试  \    适量，验证组件交互
                / ┌───────────┐ \
               /  │Integration│  \
              / ──┤           ├── \
             /    └───────────┘    \
            /       单元测试        \    大量，快速反馈
           / ┌─────────────────────┐ \
          /  │     Unit Tests      │  \
         /   │  (Table-driven,     │   \
        /    │   Mock, Fuzz,       │    \
       /     │   Benchmark)        │     \
      /      └─────────────────────┘      \
     └────────────────────────────────────┘
```

#### 2.3.2 测试最佳实践

| 实践 | 描述 | 优先级 |
|------|------|-------|
| **Table-driven tests** | 一个 test 函数覆盖多个场景 | P0 - 必须 |
| **Test isolation** | 每个测试独立，不依赖执行顺序 | P0 - 必须 |
| **Mock external deps** | 外部依赖（DB、HTTP、MQ）必须 Mock | P0 - 必须 |
| **测试命名** | `Test_功能_场景_预期结果` | P1 - 推荐 |
| **Error path testing** | 不只测 happy path，测错误路径 | P0 - 必须 |
| **Race detection** | CI 必须开启 `-race` | P0 - 必须 |
| **Fuzz testing** | 核心序列化/解析逻辑 | P1 - 推荐 |
| **Benchmark** | 性能敏感路径 | P2 - 按需 |
| **测试覆盖率** | 核心逻辑 ≥ 80%，工具代码 ≥ 60% | P0 - 必须 |

#### 2.3.3 可测试性设计

```go
// ❌ 不可测试：直接依赖全局变量和具体实现
func GetUserInfo(userID string) (*User, error) {
    db := globalDB  // 全局依赖
    return db.Query("SELECT * FROM users WHERE id = ?", userID)
}

// ✅ 可测试：依赖注入 + 接口抽象
type UserRepository interface {
    FindByID(ctx context.Context, id string) (*User, error)
}

type UserService struct {
    repo UserRepository
}

func NewUserService(repo UserRepository) *UserService {
    return &UserService{repo: repo}
}

func (s *UserService) GetUserInfo(ctx context.Context, userID string) (*User, error) {
    return s.repo.FindByID(ctx, userID)
}

// 测试时注入 Mock
type mockUserRepo struct {
    users map[string]*User
}

func (m *mockUserRepo) FindByID(ctx context.Context, id string) (*User, error) {
    if u, ok := m.users[id]; ok {
        return u, nil
    }
    return nil, ErrNotFound
}
```

### 2.4 API 与协议规范层

#### 2.4.1 Protobuf 规范

| 规则 | 说明 | 检查方式 |
|------|------|---------|
| **文件命名** | `snake_case.proto` | buf lint |
| **包名** | `company.project.service.version` | buf lint |
| **消息命名** | PascalCase | buf lint |
| **字段命名** | snake_case | buf lint |
| **枚举** | UPPER_SNAKE_CASE，零值带 `_UNSPECIFIED` | buf lint |
| **版本管理** | 不删字段，只废弃（`reserved`/`deprecated`） | Code Review |
| **注释** | 每个 message 和 field 必须有注释 | buf lint + 自定义 |
| **字段编号** | 不复用已删除的字段编号 | buf breaking |

```protobuf
// ✅ 规范的 Proto 文件示例
syntax = "proto3";

package company.game.user.v1;

option go_package = "github.com/company/game/api/user/v1;userv1";

// User 用户信息
message User {
  // 用户唯一标识
  string id = 1;
  // 用户昵称
  string nickname = 2;
  // 用户等级
  int32 level = 3;
  // 创建时间
  google.protobuf.Timestamp created_at = 4;
  // 用户状态
  UserStatus status = 5;
}

// UserStatus 用户状态枚举
enum UserStatus {
  // 未指定
  USER_STATUS_UNSPECIFIED = 0;
  // 正常
  USER_STATUS_ACTIVE = 1;
  // 封禁
  USER_STATUS_BANNED = 2;
}

// GetUserRequest 获取用户请求
message GetUserRequest {
  // 用户ID
  string id = 1;
}

// GetUserResponse 获取用户响应
message GetUserResponse {
  // 用户信息
  User user = 1;
}
```

#### 2.4.2 Google API 设计指南要点

| 原则 | 说明 |
|------|------|
| **面向资源** | API 围绕资源（名词）设计，不围绕操作（动词） |
| **标准方法** | List, Get, Create, Update, Delete |
| **自定义方法** | `resource:verb` 格式，如 `messages:batchGet` |
| **分页** | `page_size` + `page_token` |
| **过滤** | `filter` 字段，遵循 AIP-160 |
| **Field Mask** | 更新操作使用 `update_mask` 精确控制更新字段 |
| **Long Running** | 长时间操作返回 Operation 资源 |
| **错误模型** | 统一错误码，使用 `google.rpc.Status` |

### 2.5 设计与架构层

#### 2.5.1 设计模式精选（Go 场景高频使用）

| 模式 | Go 场景 | 核心价值 |
|------|---------|---------|
| **Functional Options** | Server/Client 配置 | 灵活配置，向后兼容 |
| **Strategy** | 多种算法/策略切换 | 运行时切换，符合开闭原则 |
| **Observer/EventBus** | 事件驱动、解耦 | 降低组件耦合 |
| **Circuit Breaker** | 微服务调用保护 | 级联故障防护 |
| **Decorator/Middleware** | HTTP/gRPC 中间件 | AOP，横切关注点分离 |
| **Repository** | 数据访问抽象 | 可测试性，存储可替换 |
| **Factory** | 对象创建 | 封装复杂创建逻辑 |
| **Builder** | 复杂对象构建 | 链式调用，可读性好 |

#### 2.5.2 微服务架构设计原则

```
┌──────────────────────────────────────────────────────────────┐
│                     微服务设计检查清单                          │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ☐ 单一职责：一个服务只做一件事，做好一件事                      │
│  ☐ 边界清晰：服务边界对齐业务领域（DDD Bounded Context）        │
│  ☐ 数据自治：每个服务拥有自己的数据，不直连他人的 DB             │
│  ☐ 接口契约：通过 API（Proto）通信，不共享内部模型               │
│  ☐ 异步优先：非实时依赖走消息队列，降低耦合                      │
│  ☐ 最终一致：分布式事务用 Saga/补偿，不追求强一致                │
│  ☐ 防腐层：对外部系统封装适配层，隔离变化                        │
│  ☐ 避免蜘蛛网：服务间调用不超过 3 层，引入 API Gateway 收束      │
│  ☐ 可观测性：Logging + Metrics + Tracing 三件套                │
│  ☐ 优雅降级：核心链路有兜底方案                                 │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

#### 2.5.3 存储设计原则

| 原则 | 说明 | 常见反模式 |
|------|------|-----------|
| **选型匹配** | OLTP → MySQL/PostgreSQL，OLAP → ClickHouse，缓存 → Redis | 一个 MySQL 打天下 |
| **Schema 演进** | 使用 Migration 工具，版本化管理 | 手动改表 |
| **索引设计** | 基于查询模式设计索引，定期 review 慢查询 | 随手加索引 |
| **读写分离** | 高读场景主从分离 | 全走主库 |
| **分库分表** | 提前规划 Sharding 策略 | 单表撑到扛不住 |
| **缓存策略** | Cache-Aside / Read-Through / Write-Behind | 不考虑一致性 |

---

## 三、工程素养培训计划

### 3.1 分期培训课程设计

#### 第一期（Phase 1, Month 1-3）：基础功

| 周次 | 主题 | 形式 | 时长 | 配套产出 |
|------|------|------|------|---------|
| W1 | Go 编码规范概览 | 讲座 + 实操 | 2h | `go-code-style.rule` |
| W2 | 命名与包设计实战 | Code Lab | 1.5h | 团队命名规范文档 |
| W3 | Go 工具链全景 | Demo + 实操 | 2h | `check.sh` + CI 配置 |
| W4 | 错误处理深度解析 | 案例分析 | 1.5h | 错误处理规范文档 |
| W5 | 单元测试入门：Table-driven | Code Lab | 2h | `go-test.rule` |
| W6 | Mock 测试与可测试性设计 | 实战重构 | 2h | 重构案例集 |
| W7 | Race / Fuzz / Bench | Demo + 实操 | 1.5h | 工具使用指南 |
| W8 | Protobuf 规范与 Buf 工具 | 讲座 + 实操 | 2h | `proto-style.rule` |
| W9 | Google API 设计指南 | 案例分析 | 1.5h | API 设计规范文档 |
| W10 | 可读性与代码审查 | 互审实战 | 2h | Code Review Checklist |
| W11 | Code Review 人机协作 | 流程演练 | 1.5h | Review SOP |
| W12 | Phase 1 总结与考核 | 考核 + 回顾 | 2h | 考核报告 |

#### 第二期（Phase 2, Month 4-6）：进阶

| 周次 | 主题 | 形式 | 时长 |
|------|------|------|------|
| W13-14 | 设计模式在 Go 中的应用 | 案例 + Code Lab | 2 × 2h |
| W15-16 | 微服务架构设计原则 | 架构 Workshop | 2 × 2h |
| W17-18 | 存储设计与数据建模 | 实战设计 | 2 × 1.5h |
| W19-20 | 分布式系统一致性 | 理论 + 案例 | 2 × 2h |
| W21-22 | 性能优化与调优 | Profiling 实战 | 2 × 2h |
| W23-24 | Phase 2 总结、架构评审实战 | 评审 + 回顾 | 2 × 2h |

#### 第三期（Phase 3, Month 7-9）：高阶

| 周次 | 主题 | 形式 | 时长 |
|------|------|------|------|
| W25-28 | 团队成员主导的技术分享 | 轮值分享 | 4 × 1h |
| W29-32 | 真实项目架构评审 | 集体评审 | 4 × 2h |
| W33-36 | 工程文化建设 & 最佳实践沉淀 | Workshop | 4 × 1.5h |

### 3.2 培训效果验证

| 维度 | 验证方式 | 合格标准 |
|------|---------|---------|
| 知识掌握 | 在线测验（每期末） | 正确率 ≥ 80% |
| 实操能力 | Code Lab 作业提交 | 所有用例通过 + lint 0 error |
| 实际应用 | 日常代码 lint 问题趋势 | 月环比下降 20% |
| 认知转变 | 匿名问卷调查 | 满意度 ≥ 4/5 |

---

## 四、如何将工程素养编码为 AI 规则

> 详细的 Rules/Skills/Commands 设计见 [03 文档](ai_best_practices_03_rules_skills_commands.md)，这里给出映射关系。

### 4.1 素养 → Rule 映射总表

| 工程素养 | Rule 文件 | 类型 | 触发时机 |
|---------|----------|------|---------|
| Go 编码规范 | `go-code-style.rule` | always | 每次生成 Go 代码 |
| Go 错误处理 | `go-error-handling.rule` | always | 生成包含错误处理的代码 |
| 测试规范 | `go-test.rule` | always | 生成测试代码 |
| Proto 规范 | `proto-style.rule` | always | 生成/修改 Proto 文件 |
| API 设计 | `api-design.rule` | always | 设计新 API |
| 可读性 | `readability.rule` | always | 所有代码生成 |
| 微服务设计 | `microservice-design.rule` | manual | 架构设计讨论 |
| 存储设计 | `storage-design.rule` | manual | 存储方案设计 |

### 4.2 核心理念

```
工程素养清单          编码为 Rules/Skills        AI 执行 + 人审查
     │                     │                        │
     ▼                     ▼                        ▼
 资深工程师经验  →   可复用的 AI 规则   →   初级工程师在实践中学习
                         │
                         ▼
                  持续迭代（PDCA）
```

**最终目标**：让 AI 成为"永不疲倦的资深工程师"，在每一次代码生成中传递工程素养。

---

> 📌 **下一步**：请继续阅读 [02 - AI Coding 工具全景](ai_best_practices_02_ai_coding_landscape.md)，了解主流 AI IDE 的对比与选型。
