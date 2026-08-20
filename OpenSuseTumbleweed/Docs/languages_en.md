---
sidebar_position: 3
---

# Programming Languages & Runtimes in OpenSUSE Tumbleweed

This guide details the installation and management of programming language runtimes in `ProgrammingLanguages/`.

Runtime version management is powered by **Mise** and native Zypper development patterns.

---

## 1. Mise Version Manager (`mise.sh`)

```bash
just mise
```

---

## 2. Available Languages

- **Node.js LTS (22)**: `just node`
- **Python 3.13**: `just python`
- **Rust**: `just rust`
- **.NET SDK 10**: `just dotnet`
- **OpenJDK 21**: `just java`
- **Gemini CLI**: `just gemini`
- **Angular CLI**: `just angular`

Install all with:
```bash
just languages
```
