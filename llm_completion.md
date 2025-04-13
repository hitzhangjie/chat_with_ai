ollama命令行支持的subcmds：/home/zhangjie/ai/ollama/cmd/cmd.go
- 大多数subcmds都是作为client与ollama server进行通信，通过http与server通信；
- ollama serve就是运行ollama服务程序；

ollama作为server运行时支持的handlers：/home/zhangjie/ai/ollama/server/routes.go
- 基本上每个客户端特定类型的操作都对应着服务器这边的一个handler
- ollama作为server工作时还涉及到与ollama models registry通信、认证鉴权相关的操作

然后关于最关心的推理这个环节，对应的是：
- client.Chat(ctx, &api.ChatRequest{...}, ...)
- server.(*Server).ChatHandler(*gin.Context)
