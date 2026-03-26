# 为什么 vscode-go 无法正确处理嵌套子测试

## 问题描述

Go 测试文件中，常用 `t.Run` 来组织子测试，比如：

```go
func TestXXX(t *testing.T) {
    t.Run("t1", func(t *testing.T) {
        t.Run("t2", func(t *testing.T) {
            // ...
        })
    })
}
```

vscode-go 的 CodeLens 功能（在测试函数上方显示"run test"按钮）会为每个 `t.Run` 生成对应的 `go test -run` 命令。但当嵌套超过 2 层时，生成的命令是错误的：

- **实际生成**：`go test -run=^TestXXX$/^t2$`
- **正确应为**：`go test -run=^TestXXX$/^t1$/^t2$`

中间的层级 `t1` 被漏掉了。这意味着开发者要么调整测试组织方式，要么手动输入 `-run` 参数。

---

## 问题定位

### 代码位置

Bug 在 `extension/src/goRunTestCodelens.ts` 第 112-153 行，核心代码如下：

```typescript
const simpleRunRegex = /t.Run\("([^"]+)",/;

for (let i = f.range.start.line; i < f.range.end.line; i++) {
    const line = document.lineAt(i);
    const simpleMatch = line.text.match(simpleRunRegex);

    // BUG: this does not handle nested subtests. This should
    // be solved once codelens is handled by gopls and not by
    // vscode.
    if (simpleMatch) {
        const subTestName = simpleMatch[1];
        codelens.push(
            new CodeLens(line.range, {
                title: 'run test',
                command: 'go.subtest.cursor',
                arguments: [{ functionName, subTestName }]
            }),
            // ...
        );
    }
}
```

代码里甚至有明确的 `BUG` 注释，承认这个问题。

### 根本原因

**当前实现是逐行正则匹配，没有层级概念。**

具体说：
1. 遍历测试函数体的每一行
2. 用正则 `/t.Run\("([^"]+)",/` 匹配 `t.Run("name",`
3. 找到后只记录 `name`，但不知道这一行处于哪个嵌套层级

因此 `t1` 和 `t2` 被平等对待，都只关联到顶层的 `TestXXX`，生成：
- `TestXXX/t1` → `-run=^TestXXX$/^t1$`（正确）
- `TestXXX/t2` → `-run=^TestXXX$/^t2$`（错误，漏掉了 t1）

---

## 为什么不从 gopls 获取嵌套结构？

一个自然的问题是：vscode-go 已经依赖 gopls 做 Go 代码分析，gopls 是否能提供 `t.Run` 的嵌套结构？

答案是**不能**，原因如下：

### gopls 的 DocumentSymbol 不包含 t.Run

vscode-go 通过 LSP（Language Server Protocol）向 gopls 请求 `DocumentSymbol`（文档符号）。这个接口返回：
- 顶层函数（`TestXXX`、`BenchmarkXXX` 等）
- 顶层方法（用于 testify 套件）

但 **LSP 标准** 中 DocumentSymbol 只描述代码中的"声明"（函数、变量、类型等），`t.Run(...)` 是一个函数调用，不是声明，所以 gopls 不会返回它。

相关代码在 `extension/src/goDocumentSymbols.ts`：

```typescript
const p = languageClient?.getFeature(DocumentSymbolRequest.method)?.getProvider(document);
const symbols = await p.provideDocumentSymbols(document, cancel.token);
// 只有顶层符号，没有 t.Run
```

`extension/src/testUtils.ts` 中 `getTestFunctions` 也确认了这一点，它只过滤顶层 Function 符号：

```typescript
const allTestFunctions = children.filter(
    (sym) =>
        sym.kind === vscode.SymbolKind.Function &&
        (testFuncRegex.test(sym.name) || fuzzFuncRegx.test(sym.name))
);
```

### Test Explorer 是怎么做到的？

vscode-go 的 Test Explorer（左侧测试树面板）**能正确展示嵌套子测试**，但它用的是完全不同的方式：**动态发现**。

Test Explorer 在执行测试后，解析 `go test -json` 的输出，从测试事件中动态创建子测试节点。相关代码在 `extension/src/goTest/resolve.ts`：

```typescript
// Create or Retrieve a sub test or benchmark. This is always dynamically
// called while processing test run output.
getOrCreateSubTest(parent: TestItem, label: string, name: string): TestItem | undefined {
    // 根据测试运行输出动态创建子测试节点
}
```

