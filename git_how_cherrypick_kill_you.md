一个最小修改，复现对同一个源文件多线修改+git cherry-pick操作，最终结果包含了两个分支的修改，即使某些行号重叠区域存在共同修改。

s0 master:

```
touch f
echo "apple from master" > f
echo "banana from master" >> f
git cc -m 'add f'

---
f:

@@ -0,0 +1,2 @@
apple from master
banana from master
```

s1 create feature and change f:

```
git ck -b feature master
echo "aaa from feature" >> f
echo "bbb from feature" >> f
git add .
git cc -m 'add feature'

---

@@ -1,2 +1,4 @@
Line1 apple from master
Line2 banana from master
Line3 aaa from feature        // WARN: expects a conflict with changes from master which not happen
Line4 bbb from feature
```

s2 switch back to master and change f
    
Here, insert after line1, why:
对于插入操作xdl_do_merge三路合并时, 对于每一个change block用s_xdchange表示，s_xdchange.chg1==0, 
如果另一个分支也是插入操作，但是行号不同，就很容易导致误判，“这是一个对基线文件不同行区域 [s_xdchange.i1, s_xdchange.i1+s_xdchange.chg1) 做的没有冲突的修改”

see调试跟踪过程: https://docs.qq.com/doc/DYmVVSFByb05yZE5W.

```
git ck master
cat>f<<EOF
apple from master
xxxx from master
xxxx from master
banana from master
EOF

---

@@ -1,2 +1,4 @@
Line1 apple from master
Line2 xxxx from master
Line3 xxxx from master       // WARN: expects a conflict with changes from master which not happen
Line4 banana from master
```

s3 master:

```
git ck master
git cp bc54ffae1404692cc455a1cab2ecd6fc872442f6 (change on feature branch)

---

@@ -2,3 +2,5 @@ apple from master
Line1 xxxx from master      // f*ck! no one change this
Line2 xxxx from master
Line3 banana from master    // change from master
Line4 aaa from feature      // change from feature
Line5 bbb from feature
```

**警示：对同一个源文件同时进行多线修改，不是一个好的实践，再混上 `git cherry-pick`，就属于分支策略混乱的基础上，再叠加对git工作原理的误解，非常容易犯错，最终结果也将十分不可预测：**

- 可能出现A、B、A问题，表现是代码怎么又改回去了？
- merge多次，跟每次merge的时机还有关系，结果也不可预测？
- 多线修改，代码并不是冲突或者合并，而是包含了两份修改？

**重学git明确几个问题：**

- git中的每个commit都是一个repo的完整快照，diff只是我们git show commit的时候计算出来的，例如git diff <parentOfCommit> <commit>。
- git中使用对象数据库(object database, .git/objects, .git/staging)来存储不同类型数据：
    - tree: 目录下的子目录及文件列表，不同版本也是用hash来表示, git cat-file -p <treeHash> 可以看到这个版本的完整目录结构，以及其中每个子目录(tree hash)或文件的版本(blob hash)
    - blob: 每个源文件或者二进制文件，每个版本对应一个blob对象，git cat-file blob <blobHash> 可以查看源文件的内容
    - commit：当在working area对文件进行修改时，不会生成新版本，当对修改进行git add完成stage操作后，会创建新版本的blob对象，tree对象，执行git commit后会生成新commit对象，执行 git cat-file commit <commitHash> 可以查看提交时填写的message信息等
    - tag：略
    - git rev-parse <commitHash>^{tree}，可以通过commitHash找到关联的treeHash，进而找到各个子目录或者文件的treeHash、blobHash
- 每个commit是个快照，如果文件不修改就不会重复存储，./.git/objects/ff/aabbccdd...，如果一个文件从没修改且其hash是ffaabbccdd...，那么所有版本的tree对象里记录的都是这同一个hash，有点像指针。
- 因为每个commit是个快照，而不是一个个简单的diff文件叠加，所以git才能轻易做到其他版本控制系统不那么方便做到的事情，比如shallow clone、partial clone
    - shallow clone: ci/cd的时候为了加速拉取代码才可以 git clone --depth=1 <repo>，
    - partial clone: 只检出部分感兴趣的目录、源文件--filter (see git help git-rev-list --filter options)。
- git merge <branch> 是会将branch上所有修改都合并到当前分支，注意<branch>究竟指向谁记录在./git/refs/heads，其实就是这个分支的HEAD

   ```bash
   zhangjie🦀 chat_with_ai(master) $ cat ./.git/refs/heads/master
   d0a3b195a54fc85c7e63bf7dbc0729ea407d2492

   zhangjie🦀 chat_with_ai(master) $ git logx | head -n 1
   * d0a3b19 14 hours ago >>> git: how git objects stored, blob, commit, tree                                <<< <hitzhangjie>
   ```
   HEAD是快照对不对？对，那其实根据最新这个HEAD进行merge操作是否就够了？
   git merge三路归并，两个分支a，b的公共祖先o，如果当前在a，执行git merge b。计算a-o（差集），b-o，对每个代码修改块set_a-o, set_b-o，应用xdl_do_merge中的冲突检测、合并逻辑。

- git cherry-pick <commit> 大家可能以为git会先计算这个git diff parent-of-<$commit> <$commit>作为一个diff，然后再git apply < diff，大家可能以为底层是这么一个过程，实际上不是。
    - git cherry-pick <commit> 也是走三路合并逻辑，o,a,b，公共祖先o=commit和当前分支HEAD的共同祖先（git merge-base commit HEAD)，然后三路合并逻辑走xdl_do_merge冲突检测、合并逻辑。
    - git apply < diff，它实际上看代码也是一个三路合并逻辑，但是有区别，它的o是parent of current HEAD，而不是待选择的commit和当前分支HEAD的共同祖先。


