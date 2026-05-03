---
name: dbg-card-game-workflow
description: PRJ-20260421-001 DBG卡牌游戏标准化开发流程 - PRD起草→dev agent委托→验收→部署
---

# DBG 卡牌游戏开发流程

## 概述
PRJ-20260421-001 DBG卡牌游戏的标准化开发流程。

## 标准迭代流程

1. **起草 PRD** → `workspace-pm/proposals/P-YYYYMMDD-NNN-prd.md`
2. **更新 proposal-index.md** → `approved_for_dev` + `confirmed`
3. **委托 dev agent** → `delegate_task`，传 PRD 路径 + 游戏文件路径
4. **Dev 完成检查** → `git log --oneline origin/gh-pages -3` 确认 commit 存在
5. **验收** → browser 验证功能，console 检查关键函数
6. **更新 proposal-index.md** → `accepted` + dev commit hash
7. **询问 boss** → 是否继续下一迭代

## Dev Agent 委托模板

```
项目路径: /mnt/c/Users/YeZhimin/Desktop/card-game-prototype/index.html
PRD: /home/hermes/.hermes/proposals/workspace-pm/proposals/P-XXXXXXXX-XXX-prd.md
GitHub Token: (见记忆文件中的 gh_token)
```

## 关键检查点

### 验证部署成功
```bash
git log --oneline origin/gh-pages -1
```
输出包含版本号和内容说明即成功。

### 验证功能存在
```javascript
// browser console
typeof functionName !== 'undefined'
Object.keys(RELICS || {}).length
FLOORS.length
```

### GitHub Pages 缓存刷新
```
https://yeluo45.github.io/card-game-prototype/?t=1746288000
```
时间戳每次不同即可。

## 常见问题

### Dev agent 完全重写游戏（重要！V17 教训）
**Dev agent 可能完全重写游戏，而不是增强！**

V17 教训：dev agent 将 5127 行的游戏重写成 1018 行的简化版本，完全丢失了 DBG 核心功能。

**预防措施**：
1. 委托时必须明确说明「不要重写游戏，只做增强」
2. 完成后立即检查文件行数：`wc -l index.html`（单次迭代后应该只有少量增加，如 +100~500 行）
3. 检查关键函数是否存在：`grep -c "CARD_UPGRADES\|showDeckPreview" index.html`

**rollback 步骤**（如发现重写）：
```bash
# 1. 确认最后一个正确的 commit
git log --oneline -5

# 2. 回滚到正确版本
git checkout cb9a487 -- index.html

# 3. 重新委托，明确警告「禁止重写」
```

### Git Push TLS 失败（常见）
```
gnutls_handshake() failed: The TLS connection was non-properly terminated.
```
**解决**：等待几秒后重试，通常3-5次后成功。若持续失败：
```bash
GIT_TERMINAL_PROMPT=0 git push origin gh-pages
```

### Dev agent 未完成 git push
当 dev agent 用 max_iterations 限制时，可能在 git push 前达到上限。
**处理**：检查 `git status --short`，如有修改则手动 commit + push。

### proposal-index.md 重复条目（常见）
多次 patch 后可能出现重复条目，导致文件混乱。
**检查**：`read_file` offset=390-420 查看条目
**修复**：找到重复的 section，用 patch 删除多余条目

### Dev agent 完全重写游戏（已发生！V17教训）
Dev agent 可能完全重写而不是增强，V17 将 5127 行重写为 1018 行。
**验证**：每次后立即 `wc -l index.html`，行数应该只有少量增加（+100~500）
**恢复**：`git checkout <good-commit> -- index.html` 回滚，重新委托

### Dev agent 写错路径（重要）
Dev agent (codex/claude) **经常写错工作目录**。委托后必须验证文件是否在正确位置：

```bash
# 正确路径
ls /mnt/c/Users/YeZhimin/Desktop/card-game-prototype/index.html

# dev agent 默认错误路径（会写到自己的 proposals 目录）
ls /home/hermes/workspace-dev/proposals/card-game-prototype/

# 如果文件在错误路径，手动复制
cp /home/hermes/workspace-dev/proposals/card-game-prototype/index.html \
   /mnt/c/Users/YeZhimin/Desktop/card-game-prototype/index.html
```

### PWA 文件检查
V23 引入了 manifest.json 和 sw.js：
```bash
ls -la /mnt/c/Users/YeZhimin/Desktop/card-game-prototype/*.{json,js}
```

### 浏览器显示旧版本
- 用 `?v=N` 或 `?t=timestamp` 强制刷新
- 检查 HTML `<title>` 确认实际版本

## 版本历史

| 版本 | 提案 | 主要内容 |
|------|------|----------|
| V1 | P-20250421-001 | 核心战斗循环 |
| V2 | P-20260502-003 | 卡牌扩充 + 敌人扩充 |
| V3 | P-20260502-006 | 地图/进度系统 |
| V4 | P-20260502-011 | 诅咒牌与特殊牌系统 |
| V5 | P-20260502-012 | 战斗奖励卡牌选择系统 |
| V6 | P-20260502-013 | 遗物/神器系统 |
| V7 | P-20260502-015 | 敌人与Boss扩充 |
| V12 | P-20260503-004 | 音效与特效 |
| V17 | P-20260503-009 | 牌组管理系统 + 卡牌升级扩展 |
| V18 | P-20260503-010 | 随机事件系统 |
| V19 | P-20260503-011 | 多槽位存档系统 |
| V20 | P-20260503-012 | 章节扩展 + Boss战 |
| V21 | P-20260503-013 | 移动端适配 + 触屏支持 |
| V22 | P-20260503-014 | 音效与音乐扩展 |

| V23 | P-20260503-015 | PWA应用化（manifest.json + sw.js） |
| V24 | P-20260503-016 | 成就系统（18个成就） |
| V25 | P-20260503-017 | 宠物/同伴系统（8种宠物） |
| V26 | P-20260503-018 | 更多卡牌设计（15张新卡牌） |

## 游戏访问
https://yeluo45.github.io/card-game-prototype/

## 当前文件大小
- V24: 7295行（含PWA+成就）
- V25: 7748行（+宠物系统）
- V26: 7950行（+15张新卡牌）
