hitzhangjie: 
------------------------------------------------------------------------------
如何在命令行中sidebyside的展示diff信息？甚至能对比到word级别？

搜索github，git-delta，实际上是一个二进制程序delta，它能接受git diff格式的输出，并将其
进一步以更好的可视化方式战士，比如sidebyside对比，比如word级别的对比，还有很多其他特性。

安装方式：
- macOS brew install git-delta
- ubuntu apt-get install git-delta
- fedora yum install git-delta
- centos? 如果发行版版本旧，仓库里可能没有，但是可以通过`cargo install git-delta --locked`来安装

