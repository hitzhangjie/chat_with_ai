总结下吧：
working area里的修改保存，不会生成新的object；
working area里的修改staging后，会生成新的blob object；
staging的修改commit后，会生成新的commit object，tree object；

---

```bash
zhangjie 🦀 git $ git init
zhangjie 🦀 git $ tree .
.
└── f1

1 directory, 1 file

zhangjie 🦀 git (master) $ tree -a
.
├── .git
│   ├── config
│   ├── description
│   ├── HEAD
│   ├── hooks
│   │   ├── applypatch-msg.sample
│   │   ├── commit-msg.sample
│   │   ├── fsmonitor-watchman.sample
│   │   ├── post-update.sample
│   │   ├── pre-applypatch.sample
│   │   ├── pre-commit.sample
│   │   ├── pre-merge-commit.sample
│   │   ├── pre-push.sample
│   │   ├── pre-rebase.sample
│   │   ├── pre-receive.sample
│   │   ├── prepare-commit-msg.sample
│   │   ├── push-to-checkout.sample
│   │   ├── sendemail-validate.sample
│   │   └── update.sample
│   ├── info
│   │   └── exclude
│   ├── objects
│   │   ├── info
│   │   └── pack
│   └── refs
│       ├── heads
│       └── tags
└── f1

10 directories, 19 files
```

```bash
zhangjie 🦀 git (master) $ touch f1
zhangjie 🦀 git (master) $ git add f1
zhangjie 🦀 git (master) $ tree -a
.
├── .git
│   ├── config
│   ├── description
│   ├── HEAD
│   ├── hooks
│   │   ├── applypatch-msg.sample
│   │   ├── commit-msg.sample
│   │   ├── fsmonitor-watchman.sample
│   │   ├── post-update.sample
│   │   ├── pre-applypatch.sample
│   │   ├── pre-commit.sample
│   │   ├── pre-merge-commit.sample
│   │   ├── pre-push.sample
│   │   ├── pre-rebase.sample
│   │   ├── pre-receive.sample
│   │   ├── prepare-commit-msg.sample
│   │   ├── push-to-checkout.sample
│   │   ├── sendemail-validate.sample
│   │   └── update.sample
│   ├── index
│   ├── info
│   │   └── exclude
│   ├── objects
│   │   ├── e6
│   │   │   └── 9de29bb2d1d6434b8b29ae775ad8c2e48c5391
│   │   ├── info
│   │   └── pack
│   └── refs
│       ├── heads
│       └── tags
└── f1

11 directories, 21 files
zhangjie 🦀 git (master) $ git cat-file -t e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
blob
zhangjie 🦀 git (master) $ git cat-file blob e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
zhangjie 🦀 git (master) $ 
```


```
zhangjie 🦀 git (master) $ echo "hello" > f1
zhangjie 🦀 git (master) $ git cat-file blob e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
zhangjie 🦀 git (master) $ 
```

```bash
zhangjie 🦀 git (master) $ git add f1
zhangjie 🦀 git (master) $ tree -a
.
├── .git
│   ├── config
│   ├── description
│   ├── HEAD
│   ├── hooks
│   │   ├── applypatch-msg.sample
│   │   ├── commit-msg.sample
│   │   ├── fsmonitor-watchman.sample
│   │   ├── post-update.sample
│   │   ├── pre-applypatch.sample
│   │   ├── pre-commit.sample
│   │   ├── pre-merge-commit.sample
│   │   ├── pre-push.sample
│   │   ├── pre-rebase.sample
│   │   ├── pre-receive.sample
│   │   ├── prepare-commit-msg.sample
│   │   ├── push-to-checkout.sample
│   │   ├── sendemail-validate.sample
│   │   └── update.sample
│   ├── index
│   ├── info
│   │   └── exclude
│   ├── objects
│   │   ├── ce
│   │   │   └── 013625030ba8dba906f756967f9e9ca394464a
│   │   ├── e6
│   │   │   └── 9de29bb2d1d6434b8b29ae775ad8c2e48c5391
│   │   ├── info
│   │   └── pack
│   └── refs
│       ├── heads
│       └── tags
└── f1

12 directories, 22 files
zhangjie 🦀 git (master) $ git cat-file blob ce013625030ba8dba906f756967f9e9ca394464a
hello
```

