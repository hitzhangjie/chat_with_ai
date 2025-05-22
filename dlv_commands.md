我来帮你查看 Delve (dlv) 支持的命令及其功能。让我先搜索相关文档。


Ran tool
根据搜索结果，我来总结一下 Delve (dlv) 支持的主要命令及其功能：

1. `dlv debug` - 编译并开始调试当前目录下的 main 包或指定的包
   - 默认会编译当前目录下的 main 包并开始调试
   - 可以指定包名来调试特定包

2. `dlv exec` - 执行预编译的二进制文件并开始调试会话
   - 用于调试已经编译好的程序
   - 建议使用 `-gcflags="all=-N -l"` 编译以获得更好的调试体验

3. `dlv attach` - 附加到正在运行的进程并开始调试
   - 可以附加到已经运行的进程进行调试
   - 支持等待特定进程启动（通过 `--waitfor` 参数）

4. `dlv test` - 编译测试二进制文件并开始调试
   - 用于调试单元测试
   - 可以通过 `--` 传递参数给测试程序

5. `dlv trace` - 编译并开始跟踪程序执行
   - 在匹配正则表达式的函数上设置跟踪点
   - 可以显示函数调用信息而不需要完整的调试会话

6. `dlv core` - 检查核心转储文件
   - 支持 Linux 和 Windows 的核心转储文件
   - 可以查看进程崩溃时的状态

7. `dlv connect` - 连接到--headless模式启动的调试服务器
   - 用于连接到已经运行的调试服务器
   - 支持 Unix domain socket

8. `dlv dap` - 启动 DAP 协议的调试服务器
   - 支持与 VS Code 等 IDE 集成
   - 提供多种调试模式（launch、attach 等）

9. `dlv replay` - 重放 rr 跟踪
   - 用于重放由 mozilla rr 生成的跟踪记录
   - 需要安装 mozilla rr

10. `dlv version` - 打印版本信息

通用选项：
- `--headless` - 以--headless模式运行调试服务器
- `--accept-multiclient` - 允许多个客户端连接
- `--log` - 启用调试服务器日志
- `--backend` - 选择后端（default/native/lldb/rr）
- `--build-flags` - 传递给编译器的构建标志
- `--check-go-version` - 检查 Go 版本兼容性

这些命令和选项使 Delve 成为一个功能强大的 Go 程序调试工具，可以满足各种调试场景的需求。

