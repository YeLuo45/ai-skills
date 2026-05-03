---
name: multi-agent-parallel-feature-merge
description: 多个 subagent 基于同一 GitHub 仓库并行迭代时的 merge 流程与预防策略
tags: [git, subagent, merge, parallel-dev]
---

# Multi-Agent 并行迭代代码合并流程

## 触发条件

多个 subagent 基于同一 GitHub 仓库做并行迭代开发时，如果：
- 各自 clone 到不同 `/tmp/` 目录
- 但没有约定不同 branch 名称
- 或没有约定 merge 策略

结果：代码分散在多个分支，需要人工合并。

## 问题发现过程

```
P-20260430-003 v1 → 推送到 origin/master ✓
P-20260430-004 v2 → 推送到 origin/v2-level-system ✓
P-20260430-005 v3 → 同样推送到了 origin/v2-level-system（基于同一 clone）✓
```

两个问题：
1. v2 和 v3 的分支选择依赖于 subagent 各自的行为，不可靠
2. 最终代码没有全部在 master 上

## 正确流程（已验证）

### 如果可以重新设计
- **方案A**：约定各 subagent 使用不同分支名（如 `v1-boss-skill`、`v2-level-achievement`、`v3-combo-stats`），最后统一 merge 到 master
- **方案B**：使用单一 subagent 顺序实现（或单一 subagent 并行 + 内部协调）

### 如果 subagent 已经各自推送
```bash
# 1. 在本地 clone 仓库
git clone https://github.com/YeLuo45/whack-a-mole-3d.git /tmp/merge

# 2. 找到所有相关分支
git branch -a

# 3. 按正确顺序依次 merge
git fetch origin <branch1>
git fetch origin <branch2>
git merge origin/<branch1> --no-edit  # Fast-forward
git merge origin/<branch2> --no-edit  # 可能需要解决冲突

# 4. 验证合并结果
git log --oneline -5

# 5. 推送
git push origin master
```

## 关键教训

1. **并行 subagent + 同一仓库 + 无分支约定 = 必须 merge**
2. subagent 的 branch 行为不可靠（取决于它自己怎么理解任务）
3. 如果知道是同一仓库的并行迭代，**优先在主 session 预先 merge**，不要依赖 subagent 正确处理分支
4. merge 时用 `--no-edit` 避免进入编辑器

## 预防措施

未来多 subagent 并行迭代同一代码库时：
1. 在委托前先在主 session clone 好仓库，创建各自的 feature branch
2. 或者约定 subagent 都推送到各自独立分支，主 session 最后统一 merge
3. 记录所有分支名到 proposal-index.md