啰里啰嗦，我感觉有些人应该要听迷糊了。不听也罢，那我们如何避免这个问题呢？


**有不止一个流程问题需要注意:**

- 多分支同时修改，she3，she4同时修改的情景 ==》cherrypick she3修改到she4，会导致结果不符合预期
- 版本开发分支提前拉出后，不定期从master cherrypick多次的问题 ==》因为每个cherry结果是基于三路归并，并且是和公共祖先节点比较，而非merge那样的可以看到完整变更历史，再就是跟cherrypick时机有关系（早了、晚了结果不一样），最终结果可能正确，或者表现出ABA问题

看完git合并的源码后，上述git操作就是不符合最佳实践的做法，是会出问题的，凭运气。

**言归正传，怎么解决呢？** : 不要害怕git cherrypick，有没有风险看我们怎么用

- 开发新特性、解决bug时养成拉feat分支、bugfix分支的好习惯，改完验证完ok了，rebase+squash合入集成分支（如master、版本开发分支）
  ps：因为这个小分支时一个确定目的修改的最小单元，可以像gitflow那样git merge到master、版本开发分支，
      或者先合入master再cp到版本开发分支，但是感觉git merge到版本开发分支更好。

  ps: gitflow master分支负责维护版本发布列表，tag1，tag2，tag3，……，dev分支负责开发，feat、bugfix是在dev分支上做的，hotfix是从master特定tag拉出来做的，然后backport（cherrypick）到后续的dev分支。这个flow中其实也可能存在同时修改同一个文件的可能性，所以很难100%避免。我们项目中用合适，she3、she4并行开发，且分支diverge太多了，而且不能基于公共祖先master分支进行rebase。cherrypick操作目前还是会经常用到的。
          
- 特殊情况如果确实存在多个分支开发的情况，如she3、she4分支出现较大偏差，且没法基于公共祖先进行rebase对齐，此时当需要将某个commit cp到另一个分支时，该怎么办？

  - 人肉：1）git show --stat --oneline <commit>，查看修改了哪几个文件，
          2）git diff HEAD -- changelist，对比下上述修改文件，和当前分支的差异、
          3) 人工执行合并 
          ps: git cp有时该报冲突时甚至不报冲突，原因是它设计上假定大家不存在多线同时修改的不良git实践，你想想如果将你是maintainer，有几个贡献者多个分支修改，又不rebase，找你review时，你愿意吗？肯定不愿意！开源项目提PR前必做git rebase.

  - 半自动：1) 找到公共祖先，git merge-base HEAD <commit>
            2) 看看这个commit改了哪些文件，一般执行这个就够了，大家只改自己服务嘛：git show --stat --oneline <commit>
            3) 看看当前分支与公共祖先对比有没有修改上述文件，git diff <ancestor> HEAD 
               - 如果没有修改，可以放心合并，git cp <commit>
               - 如果有修改，建议还是回去人肉check一下。
        
有没有一劳永逸解决这个问题的方法呢？归根究底是我们业务特殊性，导致了现在特殊的分支管理策略，有没有其他更合适的分支管理策略呢？
我想是有的，主干开发是不是最好的呢？未必，但是可能是相对简单的。其他更灵活更好的方案可能需要在其他地方投入，比如定制gitflow工具、培训git等等。

- 主干开发 or 在现有习惯上微调

  - 每个开发要记得cp；
  - 多版本并行开发维护she3、she4，开发大范围重构要维护在一个超长生命周期的分支上，延迟合入，后续和feat、bugfix一起合并时也会出现要解决冲突的问题；
  - 主干上新版本的需求特性开关加好了吗？当前she4，cp到she3时是不是带出了不完整的代码，还要额外设置开关，热更风险是不是有点高？还是说bugfix现在分支改，再backport回主干；
  - 主干开发一般是在有严密的单测等基础上，提pr跑通前置检查后就可以放心入库，否则不敢入库，问题代码都是负债。
    - 先不考虑质量问题，假定大家都是一心想好好写代码的
    - 紧急bug怎么办，主干、发布分支差异过大，先主干后cherrypick到分支需要解决冲突，直接分支拉个bugfix分支修完，然后backport回主干是更简单的；
    - 但是主线如果也有做修改，这也是可能的，可能就不能用git cherrypick来backport (本文讲的就是多线修改cherrypick的坑点)，就得在master单独写，创建一个新的commit；

- 灵活点？谁都想灵活点、无拘束，但是如果习惯不好、本身git掌握也不够，容易犯错，项目组要承担风险损失

- 尽量向规范看齐，避免一些不必要的不规范操作，但是对于某些特殊case，还是要“学习了解你的工具git”，用对。

大型开源项目和我们游戏的发布节奏、维护节奏还是有差异的，至少在版本发布前是经历过相当严格的测试的，问题极少，甚至都可以拖到下一个版本再修，所以主干开发、主干集成、分支发布没什么大问题。
我们上线前期还各种调整的代码、配表，而且下个版本的需求也立马排上了，天然存在同时维护线上版本、开发下个版本的情况在，从风险控制角度考虑，不完整、未测试的代码是不允许待上线的，即使有所谓的开关，万一开关逻辑没加、没有验证到呢，先在也没有review把关。
所以……天然存在主干、线上版本分支同时开发的情况在，只是可能比较少，这种情况下注意下cherrypick的上述注意事项，应该也可以较好地避免。


