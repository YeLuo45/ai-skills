---
name: merge-superset-branch-resolution
description: 当feature分支是remote的超集时，如何解决merge冲突并保留超集版本
---

# Merge: Feature Branch is Superset of Remote

## When to Use

当合并feature分支到master时，remote已经收到新的commit，你的feature分支是**超集**（包含remote所有新commit + 你自己的新功能）。

典型场景：
- 你的feature分支对某文件做了完全重写，remote同期也修改了同一文件
- 你的分支index.html从1490行变成2545行（包含了remote的改动作为子集）
- 自动合并失败，出现大量conflict标记

## 操作步骤

```bash
# 1. 切到目标分支（通常是master）
git checkout master

# 2. 合并remote最新代码
git fetch origin
git merge origin/master
# 自动合并会失败

# 3. 确认你的分支是超集
# 检查conflict文件数和标记数量
grep -n "<<<<<<\|======\|>>>>>>" index.html

# 4. 如果确认是超集，使用 --ours
git checkout --ours index.html
git add index.html
git commit -m "merge: resolve conflicts, keep V2 superset" --no-edit

# 5. 推送
git push origin master
```

## 验证步骤

```bash
# 确认关键功能还在
grep -n "KEY_FEATURE\|worlds\|SAVE_KEY" index.html

# 确认remote的新功能也在（如果超集包含了它们）
grep -n "remote_feature_name" index.html
```

## 何时不用

- remote有你的分支不包含的改动（真冲突）
- 双方独立修改了不同section但都有效（需要手动合并）
- 不确定时：先看冲突标记，判断是否真的所有冲突都是"我的包含他的"

## 真实案例

```
Remote master cb505a0:
  - feat: add stats, high score, particles, expressions, trees, flowers, pause
  - feat: add mole types (golden+bomb) + power-ups + combo system

Feature V2 fbd1078:
  - V2重写了index.html（1490→2545行）
  - V2代码本身已经包含了remote的所有新功能
  - 冲突标记只有4处，都是样式/meta标签差异

解决：git checkout --ours index.html → 保留V2，remote功能自动在内
```

## 相关

- `git-push-via-temp-branch-when-fetch-times-out`: WSL git push超时解决方案
- 常规merge冲突（非超集场景）: 需要手动逐个解决`<<<<<<`标记
