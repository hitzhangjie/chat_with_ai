1. I write a very simple c code:

```c
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char *argv[])
{
    add(1,2);
    add(3,4);
    
    return 0;
}

int add(int a, int b) {
    return a+b;
}
```

2. I compile it `gcc -c -O0 main.c -o main.o`

3. Then disassemble it `objdump -dS main.o`:

```asm
$ objdump -dS main.o

main.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <main>:
   0:   55                      push   %rbp
   1:   48 89 e5                mov    %rsp,%rbp
   4:   48 83 ec 10             sub    $0x10,%rsp
   8:   89 7d fc                mov    %edi,-0x4(%rbp)
   b:   48 89 75 f0             mov    %rsi,-0x10(%rbp)
   f:   be 02 00 00 00          mov    $0x2,%esi
  14:   bf 01 00 00 00          mov    $0x1,%edi
  19:   b8 00 00 00 00          mov    $0x0,%eax
  1e:   e8 00 00 00 00          callq  23 <main+0x23> <== !!!
  23:   be 04 00 00 00          mov    $0x4,%esi
  28:   bf 03 00 00 00          mov    $0x3,%edi
  2d:   b8 00 00 00 00          mov    $0x0,%eax
  32:   e8 00 00 00 00          callq  37 <main+0x37> <== !!!
  37:   b8 00 00 00 00          mov    $0x0,%eax
  3c:   c9                      leaveq
  3d:   c3                      retq

000000000000003e <add>:
  3e:   55                      push   %rbp
  3f:   48 89 e5                mov    %rsp,%rbp
  42:   89 7d fc                mov    %edi,-0x4(%rbp)
  45:   89 75 f8                mov    %esi,-0x8(%rbp)
  48:   8b 55 fc                mov    -0x4(%rbp),%edx
  4b:   8b 45 f8                mov    -0x8(%rbp),%eax
  4e:   01 d0                   add    %edx,%eax
  50:   5d                      pop    %rbp
  51:   c3                      retq
```

4. pay attention to the call instruction, weired? it looks like callq doesn't really call a function.

5. actually, the callq instruction doesn't contain the valid function address here.

6. let's think about how the linker process the multiple *.o files.

```bash
$ readelf -S -r main.o
There are 12 section headers, starting at offset 0x2e0:

Section Headers:
  [Nr] Name              Type             Address           Offset
       Size              EntSize          Flags  Link  Info  Align
  [ 0]                   NULL             0000000000000000  00000000
       0000000000000000  0000000000000000           0     0     0
  [ 1] .text             PROGBITS         0000000000000000  00000040
       0000000000000052  0000000000000000  AX       0     0     1
  [ 2] .rela.text        RELA             0000000000000000  00000220
       0000000000000030  0000000000000018   I       9     1     8
  [ 3] .data             PROGBITS         0000000000000000  00000092
       0000000000000000  0000000000000000  WA       0     0     1
  [ 4] .bss              NOBITS           0000000000000000  00000092
       0000000000000000  0000000000000000  WA       0     0     1
  [ 5] .comment          PROGBITS         0000000000000000  00000092
       000000000000002e  0000000000000001  MS       0     0     1
  [ 6] .note.GNU-stack   PROGBITS         0000000000000000  000000c0
       0000000000000000  0000000000000000           0     0     1
  [ 7] .eh_frame         PROGBITS         0000000000000000  000000c0
       0000000000000058  0000000000000000   A       0     0     8
  [ 8] .rela.eh_frame    RELA             0000000000000000  00000250
       0000000000000030  0000000000000018   I       9     7     8
  [ 9] .symtab           SYMTAB           0000000000000000  00000118
       00000000000000f0  0000000000000018          10     8     8
  [10] .strtab           STRTAB           0000000000000000  00000208
       0000000000000011  0000000000000000           0     0     1
  [11] .shstrtab         STRTAB           0000000000000000  00000280
       0000000000000059  0000000000000000           0     0     1
Key to Flags:
  W (write), A (alloc), X (execute), M (merge), S (strings), I (info),
  L (link order), O (extra OS processing required), G (group), T (TLS),
  C (compressed), x (unknown), o (OS specific), E (exclude),
  l (large), p (processor specific)

Relocation section '.rela.text' at offset 0x220 contains 2 entries:
  Offset          Info           Type           Sym. Value    Sym. Name + Addend
00000000001f  000900000004 R_X86_64_PLT32    000000000000003e add - 4
000000000033  000900000004 R_X86_64_PLT32    000000000000003e add - 4

Relocation section '.rela.eh_frame' at offset 0x250 contains 2 entries:
  Offset          Info           Type           Sym. Value    Sym. Name + Addend
000000000020  000200000002 R_X86_64_PC32     0000000000000000 .text + 0
000000000040  000200000002 R_X86_64_PC32     0000000000000000 .text + 3e
```

well, we see .rela.text contains some interesting info:

```bash
  Offset          Info           Type           Sym. Value    Sym. Name + Addend
00000000001f  000900000004 R_X86_64_PLT32    000000000000003e add - 4
```

this line means: the data at the address 00000000001f should be patched to the offset to the address of function add, here it's add-4.

7. we can build an executable and check again: `gcc -o main main.c` and then `objdump -dS main`:

```bash
0000000000400536 <main>:
  400536:       55                      push   %rbp
  400537:       48 89 e5                mov    %rsp,%rbp
  40053a:       48 83 ec 10             sub    $0x10,%rsp
  40053e:       89 7d fc                mov    %edi,-0x4(%rbp)
  400541:       48 89 75 f0             mov    %rsi,-0x10(%rbp)
  400545:       be 02 00 00 00          mov    $0x2,%esi
  40054a:       bf 01 00 00 00          mov    $0x1,%edi
  40054f:       b8 00 00 00 00          mov    $0x0,%eax
  400554:       e8 1b 00 00 00          callq  400574 <add> <== right offset
  400559:       be 04 00 00 00          mov    $0x4,%esi
  40055e:       bf 03 00 00 00          mov    $0x3,%edi
  400563:       b8 00 00 00 00          mov    $0x0,%eax
  400568:       e8 07 00 00 00          callq  400574 <add> <== right offset
  40056d:       b8 00 00 00 00          mov    $0x0,%eax
  400572:       c9                      leaveq
  400573:       c3                      retq

0000000000400574 <add>:
  400574:       55                      push   %rbp
  400575:       48 89 e5                mov    %rsp,%rbp
  400578:       89 7d fc                mov    %edi,-0x4(%rbp)
  40057b:       89 75 f8                mov    %esi,-0x8(%rbp)
  40057e:       8b 55 fc                mov    -0x4(%rbp),%edx
  400581:       8b 45 f8                mov    -0x8(%rbp),%eax
  400584:       01 d0                   add    %edx,%eax
  400586:       5d                      pop    %rbp
  400587:       c3                      retq
  400588:       0f 1f 84 00 00 00 00    nopl   0x0(%rax,%rax,1)
  40058f:       00
```
