---
name: wslinux-hermes-path-discovery
description: 在 WSL (Windows Subsystem for Linux) 环境下定位 Hermes Agent 的配置、数据和提案文件。关键发现：Hermes 相关文件在 Linux 家目录 /home/hermes/.hermes/，不在 Windows 用户目录 /mnt/c/Users/<username>/ 下。
---

# WSL 环境 Hermes 路径发现

## 关键经验

**在 WSL 中，Hermes Agent 的家目录是 `/home/hermes`（Linux 用户），不是 Windows 用户目录。**

- `$HOME` = `/home/hermes`
- Hermes 配置: `/home/hermes/.hermes/`
- 提案索引: `/home/hermes/.hermes/proposals/proposal-index.md`
- Windows 用户目录: `/mnt/c/Users/YeZhimin/`（可访问，但 Hermes 文件不在此处）

## 错误路径（已验证不通）

```bash
# 这些路径在 WSL 中存在，但不含 Hermes 提案数据
/mnt/c/Users/YeZhimin/proposals/   # 只有 templates/
/mnt/c/Users/YeZhimin/Desktop/hermes/  # 只有 multi-agent-delivery-system-ppt.md

# find /mnt/c/Users -name "proposal-index.md" 会超时（目录太深）
```

## 正确路径

```bash
~/.hermes/proposals/proposal-index.md
~/.hermes/proposals/workspace-dev/proposals/
~/.hermes/proposals/workspace-pm/proposals/
```

## 验证方法

```bash
ls ~/.hermes/proposals/
# 应看到: proposal-index.md, proposal-docs-index.md, workspace-dev/, workspace-pm/, etc.
```

## 为什么在 WSL 中需要知道这个

WSL 混合了 Linux 和 Windows 两套文件系统：
- Linux 进程（Hermes Agent）运行在 Linux 上下文，$HOME 是 /home/hermes
- /mnt/c/ 是 Windows 文件系统的映射，Hermes 不会把持久化数据放这里
- 即使 /mnt/c/Users/YeZhimin/ 下能看到一些 hermes 相关文件，那只是 Windows 能看到的内容，不是实际运行环境所用的路径
