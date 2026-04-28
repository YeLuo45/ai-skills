---
name: run-openclaw-from-source-windows
description: Use when running, verifying, bootstrapping, or debugging OpenClaw from a local source checkout on native Windows PowerShell, especially when pnpm, Gateway startup, setup, service commands, or the local dashboard behave differently than on WSL/macOS/Linux.
---

# 从源码在 Windows 上运行 OpenClaw

## 适用场景

- 仓库路径示例：`h:\WS\ai-tools\opensource\openclaw\openclaw`（按用户实际路径替换）。
- 官方文档推荐 WSL2；本技能针对 **原生 Windows + PowerShell** 下已验证的流程。

## 快速结论

- **PowerShell 优先用 `pnpm.cmd`**。若 `pnpm.ps1` 被执行策略拦截，不要卡在策略问题里。
- **Windows 上不要对源码开发启动用 `gateway --force`**，会报 `lsof not found`。
- **`gateway restart/start/stop` 只针对已安装的服务**；没安装服务时要直接启动前台 Gateway。
- **即使 `--bind loopback`，如果当前解析出的 `gateway.auth.mode=token` 但 token 为空，Gateway 也会拒绝启动**；请显式设置 `OPENCLAW_GATEWAY_TOKEN` 或传 `--token`。
- **`http://127.0.0.1:18789/` 返回 503** 往往不是 Gateway 没起，而是 **Control UI 资源未构建**，先执行 `pnpm ui:build`。
- **`openclaw setup`** 会写 `~/.openclaw/openclaw.json` 并初始化默认工作区；若提示缺模板，检查 `docs/reference/templates/IDENTITY.md` 和 `USER.md` 是否存在。

## 环境要求

- **Node.js ≥ 22**（与上游 README 一致）。
- 仓库 `package.json` 当前声明 **`packageManager: pnpm@10.23.0`**。
- 若未全局安装 pnpm，使用 **`npx --yes pnpm@10.23.0`** 执行所有 `pnpm` 命令。

## 0. 先处理 `pnpm` / PowerShell

### `pnpm` 不在 PATH

```powershell
npm install -g pnpm@10.23.0
```

### `pnpm.ps1` 被执行策略拦截

症状通常是：

- `无法加载文件 ...\pnpm.ps1，因为在此系统上禁止运行脚本`

优先方案：

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
pnpm -v
```

如果策略受限或只想绕过 PowerShell 脚本入口，直接用：

```powershell
pnpm.cmd -v
pnpm.cmd openclaw gateway -h
```

在本技能后续命令里，**`pnpm` 与 `pnpm.cmd` 二选一**；在 Windows PowerShell 下，`pnpm.cmd` 更稳。

## 1. 安装依赖

在仓库根目录：

```powershell
cd <openclaw-repo>
pnpm.cmd install
```

若完整安装卡在 postinstall/原生构建过久，可先跳过脚本再按需补构建：

```powershell
pnpm.cmd install --ignore-scripts
```

若本机还没全局 pnpm，则把上面两条替换为：

```powershell
npx --yes pnpm@10.23.0 install
npx --yes pnpm@10.23.0 install --ignore-scripts
```

## 2. 编译到 `dist/`（绕过 Windows 下 `run-node` 的 `pnpm exec tsgo` 问题）

`scripts/run-node.mjs` 在 `dist` 过期时会通过 `cmd /c pnpm exec tsgo|tsc` 编译；在部分 Windows 环境下会出现 **找不到 `tsgo`/`tsc`**。可靠做法：用手动 `tsc` 一次性生成 `dist`：

```powershell
cd <openclaw-repo>
node .\node_modules\typescript\bin\tsc -p tsconfig.json --noEmit false
```

说明：完整 `pnpm build` 含 `bash` 步骤（如 A2UI bundle），仅跑 Gateway/CLI 开发时，上述 `tsc` 通常足够使 `node .\openclaw.mjs` 工作。

## 3. 验证 CLI

```powershell
cd <openclaw-repo>
pnpm.cmd openclaw gateway -h
```

如果这里又触发 `dist is stale` 且失败，回到第 2 节先手动 `tsc`。

## 4. 先跑一次 `setup`

```powershell
cd <openclaw-repo>
pnpm.cmd openclaw setup
```

成功时通常会看到：

- `Config OK` 或 `Wrote ~/.openclaw/openclaw.json`
- `Workspace OK`
- `Sessions OK`

若报：

- `Missing workspace template: IDENTITY.md`
- `Missing workspace template: USER.md`

则检查仓库内是否存在：

```text
docs/reference/templates/IDENTITY.md
docs/reference/templates/USER.md
```

源码运行依赖这些模板来初始化 `~/.openclaw/workspace`。

## 5. 恢复本地 Dashboard（18789）的最小命令

如果你的目标就是恢复：

```text
http://127.0.0.1:18789/
```

请优先走下面这组已经在 Windows PowerShell 下验证过的命令。

先构建 Control UI：

```powershell
cd <openclaw-repo>
pnpm.cmd ui:build
```

再显式设置本地 token 并前台启动 Gateway（**不要**在 Windows 上使用 `--force`：会报 `lsof not found`）：

```powershell
cd <openclaw-repo>
$env:OPENCLAW_SKIP_CHANNELS = "1"
$env:CLAWDBOT_SKIP_CHANNELS = "1"
$env:OPENCLAW_GATEWAY_TOKEN = "dev-local-gateway-token-2026-04-11"
pnpm.cmd openclaw gateway --bind loopback --port 18789 --allow-unconfigured --verbose
```

如果之前执行过：

```powershell
pnpm.cmd openclaw gateway restart
pnpm.cmd openclaw gateway start
```

并看到 `Gateway service missing.`，不要继续重试 `restart/start`，直接切回上面的前台启动命令。

如果这里报：

- `Gateway auth is set to token, but no token is configured.`

说明不是端口问题，而是 **token 缺失**；补上 `OPENCLAW_GATEWAY_TOKEN` 或 `--token` 后再启动。

日志中出现 `listening on ws://127.0.0.1:18789` 即表示监听成功。

