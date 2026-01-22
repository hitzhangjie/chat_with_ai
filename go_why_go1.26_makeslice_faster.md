# Go 1.24 vs Go 1.26 切片分配性能对比

## 测试代码

```go
func allocate1() []byte {
    finalsize := 1024
    final := append([]byte(nil), make([]byte, finalsize)...)[:0]
    return final
}

func allocate2() []byte {
    finalsize := 1024
    final := make([]byte, 0, finalsize)
    return final
}
```

## Benchmark 结果

| Go 版本 | allocate1 | allocate2 | 更快的方式 |
|---------|-----------|-----------|------------|
| Go 1.24.1 | ~181 ns/op | ~196 ns/op | allocate1 快 ~8% |
| Go 1.26rc2 | ~237 ns/op | ~191 ns/op | allocate2 快 ~19% |

## 汇编分析

### Go 1.24

| 函数 | runtime 调用 | 清零方式 |
|------|--------------|----------|
| allocate1 | `growslice` | `duffzero`（高度优化的展开循环） |
| allocate2 | `makeslice` | makeslice 内部清零 |

### Go 1.26

| 函数 | runtime 调用 | 清零方式 |
|------|--------------|----------|
| allocate1 | `growslice` | 内联 MOVUPS 循环（16次×64字节） |
| allocate2 | `makeslice` | makeslice 内部清零（size-specialized 优化） |

## 原因分析

### 为什么 Go 1.24 中 allocate1 更快？

`allocate1` 使用了 `runtime.duffzero`，这是基于 Duff's device 技术的高度优化清零例程：
- 循环完全展开，消除分支预测开销
- 针对常见大小深度优化

而 `allocate2` 的 `makeslice` 内部清零逻辑优化程度较低。

### 为什么 Go 1.26 中 allocate2 更快？

1. **allocate1 变慢**：Go 1.26 将 `duffzero` 替换为内联 MOVUPS 循环，每次迭代有分支开销，效率下降

2. **allocate2 变快**：Go 1.26 引入了 **size-specialized malloc** 优化：
   - 编译器在编译时确定分配大小
   - 直接生成针对特定大小的分配调用
   - 跳过运行时 size class 计算
   - 对小于 512 字节的分配最高提升 30%

## 结论

- **Go 1.24**：`append` 方式因 `duffzero` 优化而略快
- **Go 1.26**：直接 `make` 方式因 size-specialized malloc 优化而更快
- **推荐**：使用 `make([]byte, 0, cap)` 方式，代码更简洁，且在新版本 Go 中性能更好
