# WSL2 + Docker Engine 网络不通？iptables 与 nftables 冲突排查指南

## 背景

在 Windows 11 的 WSL2 中部署 Docker 服务是很常见的开发场景。然而，不少人会遇到这样的情况：容器在 WSL2 内部可以正常访问，但在 Windows 宿主机上通过 `localhost` 却无法访问。本文记录了一次完整的排查过程，并提炼出通用的解决方案，适用于大多数在 WSL2 中使用 Docker Engine（非 Docker Desktop）的开发者。

---

## 问题现象

- `docker ps -a` 显示容器端口映射正常，例如 `0.0.0.0:3000->3000/tcp`
- 在 WSL2 内部 `curl http://localhost:3000` 可以正常访问
- 在 Windows 宿主机浏览器中访问 `http://localhost:3000` **无响应**
- 已在 `.wslconfig` 中配置了 `networkingMode=mirrored`，问题依然存在

---

## 排查思路

### 第一步：确认是 WSL2 网络问题还是 Docker 问题

在 WSL2 中直接启动一个非 Docker 的简单服务：

```bash
python3 -m http.server 8888
```

然后在 Windows 浏览器访问 `http://localhost:8888`。

- **如果能访问**：WSL2 的 mirrored 网络是正常的，问题出在 Docker 的网络层。
- **如果不能访问**：WSL2 本身的网络配置有问题，需要先排查 `.wslconfig`。

本文的场景是前者——WSL2 网络本身没问题，问题专属于 Docker。

### 第二步：检查 Docker 的 iptables 规则

Docker 依赖 iptables 做端口转发（NAT）。在 WSL2 中运行：

```bash
sudo iptables -t nat -L -n | grep 3000
```

如果看到如下报错：

```
iptables v1.8.5 (nf_tables): table `nat' is incompatible, use 'nft' tool.
```

**恭喜你，找到根本原因了。**

---

## 根本原因

新版 Ubuntu（包括部分 WSL2 发行版）默认使用 **nftables** 作为防火墙后端，而 Docker Engine 默认使用 **iptables-legacy** 来管理网络规则。两者底层实现不兼容，导致 Docker 写入的端口转发规则无法被系统识别和执行，最终表现为容器端口对外不可达。

这个问题在以下场景中特别容易出现：
- Windows 11 WSL2 + Ubuntu 22.04 及以上版本
- 使用 Docker Engine（非 Docker Desktop）
- 启用了 `networkingMode=mirrored`

---

## 解决方案

### 方案一：将 iptables 切换为 legacy 模式（推荐）

如果系统中安装了 `iptables-legacy`，可以通过 `update-alternatives` 切换：

```bash
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
```

切换后，重启 Docker 并重建容器（端口转发规则需要重新生成）：

```bash
sudo systemctl restart docker
docker compose down
docker compose up -d
```

**验证是否生效：**

```bash
sudo iptables -t nat -L -n | grep <端口号>
```

此时应能看到正常的 DNAT 规则，Windows 宿主机也可以通过 `localhost` 正常访问容器服务。

### 方案二：禁用 Docker 的 iptables 管理（备选）

如果系统中没有 `iptables-legacy`，可以让 Docker 完全不管理 iptables，由系统网络栈接管：

编辑（或创建）`/etc/docker/daemon.json`：

```json
{
  "iptables": false
}
```

然后重启 Docker 和容器：

```bash
sudo systemctl restart docker
docker compose down
docker compose up -d
```

> ⚠️ **注意**：关闭 iptables 管理会弱化容器间的网络隔离，适合本地开发环境，不建议用于生产或对安全性有要求的场景。

ps: 我的情况是，wsl发行版用的是rhel 8.5，官方软件源众没有找到iptables-legacy，简单期间就直接disable iptables了。

---

## 总结

| 现象 | 原因 | 解决方案 |
|------|------|----------|
| 容器内可访问，宿主机不行 | Docker iptables 规则未生效 | 排查 iptables/nftables 冲突 |
| `iptables` 报 nf_tables 不兼容 | 系统用 nftables，Docker 用 iptables-legacy | 切换 iptables 为 legacy 模式 |
| 系统无 iptables-legacy | 无法切换 | 在 daemon.json 中禁用 iptables |

**核心诊断命令：**

```bash
# 测试 WSL2 网络是否正常（非 Docker）
python3 -m http.server 8888

# 检测 iptables/nftables 冲突
sudo iptables -t nat -L -n
```

只要能区分"WSL2 网络问题"和"Docker 网络问题"，排查路径就会清晰很多。希望本文能帮你少走弯路。
