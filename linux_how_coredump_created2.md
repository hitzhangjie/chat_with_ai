kernel.core_pattern = |/usr/lib/systemd/systemd-coredump %P %u %g %s %t %c %h %e

---

When you see `kernel.core_pattern = |/usr/lib/systemd/systemd-coredump %P %u %g %s %t %c %h %e`, it means that **your Linux system is configured to handle core dumps using `systemd-coredump`**.

Let's break down what that means:

---

### What is a Core Dump?

A **core dump** is a file containing the memory image of a running process at the time it terminated unexpectedly (e.g., due to a crash, segmentation fault, or unhandled exception). It's essentially a snapshot of the process's state, including its memory, CPU registers, and stack trace. Developers and system administrators use core dumps to debug and diagnose why a program crashed.

---

### `kernel.core_pattern` Explained

The `kernel.core_pattern` parameter in Linux specifies how core dump files are named and where they are stored. It's a kernel tunable that you can set using `sysctl`.

* **`|` (pipe symbol):** This is the crucial part here. When the `core_pattern` starts with a pipe (`|`), it tells the kernel to pipe the core dump data directly to the specified program as standard input, rather than writing it to a file. This is a more modern and flexible way to handle core dumps, as it allows for immediate processing.

* **`/usr/lib/systemd/systemd-coredump`:** This is the executable that will receive the core dump data. `systemd-coredump` is a component of `systemd` that provides a centralized and efficient way to capture, compress, and store core dumps. It often places them in `/var/lib/systemd/coredump/` (or a similar location) and can integrate with journald for logging.

* **`%P %u %g %s %t %c %h %e` (Specifiers):** These are placeholders that the kernel replaces with specific information about the crashed process before passing them as arguments to `systemd-coredump`.
    * `%P`: PID of the dumped process.
    * `%u`: User ID of the dumped process.
    * `%g`: Group ID of the dumped process.
    * `%s`: Signal number that caused the dump.
    * `%t`: Unix time of the dump.
    * `%c`: Core file size limit (soft limit) of the dumped process.
    * `%h`: Hostname.
    * `%e`: Executable filename.

---

### In Summary

This `kernel.core_pattern` setting means that whenever a program crashes on your system:

1.  The Linux kernel intercepts the crash.
2.  Instead of writing the core dump to a file directly, it pipes the raw core dump data to the `systemd-coredump` utility.
3.  `systemd-coredump` then takes this data, along with the provided process information, and typically compresses it and stores it in a structured way (often with metadata in the systemd journal).

This approach offers several advantages, including:

* **Centralized management:** Core dumps are handled consistently.
* **Compression:** Saves disk space.
* **Metadata:** Richer information about the crash is stored.
* **Security:** Avoids potential security issues of arbitrary core dump locations.

If you are experiencing application crashes, you would typically use `journalctl -b -g coredump` or `coredumpctl` to list and inspect the captured core dumps.
