---
sidebar_position: 3
---

# Bash Configuration on Fedora 44

This guide details the modular terminal setup located in `Bash.Setup`.

---

## 1. System Aliases & Kernel Checker (`aliases.sh`)

- **Package Management**: Direct aliases for `dnf5` operations (`update`, `upgrade`, `install`, `remove`, `search`, `clean`, `list`).
- **Kernel Monitor (`check-kernel`)**: Function comparing `uname -r` against the latest stable release from `kernel.org/releases.json`.
- **Modern Tools**: `eza`, `bat`, `duf`, `dust`, `procs`.
