---
sidebar_position: 3
---

# Bash Configuration on Debian 13

This guide details the modular terminal setup located in `Bash.Setup`.

---

## 1. System Aliases & Kernel Checker (`aliases.sh`)

- **Package Management**: Direct aliases for `apt` operations (`update`, `upgrade`, `install`, `remove`, `search`, `clean`, `list`).
- **Kernel Monitor (`check-kernel`)**: Function comparing `uname -r` against the latest stable release from `kernel.org/releases.json`.
- **Modern Tools**: `eza`, `bat`, `duf`, `dust`, `procs`.
