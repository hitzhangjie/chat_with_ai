我来分析一下这两个 `Server` 结构体的不同之处。

这两个 `Server` 结构体分别定义在不同的包中，它们的功能和职责完全不同：

1. `server/routes.go` 中的 `Server` 结构体：
```go
type Server struct {
    addr  net.Addr
    sched *Scheduler
}
```
这个 `Server` 结构体是 Ollama 的主服务器结构，主要负责：
- 处理 HTTP 路由和 API 请求
- 管理模型调度器（Scheduler）
- 提供 REST API 接口，如 `/api/generate`、`/api/chat` 等
- 处理模型的生命周期管理（加载、卸载等）

2. `runner/llamarunner/runner.go` 中的 `Server` 结构体：
```go
type Server struct {
    ready sync.WaitGroup
    model *llama.Model
    image *ImageContext
    status llm.ServerStatus
    progress float32
    parallel int
    batchSize int
    mu sync.Mutex
    cond *sync.Cond
    lc *llama.Context
    seqs []*Sequence
    seqsSem *semaphore.Weighted
    cache *InputCache
    nextSeq int
}
```
这个 `Server` 结构体是 LLM 运行时的核心实现，主要负责：
- 直接管理和运行 LLM 模型
- 处理模型的推理请求
- 管理模型的上下文和缓存
- 处理批处理和序列化
- 管理多线程和并发请求

主要区别：
1. **职责不同**：
   - 第一个是 API 服务器，处理 HTTP 请求和路由
   - 第二个是 LLM 运行时，处理实际的模型推理

2. **抽象层次不同**：
   - 第一个是高层抽象，处理 HTTP 和 API 层面的逻辑
   - 第二个是底层实现，直接与 LLM 模型交互

3. **依赖关系**：
   - 第一个 `Server` 通过 `sched` 字段间接使用第二个 `Server` 的功能
   - 它们共同工作，但处于不同的抽象层次

这种设计体现了关注点分离的原则，将 API 服务和模型运行时分开，使得系统更容易维护和扩展。

