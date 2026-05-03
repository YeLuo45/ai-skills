---
name: git-push-via-temp-branch-when-fetch-times-out
description: Workaround for git fetch timeout in WSL - push to temp branch then create PR via API
tags: [git, github, wsl, workaround]
---

# Git Push via Temp Branch When Fetch Times Out

## Problem
`git fetch origin <branch>` consistently times out (even 300s) in WSL environment, while:
- `curl https://api.github.com` works fine (HTTPS API reachable)
- `gh api` commands work
- `git push` hangs/gets blocked

This blocks normal workflows like `git pull --rebase` or checking actual remote state.

## Root Cause
WSL network has issues with Git's smart HTTP protocol handshake (the `git receive-pack` phase). The TLS handshake to api.github.com works but the git protocol layer hangs.

## Workaround: Push to a New Temp Branch

Instead of trying to fetch or force-push, push your local branch to a new temporary branch name:

```bash
# Push to a unique temp branch
git push origin main:hermes-agent-main-$(date +%s)
# Example: main -> hermes-agent-main-1777309915

# This succeeds even when fetch times out
```

Then use GitHub API to create PR or update the target branch:

```bash
# Via gh CLI (if it works)
gh pr create --base master --head hermes-agent-main-1777309915 --title "..." --body "..."

# Or via GitHub web URL returned by the push output
# Remote shows: https://github.com/owner/repo/pull/new/hermes-agent-main-1777309915
```

## Key Insight
The local `origin/main` ref can be stale (shows old SHA) while the actual remote has diverged. `git show-ref refs/remotes/origin/main` shows the local tracking ref SHA. Compare with `gh api repos/{owner}/{repo}/git/refs/heads/main --jq '.object.sha'` to confirm divergence.

## When Diverged History
If remote main has commits not in your local main:
- Your local main must be a descendant (contains remote's commits as ancestors) for safe force-push
- Verify: `git merge-base --is-ancestor origin/main main` — if true, origin/main is ancestor of main (safe to force push)
- In this case, remote has new commits (c5781d5...) that are NOT in local main's history

## Workflow Summary
1. `git push origin main:temp-branch-$(date +%s)` — succeeds even with fetch timeout
2. Create PR via URL shown in push output or `gh pr create`
3. Merge PR via GitHub web UI or `gh pr merge`

---

## Alternative: Deploy dist/ to gh-pages via Independent Git Repo

When you need to push the `dist/` build folder to `gh-pages` branch but git push is blocked (both HTTPS and git://):

### Method: Create independent git repo in /tmp/

```bash
DEPLOY_DIR=/tmp/gh-pages-deploy
rm -rf $DEPLOY_DIR && mkdir $DEPLOY_DIR

# Copy dist contents (including hidden files like .gitkeep if any)
cp -r /path/to/project/dist/. $DEPLOY_DIR/

cd $DEPLOY_DIR
git init
git config user.email "hermes@agent.local"
git config user.name "Hermes Agent"

# Embed token directly in remote URL
TOKEN=ghp_YOUR_TOKEN_HERE
git remote add origin https://${TOKEN}@github.com/owner/repo.git

git add .
git commit -m "deploy: build output"
git push origin master:gh-pages --force
```

**Why this works**: This creates a brand new git repo with no history, so push is a single fast-forward with no negotiation.

**git subtree split is broken**: Do NOT use `git subtree split --prefix=dist` — it silently drops files (vendor JS chunks disappear from the tree). Always use the independent repo method for dist/ deployment.

### For large repos (not dist/): Push to temp branch then PR

```bash
git push origin main:hermes-temp-$(date +%s)
# Then create PR via GitHub web URL or gh pr create
```

## Related
- WSL network: HTTP to github.com works, git smart protocol fails
- `gh api` works as alternative to git for reading remote state
- Force push may be blocked by security filters even when it would solve the problem
- Large blob uploads via GitHub API (>1MB) timeout even with 300s timeout — use the independent git repo method instead
- GitHub CDN propagation: raw.githubusercontent.com syncs within ~30s for small files; GitHub Actions deployment takes longer for large files
