how git merge works?

---

The git merge command integrates changes from one branch into the current branch by combining multiple sequences of commits into a single, unified history. The exact mechanism depends on the project's history, resulting in one of two main types of merges: a fast-forward merge or a three-way merge. 

1. Preparation Steps

Before merging, it is best practice to:
- Switch to the receiving branch (e.g., main): git checkout main.
- Ensure both branches are up-to-date with their remote counterparts using git fetch and git pull. 

2. Types of Merges

Git automatically selects the appropriate merge strategy based on the relationship between the two branch tips. 

A. Fast-Forward Merge 

A fast-forward merge occurs when the current branch's tip is an ancestor of the branch being merged; in other words, there is a linear path from the current branch's latest commit to the other branch's latest commit. 
- How it works: Git simply moves the pointer of the current branch forward to the tip of the target branch. No merge commit is created, and the history remains linear.
- When it's used: Typically for short-lived topic branches that haven't caused the main branch to diverge.
- Note: You can force Git to create a merge commit even in a fast-forward scenario using the --no-ff option. 

B. Three-Way Merge (Recursive Merge) 

A three-way merge is the default strategy when the branches have diverged, meaning there are unique commits on both the current branch and the branch being merged that are not on the other's history. 

- How it works:
    - Finds the common ancestor (merge base): Git identifies the most recent commit from which both branches diverged.
    - Calculates diffs: It calculates two sets of changes: one from the merge base to the current branch's tip, and another from the merge base to the target branch's tip.
    - Combines changes: Git attempts to apply both sets of changes simultaneously to create a new snapshot of the project.
    - Creates a merge commit: A new, special commit is created on the current branch. This "merge commit" has two parent commits: the previous tip of the current branch and the tip of the merged branch, thus tying the two histories together.

- When it's used: This is common for longer-running features where the main branch has continued to evolve. 

3. Handling Conflicts

If both branches modify the same lines of the same file in different ways, Git cannot automatically decide which changes to keep. This is called a merge conflict. 

- Git pauses the merge process and marks the conflicted sections in the affected files with visual indicators (<<<<<<<, =======, >>>>>>>).
- The user must manually edit the files to resolve the conflicts.
- After resolving the conflicts, the user must stage the files (git add <filename>) and then commit the changes (git commit) to finalize the merge. 

4. Summary

git merge is a core function for integrating work. It either simply moves a branch pointer forward (fast-forward) or intelligently combines divergent histories using a three-way comparison to create a new merge commit, preserving the history of both lines of development. 
