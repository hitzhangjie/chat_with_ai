如果你想调试go编译工具链本身，抱歉，默认go正式版发布时，这类分支构建版本构建go/src/cmd/...时不会生成DWARF调试信息。
如果也让这些go toolchain也生成DWARF调试信息，方便做相关研究时能通过调试器跟踪呢？

---

## 关键代码位置

**1. 版本检查和 isRelease 设置**（第 272-273 行）：
```272:273:src/cmd/dist/build.go
	goversion := findgoversion()
	isRelease = strings.HasPrefix(goversion, "release.") || strings.HasPrefix(goversion, "go")
```

**2. DWARF 调试信息禁用逻辑**（第 1346-1352 行）：
```1346:1352:src/cmd/dist/build.go
	if isRelease || os.Getenv("GO_BUILDER_NAME") != "" {
		// Add -trimpath for reproducible builds of releases.
		// Include builders so that -trimpath is well-tested ahead of releases.
		// Do not include local development, so that people working in the
		// main branch for day-to-day work on the Go toolchain itself can
		// still have full paths for stack traces for compiler crashes and the like.
		env = append(env, "GOFLAGS=-trimpath -ldflags=-w -gcflags=cmd/...=-dwarf=false")
	}
```

## 工作原理

1. `findgoversion()` 读取 `VERSION` 文件的第一行作为版本字符串。
2. 如果版本字符串以 `"release."` 或 `"go"` 开头，`isRelease` 被设为 `true`。
3. 当 `isRelease` 为 `true` 时，会添加 `-dwarf=false`，从而禁用 DWARF 调试信息。

## 绕过方法

在 `VERSION` 文件的第一行前加前缀（如 `"notes/"` 或 `"tests/"`），例如：
- `"notes/go1.23.5"` → 不以 `"release."` 或 `"go"` 开头 → `isRelease = false` → 会生成 DWARF 调试信息
- `"go1.23.5"` → 以 `"go"` 开头 → `isRelease = true` → 不会生成 DWARF 调试信息

当前 `VERSION` 文件内容是 `"notes/go1.23.5"`，因此会生成 DWARF 调试信息。
