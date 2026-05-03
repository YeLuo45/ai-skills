---
name: wsl-github-ssh-push
description: WSL GitHub push via SSH when HTTPS fails — fix host key verification and use existing SSH key
version: 1.0.0
author: 小墨
license: MIT
tags: ["wsl", "git", "github", "ssh", "push"]
---

# WSL GitHub SSH Push

When `git push` via HTTPS times out or fails with "Empty reply from server" in WSL, fall back to SSH using the existing SSH key.

## The Problem

```bash
git push -u origin feature/xxx
# fatal: unable to access 'https://github.com/owner/repo.git/': Empty reply from server
# or: Connection timed out after N ms
```

## The Root Cause

WSL network sometimes blocks or times out HTTPS connections to GitHub, even though:
1. `curl https://api.github.com` works (HTTPS API works)
2. SSH connections to GitHub work

Additionally, `known_hosts` may contain a stale/fake entry for `github.com` causing "Host key verification failed" when using SSH.

## Step-by-step Solution

### 1. Check if SSH key exists

```bash
ls -la ~/.ssh/github_hermes*
# Expected: github_hermes (private) and github_hermes.pub (public)
```

### 2. Fix known_hosts

Remove the stale entry and fetch the real GitHub host key:

```bash
# Remove old/stale github.com entry
grep -v github.com ~/.ssh/known_hosts > /tmp/known_hosts_tmp && mv /tmp/known_hosts_tmp ~/.ssh/known_hosts

# Add real GitHub RSA host key
ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts 2>/dev/null
```

### 3. Push via SSH

```bash
cd /path/to/repo
GIT_SSH_COMMAND="ssh -i ~/.ssh/github_hermes -o ConnectTimeout=10" git push -u origin feature/xxx
```

### 4. (Optional) Restore HTTPS as remote URL

If you prefer to keep HTTPS as the default (so `git pull` etc. still work):

```bash
git remote set-url origin https://github.com/owner/repo.git
```

## Why not just use the REST API?

GitHub's `POST /repos/:owner/:repo/git/refs` creates a ref **pointing to an existing commit SHA**. If the commit only exists locally and hasn't been pushed, the API returns `422 Object does not exist`. The REST API cannot push commits — it only creates pointers to already-pushed objects.

## Verification

```bash
# SSH test (optional)
ssh -i ~/.ssh/github_hermes -o ConnectTimeout=10 git@github.com
# Expected: "Hi YeLuo45! You've successfully authenticated..." but PTY not allocated warning is OK

# Push verification
git log -1 --oneline
# Should show your latest commit SHA
```

## Key Files

| File | Purpose |
|------|---------|
| `~/.ssh/github_hermes` | Private SSH key for GitHub |
| `~/.ssh/github_hermes.pub` | Public SSH key (already added to GitHub) |
| `~/.ssh/known_hosts` | Must contain real github.com host key |

## Gotchas

- The `ssh-askpass` error during push is a false alarm — push actually succeeds. The message appears because SSH tries to ask for a passphrase but there's no TTY.
- `ssh-keyscan` requires network access — if it fails, the machine may have no internet at all.
- If `~/.ssh/github_hermes` doesn't exist, generate one: `ssh-keygen -t rsa -f ~/.ssh/github_hermes -C "your_email"` and add the public key to GitHub Settings → SSH Keys.
