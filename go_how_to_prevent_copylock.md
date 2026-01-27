# Go 里为什么要加 `noCopy` ？——防止 Mutex 复制的细节

在 Go 里，最常见的做法是给包含 `sync.Mutex` 或 `sync.RWMutex` 的结构体嵌入一个零字段：

```go
type myType struct {
    mu sync.Mutex
    // ...
    noCopy // ← 这行
}
```

## `noCopy` 是干什么的？

`noCopy` 只是一种 **静态检查的提示**，它不会在运行时产生任何锁或同步操作，也不会阻止真正的复制。  
它的实现（来自 `sync` 包）大致是：

```go
// noCopy may be embedded in a struct to indicate that the struct should not be copied.
// It is used by the static analysis tool `go vet` to find accidental copies of
// structures that contain a sync.Mutex or sync.RWMutex.
type noCopy struct{}

func (*noCopy) Lock()   {}
func (*noCopy) Unlock() {}
```

- **为什么有 `Lock()` / `Unlock()`？**  
  这两个空方法让 `noCopy` 满足 `sync.Locker` 接口。`go vet` 在检测结构体复制时会看是否包含实现了 `Lock/Unlock` 的字段；若是，就会把该字段标记为 **“不能复制
”**。

- **`go vet` 做了什么？**  
  当你把包含 `noCopy` 的结构体复制（比如 `x := y`、`&y`、`append` 等）时，`go vet` 会在编译阶段给出警告：

  ```
  vet: copy of struct containing a sync.Mutex is unsafe
  ```

  这就是我们通常说的 “阻止 mutex 被 copy”。

## 关键点

| 事项 | 说明 |
|------|------|
| **是否真的阻止复制？** | 不会在编译器层面阻止，复制操作仍然可以成功；但 `go vet` 会检测并警告。 |
| **运行时开销？** | 没有。`noCopy` 的 `Lock/Unlock` 是空函数，编译器会把它们优化掉。 |
| **使用方式** | 只需在结构体里 `embed` 这个字段即可。 |
| **适用范围** | 主要用于包含 `sync.Mutex`、`sync.RWMutex`、`sync.Once` 等需要“不可复制”的字段。 |
| **为什么需要？** | 在多 goroutine 环境下，错误地复制一个包含锁的结构体会导致锁失效、竞态条件或死锁。`noCopy` 通过静态分析帮你提前发现这类错误。 |

## 小结

`noCopy` 并不是一个真正的“复制防护”机制，而是一个**静态分析辅助工具**。  
- 你把它嵌入结构体 → `go vet` 看到这个字段 → 把结构体复制 → `go vet` 报警告。  
- 运行时不会产生任何额外负担。

因此，给包含 mutex 的类型加上 `noCopy` 主要是为了在开发阶段及时捕捉到“把锁结构复制了”的错误，提升代码安全性。
