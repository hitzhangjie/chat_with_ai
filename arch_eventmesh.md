# Apache EventMesh

Apache EventMesh is a fully serverless platform used to build distributed
event-driven application.

ps: EventMesh应该主要是微众银行的小伙伴在推动吧。

see: 
- 项目介绍：https://eventmesh.apache.org/docs/introduction
- 特性及规划：https://eventmesh.apache.org/docs/roadmap
- 工作流编排：https://eventmesh.apache.org/docs/design-document/event-handling-and-integration/workflow
- 可观测性：https://eventmesh.apache.org/docs/design-document/observability/metrics-export
- connectors: https://eventmesh.apache.org/docs/design-document/connect/connectors
- schema registry: https://eventmesh.apache.org/docs/design-document/schema-registry
  ps: for example, protobuf schema.
- service provider interface, https://eventmesh.apache.org/docs/design-document/spi
  ps: you can build plugins around SPI.
- event streaing, https://eventmesh.apache.org/docs/design-document/stream


总结下，
- eventmesh其实是用来构建事件驱动的分布式系统的，events来源可以扩展，如MQ、WebHook、系统事件等等。
- 事件可以被存储到event store中，event store可以扩展，如MQ、Database、File等。
- 通信消息可以是单一事件，也可以是事件流（flow of events or event streaming）。
- 可以通过workflow DSL（domain specific language）对工作流进行编排，来对“长事务链条“的交互进行编排。
  ps：DSL编排时会指定事件类型、用来执行处理的函数，java可以通过反射拿到具体的类对象、对象方法以及参数信息。
- 参数通过一定的序列化格式进行序列化，这个在schema registry中进行注册，通过反射可以知道参数应该如何从序列化数据中反序列化，然后交给处理函数处理，
- 处理完后又生成事件，驱动下一个步骤进行处理。

可见，对于支付、电商类长链条事务场景，有追求事务一致性的，eventmesh非常适合这类的场景进行处理。
但是它不一定就适合其他业务场景，比如简单的2s内的RPC调用就可以搞定的事情，或者延时敏感的，用eventmesh就太重了。

认识到eventmesh的优缺点、使用场景，选择适合自己业务场景的解决方案，
比如大多数情况下都是全链路耗时极端的RPC同步调用，那为什么要引入eventmesh？这种就没必要嘛。
