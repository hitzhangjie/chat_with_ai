hitzhangjie:
-----------------------------------------------------------------------------------
git cherrypick多个commit的时候如何直接squash成一个commit？

GitHub Copilot:
-----------------------------------------------------------------------------------
你可以按照以下步骤来实现：

首先，你需要找到你想要cherry-pick的commit的哈希值。你可以通过git log命令来查看commit历史并找到这些哈希值。

使用git cherry-pick命令来应用这些commit。你需要使用`-n`选项来防止git自动创建新的commit。例如，如果你想要cherry-pick哈希值为abc123和def456的commit，你可以运行`git cherry-pick -n abc123 def456`。

现在，所有的更改都已经在你的工作目录中，但是还没有被commit。你可以使用`git commit`命令来创建一个新的commit，这个commit会包含所有cherry-pick的更改。例如，你可以运行`git commit -m "Squashed commit"`。

请将上述的abc123和def456替换为你实际的commit哈希值。