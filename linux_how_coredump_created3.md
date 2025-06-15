how to work around the systemd-coredump.service problem in WSL2?

see: https://github.com/microsoft/WSL/issues/11997#issuecomment-2973395693

---

```
$ sysctl kernel.core_pattern
kernel.core_pattern = |/usr/lib/systemd/systemd-coredump %P %u %g %s %t %c %h %e
```

this pattern is a new method to process coredump generation.

on my WSL2+rhel8.5, it not working, when I send SIGBUS to target process, kernel try to generate core, and dmesg reports connect to systemd coredump service failed.

```
[261870.605917] potentially unexpected fatal signal 7.
[261870.606356] CPU: 0 PID: 30309 Comm: pid_printer Not tainted 5.15.90.1-microsoft-standard-WSL2+ #2
[261870.606804] RIP: 0033:0x7fb18f614068
[261870.607014] Code: 7e 2c 00 f7 d8 64 89 02 b8 ff ff ff ff eb c5 0f 1f 00 f3 0f 1e fa 48 8d 05 f5 d6 2c 00 8b 00 85 c0 75 17 b8 23 00 00 00 0f 05 <48> 3d 00 f0 ff ff 77 50 c3 0f 1f 80 00 00 00 00 55 48 89 f5 53 48
[261870.607891] RSP: 002b:00007fffaaef52a8 EFLAGS: 00000246 ORIG_RAX: 0000000000000023
[261870.608269] RAX: fffffffffffffdfc RBX: ffffffffffffff78 RCX: 00007fb18f614068
[261870.608674] RDX: 00007fb18f8de860 RSI: 00007fffaaef52b0 RDI: 00007fffaaef52b0
[261870.609362] RBP: 0000000000000000 R08: 0000000000000000 R09: 0000000000000000
[261870.609702] R10: 00007fffaaef51c3 R11: 0000000000000246 R12: 0000000000400540
[261870.609845] R13: 00007fffaaef53d0 R14: 0000000000000000 R15: 0000000000000000
[261870.610073] FS:  00007fb18fb07500 GS:  0000000000000000
[261870.618679] systemd-coredump[31738]: Failed to connect to coredump service: No such file or directory
```

Then I checked the running status:

```
$ sudo systemctl status systemd-coredump.socket
● systemd-coredump.socket - Process Core Dump Socket
   Loaded: loaded (/usr/lib/systemd/system/systemd-coredump.socket; static; vendor preset: disabled)
   Active: active (listening) since Thu 2025-06-12 20:48:05 CST; 2 days ago
     Docs: man:systemd-coredump(8)
   Listen: /run/systemd/coredump (SequentialPacket)
 Accepted: 0; Connected: 0;
    Tasks: 0 (limit: 79998)
   Memory: 0B
   CGroup: /system.slice/systemd-coredump.socket

Warning: Journal has been rotated since unit was started. Log output is incomplete or unavailable.
```

and

```
$ sudo systemctl status systemd-coredump.service
Unit systemd-coredump.service could not be found.
```

I searched and it said systemd-coredump should be part of systemd. Then how to work around this?

1. change the core.pattern to old core.xxxxx, it works.
2. if you change pattern to /var/cores/... then make sure /var/cores/... can be written by EUID/EGID of your running process.

The coredump is created and written to by the kernel with the EUID/EGID of your running process.