## 6. `restart`/`start`/`stop` 与前台启动的区别

```powershell
pnpm.cmd openclaw gateway restart
```

如果输出：

- `Gateway service missing.`
- `Start with: openclaw gateway install`

说明你还**没有把 Gateway 安装成 Windows 服务任务**。此时：

- 想立刻跑起来：用第 5 节的前台启动命令
- 想以后能 `restart/start/stop`：先执行 `pnpm.cmd openclaw gateway install`

**不要把 `gateway restart` 误认为“启动开发网关”的通用命令。**

## 7. 验证 Gateway（RPC health）

若 `~/.openclaw` 里已有其它端口配置，`openclaw health` 可能连错端口。对本次监听的地址显式调用：

```powershell
cd <openclaw-repo>
pnpm.cmd openclaw gateway health --url ws://127.0.0.1:18789 --token dev-local-gateway-token-2026-04-11 --json
```

响应顶层 **`"ok": true`** 即验证通过。

## 8. Dashboard / HTTP 根路径验证

打开：

```text
http://127.0.0.1:18789/
```

如果浏览器提示“无法访问此网站”或 PowerShell `Invoke-WebRequest` 连接失败，优先检查：

- Gateway 是否真的已经启动，而不是只执行了 `gateway restart/start`
- 是否因为 `Gateway auth is set to token, but no token is configured.` 提前退出

如果返回 **503**，常见根因是 **Control UI 静态资源不存在**。构建它：

```powershell
cd <openclaw-repo>
pnpm.cmd ui:build
```

然后再次访问首页。成功时通常返回 `200` 和 `OpenClaw Control` 的 HTML。

注意：

- `gateway health` 的成功只说明 **WebSocket Gateway / RPC 正常**
- 首页 `200` 才说明 **Control UI 资源也已就绪**

两者都最好验证。

## 9. 停止 Gateway（Windows）

不使用 `--force` 时，可按端口结束进程：

```powershell
$p = (Get-NetTCPConnection -LocalPort 18789 -ErrorAction SilentlyContinue | Select-Object -First 1).OwningProcess
if ($p) { Stop-Process -Id $p -Force }
```

## 10. 可选：与全局 `pnpm` / `tsgo` 对齐

若已把 **pnpm** 加入系统 `PATH`，可尝试仅设编译器为 `tsc`，再让 `run-node` 自动编译：

```powershell
$env:OPENCLAW_TS_COMPILER = "tsc"
```

若仍失败，继续采用第 2 节的手动 `tsc`。

## 常见故障速查

- `pnpm` 找不到：先装全局 pnpm，或用 `npx --yes pnpm@10.23.0 ...`
- `pnpm.ps1` 被拦：改用 `pnpm.cmd`，或 `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`
- `tsgo` / `tsc` 找不到：手动执行 `node .\node_modules\typescript\bin\tsc -p tsconfig.json --noEmit false`
- `gateway --force` 失败：Windows 缺 `lsof`，不要用 `--force`
- `Gateway service missing`：说明未安装服务，不是仓库坏了
- `Gateway auth is set to token, but no token is configured`：给 `OPENCLAW_GATEWAY_TOKEN` 赋值，或在启动命令里传 `--token`
- `127.0.0.1:18789` 无法访问：先确认 Gateway 进程已监听，再确认 `pnpm.cmd ui:build` 已执行
- 首页 503：Control UI 资源未构建
- `openclaw setup` 缺模板：检查 `docs/reference/templates/IDENTITY.md` 和 `USER.md`

## 相关文档

- 上游入门：<https://docs.openclaw.ai/start/getting-started>
- 本机配置与多智能体：参见用户技能 `add-openclaw-agent`（`~/.openclaw/openclaw.json`、工作区等）。
