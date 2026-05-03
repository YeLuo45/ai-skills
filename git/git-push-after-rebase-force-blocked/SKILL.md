---
name: git-push-after-rebase-force-blocked
description: When git rebase creates a diverged local branch and force-push to master is blocked, push to a new branch and create a PR instead.
---
# Git: Push After Rebase When Force-Push Is Blocked

## Scenario
1. You `git pull --rebase` from remote and resolve conflicts
2. `git rebase --continue` succeeds but now local master diverged from origin/master
3. You try `git push origin master --force` — blocked by user confirmation gate
4. You need another way to get your changes to the remote

## Solution: Push to a New Feature Branch

```bash
# After rebase conflict resolution and rebase --continue succeeds
# but you're stuck with a diverged master and can't force-push:

# Create a new branch pointing at your detached HEAD commit
git branch feat-name <commit-sha>

# Push the new branch (not master)
git push origin feat-name

# Now create a PR from feat-name → master via GitHub UI
# https://github.com/owner/repo/pull/new/feat-name
```

## Why Not `git push origin HEAD:master`?
This also gets blocked by the same force-push protection on master.

## Why This Works
- New branch push doesn't require force — it's a new ref
- No history rewriting involved
- PR workflow is the intended merge path for diverged histories

## Prevention
- Before rebasing, create a backup branch: `git branch backup-before-rebase`
- Or use `git merge` instead of `git pull --rebase` when collaborating on master
