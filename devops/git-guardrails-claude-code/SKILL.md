---
name: git-guardrails-claude-code
description: 设置 Claude Code 钩子拦截危险 git 命令（push/reset --hard/clean/branch -D 等），防止破坏性操作执行。源自 mattpocock/skills/git-guardrails-claude-code。
category: devops
---

# Git Guardrails for Claude Code

设置 PreToolUse 钩子，在危险 git 命令执行前进行拦截。

## 阻止的命令

- `git push`（所有变体包括 `--force`）
- `git reset --hard`
- `git clean -f` / `git clean -fd`
- `git branch -D`
- `git checkout .` / `git restore .`

## 安装步骤

### 1. 确认范围

询问用户：
- **本项目**（`.claude/settings.json`）
- **全局**（`~/.claude/settings.json`）

### 2. 复制钩子脚本

钩子脚本路径：
- 项目：`scripts/block-dangerous-git.sh`
- 全局：`~/.claude/hooks/block-dangerous-git.sh`

```bash
# 项目级安装示例
mkdir -p .claude/hooks
cp scripts/block-dangerous-git.sh .claude/hooks/
chmod +x .claude/hooks/block-dangerous-git.sh

# 全局安装示例
mkdir -p ~/.claude/hooks
cp scripts/block-dangerous-git.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/block-dangerous-git.sh
```

### 3. 添加钩子配置

**项目级**（`.claude/settings.json`）:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "name": "block-dangerous-git",
            "path": ".claude/hooks/block-dangerous-git.sh"
          }
        ]
      }
    ]
  }
}
```

**全局**（`~/.claude/settings.json`）:
```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "name": "block-dangerous-git",
            "path": "~/.claude/hooks/block-dangerous-git.sh"
          }
        ]
      }
    ]
  }
}
```

## 验证

阻止的命令执行时，Claude 会看到提示信息告知其无权执行该命令。
