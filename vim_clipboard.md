hitzhangjie:
------------------------------------------------------------------------------
If I use vim y or x to copy/cut, if i press any other edit actions before press p to paste, the copied/cut content will be dropped, how to work around this?

ps: in a nutshell, we can use:
- method1: `1y` to copy and `1p` to paste.
- method2: add `set clipboard=unnamed` into ~/.vimrc.

gemma:
------------------------------------------------------------------------------
**Solution 1: Use "+y/x command:**

- Instead of `y` or `x` to copy/cut, use `"+y` or `"+x` to copy/cut the text and leave it on the system clipboard.
- This way, you can perform other edits before pasting the content.

**Solution 2: Use a register:**

- Assign the copied/cut text to a register using `"ay` or `"ax` (where `a` is any unused register).
- You can then perform other edits before pasting the content using `"p`.

**Solution 3: Enable `clipboard` option:**

- Add the following line to your `.vimrc` file: `set clipboard=unnamed`.
- This configures Vim to use the system clipboard directly, preserving the copied/cut content until it is pasted.

**Additional Tips:**

- Ensure you are using the correct command to paste, which is `p` for the normal mode and `P` for visual mode.
- If you are still experiencing content being dropped, try restarting Vim or clearing the system clipboard.