```bash
zhangjie 🦀 git (master) $ git commit -m 'add f1'
zhangjie 🦀 git (master) $ tree -a
.
├── .git
│   ├── COMMIT_EDITMSG
│   ├── config
│   ├── description
│   ├── HEAD
│   ├── hooks
│   │   ├── applypatch-msg.sample
│   │   ├── commit-msg.sample
│   │   ├── fsmonitor-watchman.sample
│   │   ├── post-update.sample
│   │   ├── pre-applypatch.sample
│   │   ├── pre-commit.sample
│   │   ├── pre-merge-commit.sample
│   │   ├── pre-push.sample
│   │   ├── pre-rebase.sample
│   │   ├── pre-receive.sample
│   │   ├── prepare-commit-msg.sample
│   │   ├── push-to-checkout.sample
│   │   ├── sendemail-validate.sample
│   │   └── update.sample
│   ├── index
│   ├── info
│   │   └── exclude
│   ├── logs
│   │   ├── HEAD
│   │   └── refs
│   │       └── heads
│   │           └── master
│   ├── objects
│   │   ├── b9
│   │   │   └── 4fe35f6b9fb42474cece84a668e6788c756803
│   │   ├── ce
│   │   │   └── 013625030ba8dba906f756967f9e9ca394464a
│   │   ├── d1
│   │   │   └── ab65bb06cb7a01bca305f4740426a5228c766a
│   │   ├── e6
│   │   │   └── 9de29bb2d1d6434b8b29ae775ad8c2e48c5391
│   │   ├── info
│   │   └── pack
│   └── refs
│       ├── heads
│       │   └── master
│       └── tags
└── f1

17 directories, 28 files
zhangjie 🦀 git (master) $ git cat-file -t d1ab65bb06cb7a01bca305f4740426a5228c766a
commit
zhangjie 🦀 git (master) $ git cat-file commit d1ab65bb06cb7a01bca305f4740426a5228c766a
tree b94fe35f6b9fb42474cece84a668e6788c756803
author hitzhangjie <hit.zhangjie@gmail.com> 1761797659 +0800
committer hitzhangjie <hit.zhangjie@gmail.com> 1761797659 +0800

add f1
zhangjie 🦀 git (master) $ git cat-file -t b94fe35f6b9fb42474cece84a668e6788c756803
tree
zhangjie 🦀 git (master) $ git cat-file -p b94fe35f6b9fb42474cece84a668e6788c756803
100644 blob ce013625030ba8dba906f756967f9e9ca394464a	f1
zhangjie 🦀 git (master) $ 
```

```bash
zhangjie 🦀 git (master) $ mkdir a b c
zhangjie 🦀 git (master) $ touch a/f1 b/f1 c/f1
zhangjie 🦀 git (master) $ git cat-file -p b94fe35f6b9fb42474cece84a668e6788c756803
100644 blob ce013625030ba8dba906f756967f9e9ca394464a	f1
zhangjie 🦀 git (master) $ tree -a
.
├── .git
│   ├── COMMIT_EDITMSG
│   ├── config
│   ├── description
│   ├── HEAD
│   ├── hooks
│   │   ├── applypatch-msg.sample
│   │   ├── commit-msg.sample
│   │   ├── fsmonitor-watchman.sample
│   │   ├── post-update.sample
│   │   ├── pre-applypatch.sample
│   │   ├── pre-commit.sample
│   │   ├── pre-merge-commit.sample
│   │   ├── pre-push.sample
│   │   ├── pre-rebase.sample
│   │   ├── pre-receive.sample
│   │   ├── prepare-commit-msg.sample
│   │   ├── push-to-checkout.sample
│   │   ├── sendemail-validate.sample
│   │   └── update.sample
│   ├── index
│   ├── info
│   │   └── exclude
│   ├── logs
│   │   ├── HEAD
│   │   └── refs
│   │       └── heads
│   │           └── master
│   ├── objects
│   │   ├── b9
│   │   │   └── 4fe35f6b9fb42474cece84a668e6788c756803
│   │   ├── ce
│   │   │   └── 013625030ba8dba906f756967f9e9ca394464a
│   │   ├── d1
│   │   │   └── ab65bb06cb7a01bca305f4740426a5228c766a
│   │   ├── e6
│   │   │   └── 9de29bb2d1d6434b8b29ae775ad8c2e48c5391
│   │   ├── info
│   │   └── pack
│   └── refs
│       ├── heads
│       │   └── master
│       └── tags
├── a
│   └── f1
├── b
│   └── f1
├── c
│   └── f1
└── f1

20 directories, 31 files
```

