hitzhangjie:
------------------------------------------------------------------------------
how many states does Linux process have?

GitHub Copilot:
------------------------------------------------------------------------------
A Linux process can have one of the following five states:

- Running: The process is either running or it is ready to run.
- Waiting: The process is waiting for an event or for a resource. Linux differentiates between two types of waiting processes: interruptible and uninterruptible. Interruptible waiting processes can be interrupted by signals whereas uninterruptible waiting processes cannot.
- Stopped: The process has been stopped, usually by receiving a signal.
- Zombie: This is a halted process which, for some reason, still has a task_struct data structure in the task vector. It is a process in the "Terminated state".
- Dead: The process is not executing, and not ready to run. It is waiting to be removed by its parent.

This is a simplified view, and Linux actually differentiates between a few more states.

hitzhangjie:
------------------------------------------------------------------------------
If parental process not call wait(pid) to cleanup the child process resource, the child process become zombie process? 

GitHub Copilot:
------------------------------------------------------------------------------
Yes, if a parent process does not call wait() or waitpid() to clean up the child process's task struct, the child process becomes a zombie process. The operating system keeps the process in the process table to allow the parent process to read the child's exit status.

hitzhangjie:
------------------------------------------------------------------------------
Then what does the Dead state mean?

GitHub Copilot:
------------------------------------------------------------------------------
The "Dead" state is a step beyond the "Zombie" state. When a process is in the "Dead" state, it means that it has been removed from the process table. This happens when the parent process finally calls wait() or waitpid(), or if the parent process ends, causing the init process to adopt the child process and automatically call wait() to clean up. After this, the process is completely removed from the system.

In short, if the process removed from the process table, it is dead.