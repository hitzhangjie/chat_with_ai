# How Git LFS Works：从“模型文件不见了”到彻底搞懂机制

这篇文章基于一次真实排查：仓库里有大量 `*.glb` 资源，某台机器没装 Git LFS 时 `clone` 后发现模型目录几乎空；安装 Git LFS 后，文件又“自动回来了”。这背后正是 Git LFS 的核心设计。

---

## 1. 现象回放

在仓库中看到：

- `.gitattributes` 配置了 LFS 跟踪规则（例如 `demo/public/models/*.glb filter=lfs ...`）
- 但在未安装 Git LFS 的机器上，`clone` 后模型目录不完整/不可用
- 安装 Git LFS 后，模型文件恢复正常

这会让人产生一个关键问题：  
**Git 到底存了什么？LFS 又存了什么？**

---

## 2. 一句话结论

**Git 管“版本关系 + 指针文本”，Git LFS 管“大文件本体”。**

---

## 3. Git LFS 的存储设计

### Git 仓库（`.git/objects`）里有什么？

Git 本身仍然是三类对象：

- `commit`
- `tree`
- `blob`

当某个文件（如 `ship6.glb`）被 LFS 跟踪后，`blob` 里不再是二进制模型内容，而是一个很小的 **pointer 文件**（文本）。

典型 pointer 内容类似：

```text
version https://git-lfs.github.com/spec/v1
oid sha256:xxxxxxxx...
size 12345678
```

也就是说，Git 历史里记录的是“这个大文件的身份信息”，不是大文件本体。

---

### LFS 本地缓存（`.git/lfs/objects`）里有什么？

这里才是真正的大文件内容（按 `oid sha256` 组织）。  
LFS 会根据 pointer 里的 `oid` 去远端 LFS 存储下载本体，并落到本地 `.git/lfs/objects`。

---

### 工作区里看到的文件是什么？

取决于 LFS 过滤器是否生效：

- 生效且对象已拉取：工作区是**真实二进制文件**
- 未生效/未安装：常见是**pointer 文本文件**
- 特殊场景（稀疏检出、提交本身不含该路径等）：工作区可能**没有该文件**

---

## 4. 为什么“安装 LFS 后自动恢复”？

因为安装后，Git LFS 的 checkout/smudge 流程开始生效：

1. 读取 Git 里的 pointer
2. 按 `oid` 去拉 LFS 对象
3. 把工作区文件替换为真实内容

所以看起来像“自动下载回来了”。

---

## 5. 常见误区

- **误区 1：Git 自动管理大文件本体**  
  不是。Git 只存 pointer（在 LFS 跟踪前提下）。

- **误区 2：没装 LFS 就会看到 0 字节占位文件**  
  不一定。更常见是 pointer 文本，或者某些场景下直接缺文件。

- **误区 3：`models` 目录空就是 LFS 坏了**  
  先确认路径是否正确（例如资产实际在 `demo/public/models`，而不是仓库根 `models`）。

---

## 6. 一个实用心智模型

把 LFS 想成“Git 的大文件外置仓库”：

- Git 提供“目录索引和版本时间线”
- LFS 提供“对象仓库存储和按哈希取回”
- pointer 是两者之间的“凭证”

---

## 7. 排查清单（推荐收藏）

当你怀疑 LFS 异常时，按这个顺序看：

1. `.gitattributes` 是否有对应路径的 `filter=lfs`
2. `git ls-files "path/*.glb"` 是否有被跟踪文件
3. 是否启用了 sparse checkout（可能把路径排除）
4. 本机是否安装并初始化了 Git LFS
5. 工作区文件是 pointer 文本还是真实二进制

---

## 8. 总结

Git LFS 的关键不是“让 Git 变会存大文件”，而是“让 Git 只存可版本化的指针，把大文件交给专用对象存储”。  
理解了这点，你就能解释大多数现象：为什么 clone 后文件缺失、为什么安装 LFS 后恢复、为什么 diff 看到的是 pointer 变化而不是二进制内容变化。  

如果你愿意，我下一步可以把这篇博客整理成你仓库里的 `docs/how-git-lfs-works.md`（带命令示例版）。