```bash
zhangjie 🦀 git (master) $ git add a b c
zhangjie 🦀 git (master) $ git cc -m 'add folders'
zhangjie 🦀 git (master) $ tree -a
.
├── .git
│   ├── COMMIT_EDITMSG
│   ├── config
│   ├── description
│   ├── HEAD
│   ├── hooks
│   │   ├── applypatch-msg.sample
│   │   ├── commit-msg.sample
│   │   ├── fsmonitor-watchman.sample
│   │   ├── post-update.sample
│   │   ├── pre-applypatch.sample
│   │   ├── pre-commit.sample
│   │   ├── pre-merge-commit.sample
│   │   ├── pre-push.sample
│   │   ├── pre-rebase.sample
│   │   ├── pre-receive.sample
│   │   ├── prepare-commit-msg.sample
│   │   ├── push-to-checkout.sample
│   │   ├── sendemail-validate.sample
│   │   └── update.sample
│   ├── index
│   ├── info
│   │   └── exclude
│   ├── logs
│   │   ├── HEAD
│   │   └── refs
│   │       └── heads
│   │           └── master
│   ├── objects
│   │   ├── 3c
│   │   │   └── 91265e1422ab4ee4155fc6994d299a2ed34ff5
│   │   ├── 4f
│   │   │   └── 6a3e763c056f24f5a019591dfa0d280fd721b3
│   │   ├── 56
│   │   │   └── e3dd6f60494c9bbe56ea178b9a86c91d3139c6
│   │   ├── b9
│   │   │   └── 4fe35f6b9fb42474cece84a668e6788c756803
│   │   ├── ce
│   │   │   └── 013625030ba8dba906f756967f9e9ca394464a
│   │   ├── d1
│   │   │   └── ab65bb06cb7a01bca305f4740426a5228c766a
│   │   ├── e6
│   │   │   └── 9de29bb2d1d6434b8b29ae775ad8c2e48c5391
│   │   ├── info
│   │   └── pack
│   └── refs
│       ├── heads
│       │   └── master
│       └── tags
├── a
│   └── f1
├── b
│   └── f1
├── c
│   └── f1
└── f1

23 directories, 34 files
zhangjie 🦀 git (master) $ git cat-file -t 3c91265e1422ab4ee4155fc6994d299a2ed34ff5
commit
zhangjie 🦀 git (master) $ git cat-file -t 4f6a3e763c056f24f5a019591dfa0d280fd721b3
tree
zhangjie 🦀 git (master) $ git cat-file -p 4f6a3e763c056f24f5a019591dfa0d280fd721b3
040000 tree 56e3dd6f60494c9bbe56ea178b9a86c91d3139c6	a
040000 tree 56e3dd6f60494c9bbe56ea178b9a86c91d3139c6	b
040000 tree 56e3dd6f60494c9bbe56ea178b9a86c91d3139c6	c
100644 blob ce013625030ba8dba906f756967f9e9ca394464a	f1
zhangjie 🦀 git (master) $ git cat-file -t 56e3dd6f60494c9bbe56ea178b9a86c91d3139c6
tree
zhangjie 🦀 git (master) $ git cat-file -p 56e3dd6f60494c9bbe56ea178b9a86c91d3139c6
100644 blob e69de29bb2d1d6434b8b29ae775ad8c2e48c5391	f1
zhangjie 🦀 git (master) $ git cat-file blob e69de29bb2d1d6434b8b29ae775ad8c2e48c5391
```
