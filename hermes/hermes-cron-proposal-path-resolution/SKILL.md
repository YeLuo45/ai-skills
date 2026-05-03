---
name: hermes-cron-proposal-path-resolution
description: 在 Hermes cron job 环境中正确解析提案文件路径。解决 `~/.hermes/proposals` 在 cron session 中指向 `/home/hermes/.hermes/proposals` 而不是 Windows WSL 挂载路径的问题。
---

# Hermes Cron Proposal Path Resolution

## Problem

Cron job 执行时 `~` 展开为 `/home/hermes`，而提案实际存储在：
- **正确路径**: `/home/hermes/.hermes/proposals/proposal-index.md`
- **错误假设**: `/mnt/c/Users/YeZhimin/.hermes/proposals/` (WSL 挂载的 Windows 路径)

## Resolution Steps

1. 优先检查 `/home/hermes/.hermes/proposals/proposal-index.md`
2. 若不存在，检查 `~/proposals` (即 `/home/hermes/proposals`)
3. 最后才检查 WSL 挂载路径 `/mnt/c/Users/*/.hermes/`

## Actual Path Structure (Updated 2026-05-02)

| 用途 | 路径 |
|------|------|
| Main Proposals Index | `/home/hermes/.hermes/proposals/proposal-index.md` |
| PM Workspace | `/home/hermes/.hermes/proposals/workspace-pm/proposals/` |
| Dev Workspace | `/home/hermes/.hermes/proposals/workspace-dev/proposals/` |
| Test Workspace | `/home/hermes/.hermes/proposals/workspace-test/proposals/` |
| Templates | `/home/hermes/.hermes/proposals/templates/` |
| Hermes Memory | `/home/hermes/.hermes/memories/` |

## Critical Discovery (2026-05-02)

**实际提案存储在 `/home/hermes/.hermes/`（原生 Linux 路径）**，不是 Windows 挂载路径。

`~` 在 cron session 中展开为 `/home/hermes`，与预期一致：
- 提案索引：`/home/hermes/.hermes/proposals/proposal-index.md`
- PRD：`/home/hermes/.hermes/proposals/workspace-pm/proposals/<proposal-id>-prd.md`
- 技术方案：`/home/hermes/.hermes/proposals/workspace-dev/proposals/<project>/<proposal-id>-tech-solution.md`

## Cron Session Path Resolution

**正确的搜索顺序**：
1. `/home/hermes/.hermes/proposals/proposal-index.md`
2. `/home/hermes/.hermes/proposals/workspace-pm/proposals/`
3. `/home/hermes/.hermes/proposals/workspace-dev/proposals/`

**快速验证命令**：
```bash
ls -la /home/hermes/.hermes/proposals/
find /home/hermes/.hermes/proposals -name "*.md" | head -10
```

## Related

- skill: `proposal-management` — 提案生命周期管理
- skill: `hermes-cron-reporting` — Cron 输出结构及验收检查方式
