---
name: game-studio-dev-workflow
description: Claude Code Game Studios 多Agent开发流程规范 — 包含任务分发、文件位置验证、功能完整性验收
version: 1.0.0
author: Hermes Agent
tags: [Game Development, Multi-Agent, Acceptance Review]
metadata:
  hermes:
    category: workflow
---

# Game Studio 开发流程规范

## 何时使用

当使用 `game-studio` 技能通过 `delegate_task` 启动多Agent开发时，遵循本规范。

---

## 1. 任务分发前

### 1.1 明确项目根目录
```
项目必须位于: ~/.hermes/proposals/workspace-dev/proposals/<slug>/
```
- 在 `delegate_task` 的 `context` 中明确写出完整路径
- 路径末尾不带 `/`

### 1.2 验证 GDD/技术方案存在
- 确认 `docs/gdd.v1.md` 已产出
- 确认 `docs/technical-solution.v1.md` 已产出

---

## 2. 任务分发时

### 2.1 delegate_task context 必须包含
```javascript
{
  "项目目录": "/home/hermes/.hermes/workspace-dev/proposals/<slug>/",
  "GDD路径": "/home/hermes/.hermes/workspace-dev/proposals/<slug>/docs/gdd.v1.md",
  "技术方案路径": "/home/hermes/.hermes/workspace-dev/proposals/<slug>/docs/technical-solution.v1.md",
  "必须读取这两个文档作为实现参考！"
}
```

### 2.2 明确验收标准
在 `goal` 中列出必须实现的核心功能，不能只说"实现游戏"。

---

## 3. 任务完成后（关键！）

### 3.1 文件位置验证
```bash
# 检查文件是否在正确位置
ls -la ~/.hermes/proposals/workspace-dev/proposals/<slug>/
```
- 常见错误：文件被创建在 `/home/hermes/<slug>/` 或 `~/<slug>/`
- 如位置错误，立即 `mv` 移动文件

### 3.2 语法检查
```bash
node --check ~/.hermes/proposals/workspace-dev/proposals/<slug>/game.js
```

### 3.3 功能完整性验收（对照 GDD）

**必须检查项**:
1. GDD 中定义的核心系统是否有对应实现？
2. 主场景是否齐全？
3. 核心功能是否可运行？
4. 数据存储是否实现？

**检查方法**:
```bash
# 搜索关键功能关键词
grep -E "class.*Scene|function.*Pet|function.*Feed|hunger|happiness" game.js
```

---

## 4. 常见问题处理

### 4.1 文件放错位置
```bash
# 从错误位置移动到正确位置
mv /home/hermes/game.js ~/.hermes/proposals/workspace-dev/proposals/<slug>/game.js
mv /home/hermes/<slug>/* ~/.hermes/proposals/workspace-dev/proposals/<slug>/
```

### 4.2 缺少核心功能
- 如果验收发现 GDD 核心功能缺失 → `needs_revision`
- 输出结构化返修意见：
  ```
  问题: <描述>
  影响: <什么功能受影响>
  期望修复: <如何修复>
  ```

### 4.3 HTML 未引用正确资源
- 检查 `index.html` 中的 `src` 和 `href` 指向是否正确
- 常见问题：引用 `css/styles.css` 但文件叫 `style.css`

---

## 5. 验收通过后

### 5.1 更新提案状态
- `in_acceptance` → `accepted`（通过）
- 或 `in_acceptance` → `needs_revision`（不通过）

### 5.2 部署准备
- GitHub Pages: 创建 `gh-pages` 分支，直接推送 `index.html` + `game.js` + `style.css`
- 或告知 boss 本地直接打开 HTML 即可运行

---

## 关键教训

> **开发完成 ≠ 验收通过**。必须对着 GDD 逐项核对功能实现情况。
