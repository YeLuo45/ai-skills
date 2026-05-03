---
name: git-selective-commit-dirty-wd
description: 在存在大量 untracked 文件的 git 工作目录中，如何只提交特定文件或目录
---

# Git Selective Commit in Dirty Working Directory

## Problem

When working in a git repository with many untracked files (like a skills directory with dozens of subdirectories), using `git add .` or `git add -A` will stage everything, which is usually not what you want.

## Solution

### Always use explicit paths

```bash
# ❌ Wrong - stages everything including untracked dirs
git add .

# ✅ Correct - only stages the specific file
git add path/to/file.md

# ✅ Correct - only stages files in a specific directory
git add skills/prj-proposal-management/
```

### When you accidentally staged everything

```bash
# Reset the index but keep working tree changes
git reset HEAD -- <path>  # unstage specific path
git reset HEAD -- .       # unstage everything
```

### When you made a commit with wrong content

```bash
# If commit is only on local branch (not pushed)
git reset HEAD~1 --hard   # completely remove the bad commit
# Then re-do your work correctly

# If commit was already pushed, you may need:
git revert <commit-sha>   # create a new commit that undoes the bad one
```

### Copy before stage anti-pattern

If you're copying files from one location to another (e.g., from `~/.hermes/skills/` to `~/.hermes/hermes-agent/skills/`):

```bash
# ❌ Don't rely on cp -r to update in-place if the file was modified
# ✅ Explicitly copy, then stage
cp ~/.hermes/skills/foo/SKILL.md ~/.hermes/hermes-agent/skills/foo/SKILL.md
git add skills/foo/SKILL.md
git commit -m "message"
```

## Common Scenario

You're on a feature branch and have:
- Modified files you DON'T want to commit
- New untracked directories you DON'T want to commit
- One specific file/directory you DO want to commit

```bash
# Verify what's staged
git status --short

# Stage only what you need
git add skills/prj-proposal-management/SKILL.md

# Commit
git commit -m "feat: update specific skill"

# Push
git push origin feature/branch-name
```

## Nested Directory Gotcha

When copying skill directories, you may accidentally create nested paths like:
```
skills/prj-proposal-management/prj-proposal-management/SKILL.md  # BAD
skills/prj-proposal-management/SKILL.md                           # GOOD
```

Always check `ls skills/<skill-name>/` before staging.

## Verification Commands

```bash
# See what would be committed (without actually staging)
git diff --cached --stat

# See staged changes
git diff --cached

# See what's staged vs unstaged
git status
```
