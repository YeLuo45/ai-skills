---
name: wsltty-git-ssh-push
description: WSL git push via SSH when HTTPS times out — ssh-agent setup, known_hosts, and push workflow
version: 1.0.0
tags: ["git", "wsl", "ssh", "github"]
---

# WSL Git Push via SSH (When HTTPS Times Out)

## Problem

In WSL (tested on Ubuntu), `git push` over HTTPS times out consistently:
```
fatal: unable to access 'https://github.com/...': Empty reply from server
```
But SSH works.

## Solution: SSH Push Workflow

```bash
# 1. Start ssh-agent and add key
eval $(ssh-agent -s) && ssh-add ~/.ssh/github_hermes

# 2. Set remote to SSH URL (if currently HTTPS)
git remote set-url origin git@github.com:owner/repo.git

# 3. Push
git push

# 4. Restore HTTPS remote (optional, for consistency)
git remote set-url origin https://github.com/owner/repo.git
```

## One-liner (for scripted pushes)

```bash
(eval $(ssh-agent -s) && ssh-add ~/.ssh/github_hermes && git push)
```

## Key Points

- `eval $(ssh-agent -s)` MUST be in the same subshell/process as `ssh-add` and `git push` — setting env vars in a separate `export` call doesn't propagate to child processes
- SSH key at `~/.ssh/github_hermes` (RSA key, not default `id_rsa`)
- If `ssh -T git@github.com` fails with "Permission denied" even after ssh-add, the key isn't registered with GitHub — add it via GitHub Settings > SSH Keys

## 添加 GitHub 到 known_hosts

```bash
ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
```

不需要手动记录 fingerprint，每次连接时 SSH 会自动验证服务器 key。

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `Could not open a connection to your authentication agent` | ssh-agent not running | `eval $(ssh-agent -s)` first |
| `Permission denied (publickey)` | Key not registered with GitHub or not added | Check `ssh -T git@github.com` |
| `Host key verification failed` | github.com not in known_hosts | `ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts` |
| HTTPS push times out | Network/WSL DNS issue | Use SSH workflow above |
