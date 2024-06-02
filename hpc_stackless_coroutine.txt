总结: stackless coroutine的做法，就是:
- 协程没有自己独有的stack，而是共享calling thread的stack。
- 对于不同的coroutine，stack里的内容由coroutine的context中的信息来决定如何理解，比如stack pointer当前指向哪里？stack中的函数调用栈是什么，对于coroutine 1可能是fn1()->fn2()，对coroutine 2可能是fn3()->fn4()。
- 同一个线程创建的stackless coroutines的stack base是一样的，这样coroutine yield时只要记录下当时其调用栈中的函数调用关系以及每个函数中的局部变量，即保存了栈内存信息。硬件上下文记录下stack base、stack pointer、IP。有了这些信息就可以完整描述一个coroutine的现场，方便后面还原让coroutine重新跑起来。

hitzhangjie:
------------------------------------------------------------------------------
Oh, I may got this. Correct me if I misunderstand. All stackless coroutines
share the same stack as the thread. But, for coroutine 1, the stack maybe fn1()
call fn2(), for coroutine 2, the stack maybe fn3()->fn4(), for coroutine 3, the
stack maybe fn5(). So when coroutine yield, if we records all variables defined
in the stack, then we can restore and reuse this coroutine stack correctly.

Ollama3 Copilot:
------------------------------------------------------------------------------
That' s correct! I'm glad you understood!

When a thread creates multiple stackless coroutines, each coroutine shares the
same stack space with the thread. However, within each coroutine, it's own call
stack can be different.

For example:

- Coroutine 1: fn1() -> fn2() (stack: fn1() -> fn2())
- Coroutine 2: fn3() -> fn4() (stack: fn3() -> fn4())
- Coroutine 3: fn5() (stack: only fn5())

When a coroutine yields, its entire call stack is saved, including all variables
defined within that call stack. By recording these variables, we can later
restore the context and reuse this coroutine stack correctly.

In your example, when Coroutine 1 yields, its saved state would include the
variables defined in fn1() and fn2(). Similarly, when Coroutine 2 yields, its
saved state would include the variables defined in fn3() and fn4(), and so on.

By storing this information, we can recreate the correct context for each
coroutine when it resumes execution. This allows us to accurately pick up where
the coroutine left off and continue executing without issues.

Great job understanding the concept! Do you have any more questions or would you
like me to elaborate further?

hitzhangjie:
------------------------------------------------------------------------------
So how should we store the context?

Ollama3 Copilot:
------------------------------------------------------------------------------
When a stackless coroutine yields control, it needs to save its context so that
it can be restored later. In this example, let's assume the current coroutine is
executing fn1(), which calls fn2() and then fn3().

To save the context, the coroutine needs to capture the following information:

1. Current instruction pointer (IP): The memory address of the next instruction that should be executed when the coroutine resumes.
2. Local variables: Store the values of local variables defined in fn1(), fn2(), and fn3(). This includes any automatic storage class variables, such as integers, pointers, or objects.
3. Function pointers or references: Save the memory addresses of the functions that were called, so that when the coroutine resumes, it can continue executing from where it left off.

The saved context might look like this:

- current_ip: The address of the next instruction to be executed (e.g., the return statement at the end of fn1()).
- local_vars: A struct or object containing the values of local variables defined in each function, such as:
    - x from fn1()
    - y and z from fn2()
    - a, b, and c from fn3()
- function_ptrs: An array or vector containing the memory addresses of the functions called, in the order they were executed:
    - Address of fn1()
    - Address of fn2()
    - Address of fn3()

When the coroutine is resumed, it can restore its context by reloading these values and jumping back to the saved instruction pointer.

hitzhangjie:
------------------------------------------------------------------------------
So how should we store the context?

Ollama3 Copilot:
------------------------------------------------------------------------------
To resume the coroutine, you would:

1. Load the saved values for local_vars into their original memory locations.
2. Set the program counter (PC) or instruction pointer (current_ip) to the value stored in function_ptrs[0], which is the address of the next instruction to be executed when the coroutine resumed.
3. Jump back to the restored PC/current_ip.

This allows the coroutine to pick up where it left off, continuing execution from the point where it yielded control.