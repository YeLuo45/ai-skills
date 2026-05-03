---
name: subagent-delegation-checklist
description: subAgent 委托后的验收清单与常见问题预防
version: 1.0.0
author: Hermes Agent
license: MIT
---

# subAgent 委托验收清单

## 何时使用

每次使用 delegate_task 委托子Agent后，应用此清单进行验收。

## 验收检查清单

### 1. 文件位置检查
- [ ] 文件是否写入正确目录（检查完整绝对路径）
- [ ] 不是 home/ 或 session 默认目录

### 2. PRD 需求核对
- [ ] 每一条 PRD 需求是否有对应实现
- [ ] 常见遗漏项：
  - UI 按钮（开始/重新开始）
  - 游戏结束判定逻辑
  - 边界条件处理
  - 错误处理

### 3. 功能完整性
- [ ] 核心逻辑可正常运行
- [ ] 主要功能流程无崩溃
- [ ] 控制台无 Error

### 4. 关键 Bug 模式检查（web UI 项目）
- [ ] `grep -n "WIN_VALUE\|hardcode\|写死的值" src/` — 检查配置是否被硬编码覆盖
- [ ] `grep -n "import.*组件名" src/` — 检查组件是否被 import（文件存在 ≠ 被使用）
- [ ] `grep -n "组件名\|<组件 " src/` — 检查组件是否在 JSX 中实际渲染
- [ ] 检查 hooks 返回值是否被调用方正确解构（如 `mode` vs `playMode` vs `gameMode`）

### 5. 存储 key 验证
- [ ] 切换模式后 localStorage key 是否真的变化
- [ ] 不同概念（如 gameMode + playMode）的存储 key 是否各自独立

### 6. 文件行数验证（针对已有项目增强）
- [ ] 交付后立即检查文件行数：`wc -l <file>`
- [ ] 如果行数大幅减少（如减少50%+），说明发生了重写，必须回滚
- [ ] 回滚命令：`git checkout <previous_commit> -- <file>`
- [ ] 回滚后重新委托，明确强调「禁止重写，只能修改」

## 常见问题

| 问题 | 原因 | 预防 |
|------|------|------|
| 文件写入 ~/animal-forest/ 而不是 proposals/workspace-dev 目录 | subAgent 自作主张在 home 目录创建项目 | **delegate_task 的 context 里写明：`项目根目录 = ~/.hermes/proposals/workspace-dev/proposals/<slug>/`，明确告知"不要在其他位置创建文件，创建后用 ls 验证"** |
| 找到错误的代码库路径 | subAgent 根据模糊描述自行推断项目位置 | **委托前先用 terminal + find 确认实际路径**，特别对于 web 项目，实际可能是一个单文件 HTML 而非 React 目录 |
| 组件文件存在但从未渲染 | subAgent 创建了组件但忘记在父组件中 import 和使用 | **验收时必须验证：grep -n "import.*组件名" 检查是否有 import，grep "组件名" 检查是否有实际渲染** |
| 配置对象定义但从未读取 | subAgent 定义了 MODES/Achievements 等配置，但实际逻辑用硬编码绕过 | **验收时必须验证：grep 配置文件中的 key 名，确认在 hook/逻辑代码中有实际调用** |
| 两套概念混用（如 gameMode vs playMode） | subAgent 定义了 A/B 两种概念但存储 key 只用了一种 | **验收时必须验证：每种概念都有对应的存储 key，切换概念时 key 确实变化** |
| PRD 要求遗漏 | subAgent 未完整理解需求 | 交付后逐一核对 |
| 直接跳过草稿确认 | subAgent 自主执行 | 先要求输出结构，确认后再写文件 |
| GitHub push 失败（WSL 网络） | WSL DNS/网络问题 | 委托前确认网络，备好手动 push 方案（API创建仓库+本地commit待网络恢复后push） |
| dev agent 完全重写游戏而非增强 | subAgent 倾向于从头创建而非修改现有代码 | **对于已有项目（特别是单文件项目如HTML游戏），必须在 context 中明确强调：「禁止重写游戏，只能修改现有代码」。交付后立即检查文件行数，如果行数大幅减少（如5000行→1000行）说明发生了重写，必须回滚并重新委托** |

### 委托前必做：项目结构预检

对于 web UI 类项目，在委托前先用以下命令确认实际代码位置：

```bash
# 在预期项目目录下执行
find . -name "*.html" -not -path "./node_modules/*" 2>/dev/null | head -5
find . -name "package.json" -not -path "./node_modules/*" 2>/dev/null
ls -la
```

这样可以避免 subAgent 跑到错误路径（如 `hermes-collab-web/` 而非 `collaboration/web/index.html`）。

## 关键教训

1. **必须指定完整绝对路径**，不能只给目录名
2. **subAgent 跳过草稿确认是常见问题**，主Agent必须主动验收
3. **PRD 每一条都要核对**，不能假设交付即合格
4. **web UI 项目在委托前预检实际代码位置**，实际实现可能与描述不符（单文件 vs 框架项目）
