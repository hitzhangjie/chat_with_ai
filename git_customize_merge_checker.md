# 使用自定义合并驱动增强 Git 冲突检测

本文档记录了如何通过配置 Git 的自定义合并驱动（Custom Merge Driver）来改变其默认的合并行为，以满足特定的冲突检测需求。

## 1. 问题背景

默认情况下，当合并（merge）两个 Git 分支时，如果它们各自的修改位于文件的不同位置，即使从最终结果来看修改的“区域”有所重叠，Git 也可能会将它们干净地合并（clean merge），而不会报告冲突。

在某些工作流中，我们希望任何对同一文件的并行修改（即使在不同位置）都能被标记为冲突，以强制进行人工审查。

**期望行为**：当两个分支都对同一个文件进行了修改时，无论修改位置是否直接冲突，`git merge` 都应提示合并冲突。

## 2. 初步尝试：使用 `union` 合并驱动

我们首先尝试使用内置的 `union` 合并驱动。

### 配置

通过在 `.gitattributes` 文件中添加以下内容来启用 `union` 驱动：

```
* merge=union
```

### 测试与分析

我们对一个具体场景进行了测试：
- **`b11` 分支**：在文件 `f` 的中间插入了内容。
- **`b22` 分支**：在文件 `f` 的末尾插入了内容。

执行 `git merge b11` 后，Git 成功地自动合并了文件，并未产生冲突。

**结论**：`union` 驱动（以及 Git 的标准合并策略）之所以没有报冲突，是因为两个分支的修改从“变更集”的角度来看是不相关的，它们作用于共同祖先的不同行。这无法满足我们“只要有并行修改就提示冲突”的需求。

## 3. 最终方案：自定义合并驱动

为了实现更严格的冲突检测逻辑，我们采用了一个自定义合并驱动脚本。

这个脚本的核心思想是：在合并一个文件时，只要发现当前分支和待合并分支都对该文件做出了修改（相对于它们的共同祖先），就强制让合并操作失败，并报告一个冲突。

### 步骤 1：创建驱动脚本

我们创建了一个名为 `merge-driver.sh` 的 Shell 脚本：

```bash
#!/bin/bash
# Custom merge driver to force conflict on any parallel change.

ancestor_file="$1"
current_file="$2"
other_file="$3"

# 检查两个分支的文件是否都相比于祖先版本发生了变化
# cmp -s 命令在文件相同时返回 0，不同时返回 1
cmp -s "$ancestor_file" "$current_file"
current_has_changes=$?

cmp -s "$ancestor_file" "$other_file"
other_has_changes=$?

# 如果两个分支都进行了修改，则强制制造一个冲突
if [ $current_has_changes -ne 0 ] && [ $other_has_changes -ne 0 ]; then
  # 我们仍然调用 git merge-file 来生成一个合并后的文件
  # 这个文件可能包含标准的冲突标记（如果内容有直接交集）
  # 或者是一个干净的合并结果（如果内容没有直接交集）
  git merge-file --diff3 "$current_file" "$ancestor_file" "$other_file"
  
  # 关键：无论 merge-file 是否成功，我们都以退出码 1 退出
  # 这会告诉 Git 本次合并有冲突，需要用户介入
  exit 1
else
  # 如果只有一个分支或没有分支修改了文件，则执行标准合并
  git merge-file --diff3 "$current_file" "$ancestor_file" "$other_file"
  exit $?
fi
```

然后，赋予该脚本执行权限：

```shell
chmod +x merge-driver.sh
```

### 步骤 2：在 Git 中注册新驱动

使用 `git config` 命令在本地仓库配置中注册这个脚本，将其命名为 `overlap`：

```shell
# 定义驱动名称
git config merge.overlap.name "Overlap-detecting merge driver"

# 指定驱动要执行的命令
# %O, %A, %B 分别是祖先、当前分支、其他分支的文件路径占位符
git config merge.overlap.driver "./merge-driver.sh %O %A %B"
```

### 步骤 3：启用自定义驱动

修改 `.gitattributes` 文件，告诉 Git 对所有（`*`）文件都使用我们刚注册的 `overlap` 驱动：

```
* merge=overlap
```

## 4. 验证

完成以上所有配置后，我们再次执行 `git merge b11` 命令。这一次，得到了预期的结果：

```
Auto-merging f
CONFLICT (content): Merge conflict in f
Automatic merge failed; fix conflicts and then commit the result.
```

`git status` 显示 `f` 文件处于冲突状态，需要人工解决。这证明了自定义合并驱动成功地拦截了自动合并，并强制要求进行人工审查。

通过这种方式，我们成功地定制了 Git 的合并行为，使其更符合特定的、更严格的代码审查工作流。
