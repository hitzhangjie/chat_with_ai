╭────────────────────────────────────────────────────────────────────────────────────╮
│  > 网络运营商有时候会进行网络割接，网络割接是什么意思？对应的英文专业术语是什么？  │
╰────────────────────────────────────────────────────────────────────────────────────╯

✦ “网络割接”是一个在电信和IT行业中非常常见的术语。

  **意思解释**

  “网络割接”指的是对正在运行的网络进行改造、升级、扩容或迁移时，需要将网络设备、线路或业务从旧的系统/设备/链路上“割断”，然后“接入”到新的系统/设备/链路上。

  这个过程通常是：
   1. **计划性操作**：它是一个预先规划好的维护活动，而不是突发故障。
   2. **中断或瞬断**：割接过程中，相关的网络服务可能会发生短暂的中断或不稳定。为了将影响降到最低，运营商通常会选择在业务量最少的时间段进行，比如凌晨。
   3. **目的**：常见目的包括设备更新换代、网络扩容、架构优化、业务迁移等。

  简单来说，就像给正在行驶的火车更换一段铁轨，需要先让火车停下（或慢行），快速换好铁轨，再让火车恢复正常行驶。

  **英文专业术语**

  “网络割接”最常用、最贴切的英文专业术语是 **Network Cutover**。

   * **Cutover**: 这个词精确地描述了从一个系统切换（cut）到另一个系统（over）的动作。

  在不同的上下文中，也可能会用到其他相关词汇：
   * **Network Migration**: 网络迁移。这个词更侧重于整个迁移过程，而 "Cutover" 特指切换发生的那个具体时间点或事件。
   * **System Upgrade**: 系统升级。这是割接的目的之一，但不是割接这个动作本身。
   * **Planned Network Maintenance**: 计划性网络维护。这是一个更宽泛的说法，网络割接是其中的一种。

  **总结一下：**

| 中文   | 英文 (最专业/常用) |
| :----- | :------------------- |
| 网络割接 | **Network Cutover**  |

╭──────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│  > 割接这个动作，具体是如何操作呢？比如说一个核心路由器进行网络割接，在割接前、中、后需要分别进行什么操作？  │
╰──────────────────────────────────────────────────────────────────────────────────────────────────────────────╯

✦ 好的，这是一个非常专业且重要的问题。对核心路由器（Core Router）进行网络割接是网络运维中风险最高、技术要求最严的操作之一，堪称“网络世界的心脏搭桥手术”。

  整个过程必须被精确地计划和执行。下面我将详细拆解割接前、中、后三个阶段的关键操作和注意事项。

  ---

  **核心理念**

   * **万无一失 (No Margin for Error)**: 核心路由器是网络骨干，任何长时间的中断都可能导致大面积的网络瘫痪。
   * **影响最小化 (Minimize Impact)**: 所有操作都旨在将业务中断时间缩短到秒级甚至毫秒级。
   * **随时回退 (Rollback Ready)**: 必须准备好在任何步骤出错时，都能在几分钟内恢复到割接前的状态。

  ---

  **阶段一：割接前 (Pre-Cutover Phase) - 准备与规划**

  这个阶段是整个割接工作的重中之重，花费的时间最长，准备工作越充分，割接过程就越顺利。

