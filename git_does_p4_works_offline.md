## 1. Perforce 与服务器的关系

Perforce **不是本地化的 VCS**。  
* 服务器（P4D）持有**所有文件的完整历史**、**提交列表**、**文件的最新版本号**（have list）、**变更列表编号**等元数据。  
* 客户端（p4）只在本地有 **工作区目录**（client root）和 **客户端规范**（client spec，存放在服务器上）。  
* 任何需要知道“某个文件当前在哪个版本”，或者 “我想把改动提交给谁”，或者 “我想把最新版本同步到本地” 的操作，都必须与服务器通讯。

简言之：**没有服务器，Perforce 的核心功能几乎全失**。

---

## 2. 连不上服务器时的具体表现

下面列出常见 `p4` 命令的运行结果（以 `-s`（服务器不可达）为前提）：

| 命令 | 作用 | 结果 | 典型错误信息 |
|------|------|------|--------------|
| `p4 sync` | 同步文件到本地 | **失败** | `p4: Can't find server, please run 'p4 set P4PORT=...'` 或 `p4: Unable to connect to server` |
| `p4 edit`, `p4 add`, `p4 delete` | 申请改动（打开文件） | **失败** | `p4: Unable to connect to server` / `p4: Can't open file for edit, 
no connection` |
| `p4 submit` | 提交已打开文件 | **失败** | `p4: Unable to connect to server` / `p4: Can't submit, no connection` |
| `p4 opened` | 列出当前打开的文件 | **失败** | `p4: Unable to connect to server` |
| `p4 resolve` | 解决冲突 | **失败** | 同上 |
| `p4 diff` | 对比工作区文件 | **失败** | `p4: Unable to connect to server` |
| `p4 changes`, `p4 changelist -o`, `p4 filelog` 等 | 查询历史 | **失败** | 同上 |
| `p4 info` | 显示客户端/服务器信息 | **失败**（可能仅显示客户端信息，但缺失服务器信息） | `p4: Unable to connect to server` |
| `p4 client -o` / `-d` / `-t` | 查看/修改客户端规范 | **失败** | `p4: Unable to connect to server` |

> 这些错误信息在 Windows / Mac / Linux 终端上都大同小异，核心是 “Unable to connect to server” / “Can't find server”。

### 只剩下的可用操作

| 可能可用 | 说明 |
|----------|------|
| **手工编辑本地文件** | `p4` 本身无法检查或提交，只是普通文件操作。 |
| **使用 `p4 -c`（离线模式）** | 并不存在真正的“离线模式”。`p4` 没有类似 Git 的本地仓库；所有提交、同步、查询都必须访问服务器。 |
| **查看 `p4 where`** | 有时能显示文件路径映射（client->depot），但不涉及服务器元数据，仍需连接来确认有效性。 |

> **结论：** 除了纯粹的本地文件操作外，**所有与 Perforce 交互的命令都会报错**。也就是说，Perforce 在无法连接服务器时 **基本无法工作**。

---

## 3. 为什么会出现“连不上”？

| 可能原因 | 排查方法 | 典型表现 |
|----------|----------|----------|
| 服务器 IP/端口不正确 | `p4 set P4PORT` 或 `p4 info` | `Unable to connect to server` |
| 网络防火墙/路由 | `telnet <server> <port>` | 连接超时或重置 |
| 服务器挂掉 / 过载 | `p4 -d` (离线模式) | `Connection timed out` |
| 认证失败 | `p4 login` | `Invalid password` 或 `Authentication failed` |

---

## 4. 如何在服务器不可用时“工作”？

虽然 Perforce 不是离线工具，但你可以采取以下折中方案：

1. **使用 **`p4 -Ztag`** 记录本地变更**  
   先把所有想提交的文件手动记录下来（例如写成一个变更列表），等服务器恢复后再手工执行 `p4 edit` + `p4 submit`。  
   这并不理想，但在无法访问服务器的临时停机期间是可行的。

2. **部署** **备份服务器** 或 **本地代理**  
   在关键项目中，可以部署一个 **镜像服务器**（如 `p4d` 的备份实例），以防主服务器不可达时切换。  

3. **使用** **Perforce 的 **`p4v` 或 `p4` 的** **`-s`** (sync‑to‑specific‑revision)**  
   但这仍需要服务器连接，只是减少不必要的网络往返。

4. **把工作区切换为** **`p4 set P4CLIENT=offline`**  
   这只是一种标识方式，`p4` 仍会尝试连接。  

> 也就是说 **真正的离线工作** 只能用 **普通文件编辑** 来完成；等服务器恢复后再手工 `p4 sync/submit`。

---

## 5. 小结

* **Perforce 需要服务器**：所有增删改查、同步、提交、变更列表等操作都必须访问服务器。  
* **无法连上服务器时**：几乎所有 `p4` 命令都会报错；只能做普通文件操作。  
* **表现**：错误信息大多为 `Unable to connect to server` 或类似。  
* **应对**：在服务器不可用时只能靠手工编辑文件、记录变更或部署备用服务器；一旦服务器恢复，恢复正常 `p4` 流程即可。

如果你需要真正的离线版本控制体验，建议考虑 **Git** 或 **Mercurial** 之类的分布式 VCS；但如果你已经在使用 Perforce，那么保持服务器可用并定期
备份是最稳妥的做法
