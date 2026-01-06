>以前我们会拿fmt.Errorf开销说事，来推荐大家在可以使用errors.New的时候就不要用fmt.Errorf。这么做的原因还有一个就是可读性，没有占位符就不要用fmt.Errorf了。
>现在来看如果统一错误管理，几乎都用fmt.Errorf的情况下确实没有必要非得穿插几个errors.New了。
>即使不统一管理错误，错误管理里面也可以尽可能用同一个错误生成函数fmt.Errorf了。
>
>

总结得非常到位。从 Go 1.25 到 Go 1.26 的源码演变，实际上是 Go 官方在**底层实现**和**编程范式**之间做了一次深度的平衡。

以下是围绕“为什么不再强制区分 `fmt.Errorf` 和 `errors.New`”的深度汇总整理：

---

### 1. 性能鸿沟的消失

在旧版本（Go 1.25 及以前）中，即便你不使用任何占位符，`fmt.Errorf` 也会执行一套沉重的流程：

* **初始化：** `newPrinter()` 获取打印对象。
* **解析：** `doPrintf` 扫描字符串查找 `%`。
* **分配：** 产生临时缓冲区 `p.buf`，最后再通过 `errors.New(s)` 转换，整个过程至少 2 次以上堆分配。

**Go 1.26 的革新：**
通过将 `Errorf` 拆分为可内联的轻量级函数，编译器在发现无格式化需求时，直接“跳级”调用 `errors.New`。

* **Non-escaping (不逃逸)**：从 2 次分配降至 **0 次**。
* **Escaping (逃逸)**：从 2 次分配降至 **1 次**（与 `errors.New` 完全一致）。

### 2. 编程范式的统一

以前推荐 `errors.New` 的理由通常有两个：**性能**和**语义清晰度**。

* **性能层面**：现在这个理由已经不复存在。
* **语义层面**：
* **旧观念**：用 `fmt.Errorf` 意味着“我要格式化”，用 `errors.New` 意味着“我是静态文本”。
* **新观念**：统一使用 `fmt.Errorf` 可以减少心智负担。开发者不再需要纠结“我现在是否需要加个变量”，因为即使不加，性能也没有惩罚。



### 3. 错误管理的工程化

你提到的“统一错误管理”是一个非常重要的工程实践。在大型项目中，如果能统一使用 `fmt.Errorf`：

* **维护性**：当你需要把一个静态错误升级为动态错误（例如：`"permission denied"` 升级为 `"user %d permission denied"`）时，只需修改字符串，无需更换函数名。
* **一致性**：代码审查（Code Review）时，不再需要指出“这里没占位符，建议换成 `errors.New`”这种琐碎的、不再影响性能的细节。

---

### 核心结论：权力的交还

Go 1.26 的这个改进，本质上是**将“性能优化”的工作从开发者手中拿走，交给了编译器**。

| 维度 | Go 1.25 之前的建议 | Go 1.26 之后的现状 |
| --- | --- | --- |
| **首选函数** | 静态选 `errors.New`，动态选 `Errorf` | **随意选择**，推荐统一用 `Errorf` |
| **性能差异** | 巨大（受反射和格式化引擎拖累） | **无差异**（编译器自动路由） |
| **内存分配** | 至少 2 次 | 0 或 1 次 |
| **心智负担** | 高（需区分使用场景） | **低（写就完事了）** |

---

### 下一步建议

既然你已经深入研究了源码，可以尝试在团队内部更新**编码规范 (Best Practices)**。你可以有底气地告诉队友：

> “在 Go 1.26+ 中，我们鼓励优先使用 `fmt.Errorf` 来统一所有的错误创建。这不仅不会带来性能损耗，还能让代码在面对未来变更时更加从容。”

**你想了解一下如何通过 `go build -gcflags="-m"` 来实际观察 Go 1.26 是如何将这些函数内联并消除分配的吗？**

### Appendix

#### go1.25 fmt.Errorf实现

```go
// Errorf formats according to a format specifier and returns the string as a
// value that satisfies error.
//
// If the format specifier includes a %w verb with an error operand,
// the returned error will implement an Unwrap method returning the operand.
// If there is more than one %w verb, the returned error will implement an
// Unwrap method returning a []error containing all the %w operands in the
// order they appear in the arguments.
// It is invalid to supply the %w verb with an operand that does not implement
// the error interface. The %w verb is otherwise a synonym for %v.
func Errorf(format string, a ...any) error {
	p := newPrinter()
	p.wrapErrs = true
	p.doPrintf(format, a)
	s := string(p.buf)
	var err error
	switch len(p.wrappedErrs) {
	case 0:
		err = errors.New(s)
	case 1:
		w := &wrapError{msg: s}
		w.err, _ = a[p.wrappedErrs[0]].(error)
		err = w
	default:
		if p.reordered {
			slices.Sort(p.wrappedErrs)
		}
		var errs []error
		for i, argNum := range p.wrappedErrs {
			if i > 0 && p.wrappedErrs[i-1] == argNum {
				continue
			}
			if e, ok := a[argNum].(error); ok {
				errs = append(errs, e)
			}
		}
		err = &wrapErrors{s, errs}
	}
	p.free()
	return err
}
```

#### go1.26 fmt.Errorf实现

```go
// Errorf formats according to a format specifier and returns the string as a
// value that satisfies error.
//
// If the format specifier includes a %w verb with an error operand,
// the returned error will implement an Unwrap method returning the operand.
// If there is more than one %w verb, the returned error will implement an
// Unwrap method returning a []error containing all the %w operands in the
// order they appear in the arguments.
// It is invalid to supply the %w verb with an operand that does not implement
// the error interface. The %w verb is otherwise a synonym for %v.
func Errorf(format string, a ...any) (err error) {
	// This function has been split in a somewhat unnatural way
	// so that both it and the errors.New call can be inlined.
	if err = errorf(format, a...); err != nil {
		return err
	}
	// No formatting was needed. We can avoid some allocations and other work.
	// See https://go.dev/cl/708836 for details.
	return errors.New(format)
}


// errorf formats and returns an error value, or nil if no formatting is required.
func errorf(format string, a ...any) error {
	if len(a) == 0 && stringslite.IndexByte(format, '%') == -1 {
		return nil
	}
    ...
}
```