| 关键操作 | 详细说明 |
| :--- | :--- |
| **1. 制定方案 (MOP)** | 编写详尽的 **MOP (Method of Procedure)**，即标准操作流程文档。这不仅仅是步骤，而是精确到**每一条命令、每一个端口、每一个负责人、每一个时间点**的剧本。 |
| **2. 技术勘察** | - **物理层面**: 确认机房空间、电源、光纤类型和长度、端口型号是否匹配。<br>- **逻辑层面**: 梳理与该路由器相连的所有设备、承载的所有业务（如专线、互联网出口）、运行的路由协议（BGP, OSPF, IS-IS等）和策略。 |
| **3. 准备新设备/配置** | - **设备预上线**: 如果是更换硬件，新设备需要提前在实验室（Lab）环境中进行完整的配置和测试，模拟生产环境的流量和协议。<br>- **配置预生成**: 无论是升级软件还是更改配置，新的配置文件必须提前写好、审查（Peer Review），并进行语法检查。 |
| **4. 备份！备份！备份！** | - **备份配置**: 备份当前路由器的 `running-config`。 <br>- **备份许可证 (License)**: 如果有，必须备份。 |
| **5. 采集基线数据** | 在割接开始前，记录下网络“健康”时的状态，作为割接后对比的依据。<br>- **路由表**: `show ip route`, `show bgp summary`<br>- **接口状态/流量**: `show interfaces`, `show ip traffic`<br>- **设备性能**: CPU、内存使用率<br>- **业务延迟**: `ping`, `traceroute` 关键业务地址 |
| **6. 制定回退计划** | 这是MOP中最重要的部分。清晰地定义在哪个步骤出错时，应该执行哪些命令来撤销更改，恢复到割接前的状态。**回退方案必须和执行方案一样详细。** |
| **7. 沟通与通知** | - **确定割接窗口**: 通常选择业务量最低的凌晨（如周日 2:00 AM - 4:00 AM）。<br>- **通知相关方**: 提前通知所有可能受影响的部门、客户和网络监控中心（NOC），告知割接时间、目的和潜在风险。<br>- **组建团队**: 明确分工，谁是总指挥，谁负责执行命令，谁负责物理操作，谁负责验证，谁负责对外沟通。通常会建立一个专门的电话会议或即时通讯群组。 |

  ---

  **阶段二：割接中 (Cutover Phase) - 精确执行**

  这个阶段时间紧、压力大，严格遵守MOP是成功的唯一途径。

| 关键操作 | 详细说明 |
| :--- | :--- |
| **1. 开始前最终检查** | - 在割接窗口开始时，再次检查网络状态是否平稳，有无突发告警。<br>- 在团队频道中宣布：“割接正式开始”。 |
| **2. 流量切换（优雅地）** | 这是核心技术点。目标是让流量平滑地切换到备用路径或新设备上，而不是粗暴地中断。<br>- **利用路由协议**: 逐步调高当前路由器的路由cost/metric（如OSPF cost）或增加AS-PATH（BGP），让网络中的其他路由器“主动”避开这台设备，从而“排干”流量。<br>- **关闭BGP会话**: `shutdown` BGP邻居关系，让流量从其他出口走。 |
| **3. 执行核心变更** | 这是真正的“割接”动作。<br>- **软件升级**: 执行升级命令，重启设备。<br>- **硬件更换**: 确认流量为零后，`shutdown` 接口，拔下光纤，连接到新设备上，然后 `no shutdown` 新设备接口。<br>- **配置变更**: 粘贴或加载新的配置。 |
| **4. 流量恢复** | - 将之前调整的路由协议参数改回正常值，让流量“流回”到新的/升级后的设备上。 |
| **5. 立即验证 (Immediate Verification)** | 在执行完每一步关键操作后，都要进行快速验证。<br>- **物理/链路层**: 检查接口是否 `up/up`。`show interfaces`<br>- **网络层**: 检查路由协议邻居是否建立。`show ip ospf neighbor`, `show bgp summary`<br>- **路由表**: 检查路由条目是否按预期学习回来。<br>- **连通性**: `ping` |

  ---

  **阶段三：割接后 (Post-Cutover Phase) - 监控与确认**

  割接操作完成不代表工作结束，持续的监控和最终确认同样重要。

| 关键操作 | 详细说明 |
| :--- | :--- |
| **1. 深度监控** | - **对比基线**: 将当前设备的CPU、内存、流量、延迟等数据与割接前采集的基线数据进行对比，确认是否在正常范围内。<br>- **检查错误日志**: 持续观察设备日志，看是否有异常报错、接口CRC错误、 flapping（接口不稳定）等。<br>- **业务验证**: 联系业务部门或使用自动化探针，确认所有关键业务（如数据库连接、应用访问）是否正常。 |
| **2. 宣布割接成功** | 在监控期（通常为30分钟到2小时）内，如果一切平稳，总指挥可以在团队频道中宣布：“割接成功，进入监控期”。 |
| **3. 清理工作** | - **移除旧设备**: 在确认新设备稳定运行一段时间后（可能是几天后），再将旧设备下电、下架。<br>- **清理临时配置**: 移除割接过程中使用的临时路由策略等。 |
| **4. 更新文档** | - **更新网络拓扑图**。<br>- **更新设备信息库 (CMDB)**。<br>- **归档MOP和操作记录**。 |
| **5. 复盘总结** | - 召开复盘会议，总结本次割接的成功经验和不足之处，为未来的网络变更提供参考。 |

  通过这样一套严谨、系统化的流程，才能最大程度地保证核心网络割接的安全与成功。