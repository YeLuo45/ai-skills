---
name: wslinux-dns-failure-workaround
description: WSL DNS failure workaround for GitHub operations — when github.com cannot be resolved but network connectivity exists
category: devops
---

# WSL DNS Failure Workaround for GitHub Operations

## Problem
WSL DNS completely fails (cannot resolve github.com), but network connectivity exists:
- `ping github.com` → fail
- `curl https://api.github.com/...` → may work if using IP directly
- `git push` → blocks on DNS resolution

## Symptoms
- DNS resolution completely down: `getent hosts github.com` returns empty
- curl works with IP: `curl -k https://140.82.121.35/...`
- ping fails completely: `ping github.com` → "Name or service not known"

## Verified Workarounds (in order of preference)

### 0. Check DNS failure severity first
```bash
# Check if DNS completely fails (no resolution at all)
getent hosts github.com
# If empty, DNS is completely down

# Check if curl with IP works (partial DNS failure - DNS down but network works)
curl -s --max-time 5 https://140.82.121.35/ 2>&1 | head
# If this works, REST API workaround will work
# If "Could not resolve host" even for IP, ALL network is down
```

### 1. GitHub REST API with curl (only works when DNS fails but direct IP works)
```bash
# Get current tree
curl -s https://api.github.com/repos/YeLuo45/flight-chess-3d/git/trees/main?recursive=1 \
  -H "Authorization: token ghp_..." | jq -r '.tree[].path'

# Create file via API (base64 encode content first)
CONTENT=$(base64 -w0 < file.txt)
curl -X PUT https://api.github.com/repos/YeLuo45/flight-chess-3d/contents/path/file.txt \
  -H "Authorization: token ghp_..." \
  -d "{\"message\":\"commit msg\",\"content\":\"$CONTENT\"}"
```

**IMPORTANT**: This only works when DNS fails but direct IP connectivity works. If `curl https://140.82.121.35/` fails with "Could not resolve host", even the REST API is unreachable. In that case, only option is to commit locally and wait for network recovery.

### 2. Direct IP workaround for git
Add to `/etc/hosts`:
```
140.82.121.35 github.com
```
Then git operations may work.

### 3. GitHub CLI (gh)
May bypass DNS issues:
```bash
gh auth login
gh repo clone YeLuo45/flight-chess-3d
```

### 4. Manual Windows-side push
Tell user to run in Windows CMD:
```bash
cd %USERPROFILE%\.hermes\workspace-dev\proposals\flight-chess-3d
git push origin main --force
```

## Key Files Affected
- flight-chess-3d project: `~/.hermes/proposals/workspace-dev/proposals/flight-chess-3d/`
- GitHub repo: `https://github.com/YeLuo45/flight-chess-3d` (empty, needs push)
- dist/ is ready and build succeeds

## Prevention
- When DNS fails, try `curl --max-time 5 https://140.82.121.35/` first to confirm connectivity
- If curl with IP fails, REST API will also fail - only option is commit locally and wait
- If curl with IP works, REST API workaround will work
- Always check `git remote -v` to confirm remote is set correctly
- git push --force can be used since remote is empty

## Session Learning (2026-05-02)
When DNS completely fails (socket.gaierror: [Errno -3] Temporary failure in name resolution), even urllib.request.urlopen() to api.github.com fails. This is different from when only Git HTTPS is blocked. In this case, local commit is the only option.