代码里甚至有一个 TODO 说明静态发现的问题：
> "TODO: If uri.query is test or benchmark, this is where we would discover sub tests or benchmarks, **if that is feasible**."

也就是说，静态发现 `t.Run` 的嵌套结构在当前架构下被认为是不可行的，所以 Test Explorer 选择了动态方案。

---

## 为什么 CodeLens 不能用动态方案？

Test Explorer 是"运行后显示"的，所以可以等测试执行完再建立嵌套结构。

但 CodeLens 是"显示在代码旁边的按钮"，需要在用户打开文件时立即生成，不能等到测试运行后才知道嵌套结构。所以 CodeLens 必须做**静态分析**。

---

## 修复思路

既然 gopls 不提供嵌套信息，只能在 vscode-go 层面做轻量的静态分析。

### 核心洞察

之所以现在能知道"t2 属于 TestXXX"，是因为：
1. 取到了 `TestXXX` 的行范围（通过 gopls symbols）
2. 在这个行范围内搜索 `t.Run`

用同样的逻辑：
- 如果知道 `t1` 对应的函数字面量（`func(t *testing.T) { ... }`）的行范围
- 那么在这个范围内找到的所有 `t.Run` 就是 `t1` 的子测试

问题转化为：**扫描函数体时，如何跟踪每个 `t.Run` 的闭包范围？**

### 实现方案：轻量括号追踪解析器

不需要完整的 Go AST 解析器，只需要一个轻量的字符扫描器：

1. **逐字符扫描**测试函数体
2. 跳过字符串和注释（避免误匹配）
3. 遇到 `t.Run("name",` 时，记录当前**嵌套深度**和**行号**
4. 记录每个 `t.Run` 调用的左花括号 `{` 和配对的右花括号 `}` 位置，确定子函数的作用域范围
5. 通过作用域包含关系，建立父子树：如果 t2 的行号在 t1 的作用域范围内，则 t2 是 t1 的子测试
6. 对每个 t.Run 节点，计算从根到该节点的完整路径（如 `["t1", "t2"]`）

### 生成正确的 -run 参数

现有的 `escapeSubTestName` 函数（`extension/src/subTestUtils.ts`）已经支持路径拼接：

```typescript
export function escapeSubTestName(testFuncName: string, subTestName: string): string {
    return `${testFuncName}/${subTestName}`
        .replace(/\s/g, '_')
        .split('/')
        .map((part) => escapeRegExp(part), '')
        .join('$/^');
}
```

只需将路径数组拼接为 `/` 分隔的字符串，再调用这个函数即可：

```typescript
// ["t1", "t2"] → "t1/t2" → escapeSubTestName(funcName, "t1/t2")
// 最终生成：^TestXXX$/^t1$/^t2$
const fullPath = subTestPath.join('/');
const escapedName = escapeSubTestName(functionName, fullPath);
```

### 需要修改的文件

| 文件 | 操作 | 说明 |
|------|------|------|
| `extension/src/subTestParser.ts` | 新建 | 实现括号追踪解析器，提供 `findNestedSubTests()` 函数 |
| `extension/src/goRunTestCodelens.ts` | 修改 | 替换第 112-153 行的简单正则循环，改用新解析器 |
| `extension/test/unit/subTestParser.test.ts` | 新建 | 解析器单元测试 |

`subTestUtils.ts` 无需改动，已有逻辑可以复用。

---

## 局限性

修复后仍有以下已知局限（与当前版本相同）：

1. **动态测试名称无法检测**：`t.Run(varName, ...)` 或 `t.Run(fmt.Sprintf(...), ...)` 无法静态分析
2. **注释中的 t.Run 需要小心**：解析器需要正确跳过注释

---

## 总结

| 问题 | 原因 |
|------|------|
| 嵌套子测试 CodeLens 生成错误 | 逐行正则匹配，无法感知嵌套层级 |
| gopls 无法提供帮助 | LSP DocumentSymbol 只描述声明，不包含函数调用 |
| Test Explorer 能正确处理 | 动态解析测试运行输出，非静态分析 |
| 修复方向 | 在 vscode-go 层实现轻量括号追踪解析器，建立 t.Run 调用树 |
| 修复复杂度 | 不高，不需要完整 AST，只需括号匹配+字符串/注释跳过 |
