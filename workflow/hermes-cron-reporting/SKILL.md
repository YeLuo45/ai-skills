---
name: hermes-cron-reporting
description: Hermes Cron 每日验收报告生成 — 环境路径、cron 输出结构及四个验收项的正确检查方式
---

# Hermes Cron 每日验收报告生成

## 触发条件

生成每日验收报告时使用。

## 关键环境发现

### 路径解析差异

技能文档说 `PROPOSALS_ROOT = ~/.hermes/proposals`，但实际有效路径因 Shell `~` 扩展而不同：

| 变量 | 技能文档路径 | 实际有效路径 | 说明 |
|------|-------------|-------------|------|
| `PROPOSALS_ROOT` | `~/.hermes/proposals` | `/home/hermes/.hermes/proposals/` | `~` 在 bash 中 = `$HOME` = `/home/hermes` |
| `workspace-dev` | `~/.hermes/workspace-dev` | `/home/hermes/.hermes/workspace-dev/` | 同上 |
| `proposal-index.md` | `~/.hermes/proposals/proposal-index.md` | `/home/hermes/.hermes/proposals/proposal-index.md` | 注意是 `.hermes` 子目录 |

### 验证命令

```bash
echo $HOME  # 应输出 /home/hermes
whoami      # 应输出 hermes
```

### 正确读取方式

```bash
# ✅ 用 bash ~ 扩展（HOME=/home/hermes）
cat ~/.hermes/proposals/proposal-index.md
cat ~/proposals/proposal-index.md          # 同上，因为 ~/proposals -> /home/hermes/proposals

# ❌ read_file tool 的 ~ 默认映射到 /root，而非 $HOME
read_file(path="~/.hermes/proposals/proposal-index.md")  # 实际读 /root/.hermes/... → 失败

# ✅ read_file 用绝对路径
read_file(path="/home/hermes/.hermes/proposals/proposal-index.md")  # 成功
```

### Cron 输出目录结构

Cron 输出统一在 `~/.hermes/cron/output/` 下，每个 Job ID 一个子目录：

```
~/.hermes/cron/output/
├── deaa66b08f2d/          # 提案系统→网站同步 cron（每天 09:00, 18:00）
│   └── 2026-04-24_09-00-50.md
├── c394083c069c/          # PRD 超时确认倒计时（一次性 5 分钟）
│   └── 2026-04-24_08-19-47.md
├── github-trending-daily/ # GitHub Trending 推送（固定目录名，非 job ID）
│   └── report.md
└── [其他 job ID]/         # 其他 cron job
```

**注意**：`github-trending-daily` 目录不是 job ID，而是固定名称，每次运行覆盖同一份 `report.md`。

## 验证步骤（每次报告前必查）

1. **检查 cron job 调度时间是否正确**
   ```bash
   cronjob(action='list')  # 查看所有 job 的 schedule 和 next_run_at
   ```
   常见错误：job 创建时 schedule 填错，导致报告在错误时间运行
   - `hermes-agent-acceptance-daily` 应为 `0 21 * * *`（晚9点），误配为 `0 12 * * *`（中午12点）

2. 读 proposal-index：`cat ~/.hermes/proposals/proposal-index.md`（bash）或绝对路径
3. 读 proposal-docs-index：`cat ~/.hermes/proposals/proposal-docs-index.md`
4. 检查贪吃蛇源码语法：grep -n "n pa\|n$" GameCanvas.jsx
5. 检查 GitHub Trending cron：ls -la ~/.hermes/cron/output/github-trending-daily/
6. 检查计算器 APK：find proposals/workspace-dev/proposals/calculator-app -name "*.apk"

## 四个验收项的正确路径

```
贪吃蛇大作战：
  源码：  /home/hermes/.hermes/workspace-dev/proposals/snake-battle/src/components/GameCanvas.jsx
  构建：  /home/hermes/.hermes/workspace-dev/proposals/snake-battle/dist/
  README: /home/hermes/.hermes/workspace-dev/proposals/snake-battle/README.md
  注意：未在 proposal-index.md 登记，需主动搜索

GitHub Trending 推送：
  报告：  /home/hermes/.hermes/cron/output/github-trending-daily/report.md
  时间戳：检查文件 mtime 确认最新推送时间

P-20260419-005 Agent 团队协作：
  proposal-index 中状态：delivered ✅

P-20250416-003 计算器：
  项目：  /home/hermes/.hermes/workspace-dev/proposals/calculator-app/
  android/ 子目录存在
  APK：需检查 android/app/build/outputs/apk/
```

## 报告生成步骤

1. 读 proposal-index：`cat ~/.hermes/proposals/proposal-index.md`（bash）或绝对路径
2. 读 proposal-docs-index：`cat ~/.hermes/proposals/proposal-docs-index.md`
3. 检查贪吃蛇源码语法：grep -n "n pa\|n$" GameCanvas.jsx
4. 检查 GitHub Trending cron：ls -la ~/.hermes/cron/output/github-trending-daily/
5. 检查计算器 APK：find proposals/workspace-dev/proposals/calculator-app -name "*.apk"
