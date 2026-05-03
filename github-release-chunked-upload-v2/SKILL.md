---
name: github-release-chunked-upload-v2
description: Upload large files to GitHub Releases in chunks via cron — dynamic token, stale cache avoidance, delete+retry on already_exists
triggers: [github, release, upload, large-file, chunked, exe, binary, already_exists]
tags: [github, devops, upload, release, cron]
---

# GitHub Release Chunked File Upload (v2)

## When to Use
Upload large files (>100MB) to a GitHub Release as chunks, running one chunk per cron invocation. Handles API unreliability, stale cache inconsistencies, and `already_exists` errors correctly.

## Prerequisites
- `gh` CLI authenticated: `gh auth login`
- File split into ~5MB chunks in a directory
- Target release already created

## Quick Reference

| Scenario | Action |
|----------|--------|
| Chunk upload returns `HTTP:201` in status line | Success, move to next |
| Chunk upload returns `HTTP:201` + `already_exists` in body | **SUCCESS** — do NOT retry/delete |
| Chunk upload returns `HTTP:422` + `already_exists` | Find ID via tag API → delete → retry |
| API query returns stale/empty list | Use `/releases/tags/{tag}` not `/releases/{id}/assets` |
| Token unavailable | Always use `gh auth token` dynamically |
| `gh release upload` hangs | Use curl POST instead |

## Upload Script Template

```python
#!/usr/bin/env python3
"""Upload one chunk to GitHub Release. Cron runs this repeatedly."""
import subprocess, os, json, time

REPO = "OWNER/REPO"
RELEASE_ID = "310710320"
CHUNK_DIR = "/tmp/chunks"
LOG = "/tmp/upload-log.txt"

def log(msg):
    with open(LOG, "a") as f:
        f.write(f"{msg}\n")
    print(msg)

def get_token():
    """Always get token dynamically — never embed a PAT."""
    r = subprocess.run(["gh", "auth", "token", "--hostname", "github.com"],
                       capture_output=True, text=True, timeout=10)
    return r.stdout.strip()

def get_uploaded_names():
    """Use /releases/tags/TAG endpoint, NOT /releases/{ID}/assets.
    Assets created via uploads.github.com may not appear immediately under the
    release ID endpoint, but ARE visible via the tag endpoint.
    """
    r = subprocess.run(
        ["gh", "api", f"repos/{REPO}/releases/tags/v1.0.0",
         "--jq", ".assets[] | select(.name | contains(\"YOUR_PREFIX\")) | .name"],
        capture_output=True, text=True, timeout=20)
    if r.returncode != 0:
        return []
    return [l for l in r.stdout.strip().split("\n") if l.strip()]

def delete_asset_by_name(token, name):
    """Find asset ID by name from the tag endpoint, then delete it by ID."""
    r = subprocess.run(
        ["gh", "api", f"repos/{REPO}/releases/tags/v1.0.0",
         "--jq", f".assets[] | select(.name == \"{name}\") | .id"],
        capture_output=True, text=True, timeout=15)
    asset_id = r.stdout.strip()
    if not asset_id:
        log(f"  delete_asset_by_name: asset '{name}' not found in tag API")
        return False
    dr = subprocess.run(
        ["curl", "-s", "-X", "DELETE", "--max-time", "10",
         "-H", f"Authorization: token {token}",
         f"https://api.github.com/repos/{REPO}/releases/assets/{asset_id}"],
        capture_output=True, text=True, timeout=15)
    return dr.returncode == 0

def upload_chunk(token, i, path):
    """Upload one chunk via curl. Returns True on success."""
    name = f"YourFile.part{i:03d}"
    size = os.path.getsize(path) / 1024 / 1024
    log(f"[{i}] Uploading {name} ({size:.1f}MB)...")

    r = subprocess.run(
        ["curl", "-s", "-w", "\nHTTP:%{http_code}",
         "-X", "POST",
         "-H", f"Authorization: token {token}",
         "-H", "Content-Type: application/octet-stream",
         "--upload-file", path,
         "--max-time", "240",
         f"https://uploads.github.com/repos/{REPO}/releases/{RELEASE_ID}/assets?name={name}"],
        capture_output=True, text=True, timeout=260)

    # HTTP status is ALWAYS on a separate line at the end (after \n from -w).
    # NEVER check for already_exists before verifying the HTTP status line,
    # because GitHub sometimes returns HTTP 201 + already_exists in body
    # when the asset was actually created successfully.
    http_marker = r.stdout.split('\n')[-1] if '\n' in r.stdout else r.stdout

    if 'HTTP:201' in http_marker:
        log(f"  SUCCESS")
        return True

    if 'HTTP:422' in http_marker and "already_exists" in r.stdout:
        log(f"  Already exists — deleting and retrying...")
        delete_asset_by_name(token, name)
        time.sleep(1)
        r = subprocess.run(
            ["curl", "-s", "-w", "\nHTTP:%{http_code}",
             "-X", "POST",
             "-H", f"Authorization: token {token}",
             "-H", "Content-Type: application/octet-stream",
             "--upload-file", path,
             "--max-time", "240",
             f"https://uploads.github.com/repos/{REPO}/releases/{RELEASE_ID}/assets?name={name}"],
            capture_output=True, text=True, timeout=260)
        http_marker2 = r.stdout.split('\n')[-1] if '\n' in r.stdout else r.stdout
        if 'HTTP:201' in http_marker2:
            log(f"  SUCCESS (retry)")
            return True
        log(f"  FAILED (retry): {r.stdout[:200]}")
        return False

    log(f"  FAILED: {r.stdout[:200]}")
    return False

def main():
    token = get_token()
    if not token:
        log("ERROR: no token")
        return

    uploaded = set(get_uploaded_names())
    log(f"Uploaded: {len(uploaded)}")

    for i in range(100):  # adjust range to total chunks
        name = f"YourFile.part{i:03d}"
        path = f"{CHUNK_DIR}/part_{i:03d}"
        if name in uploaded or not os.path.exists(path):
            continue
        upload_chunk(token, i, path)
        break  # one per run

    # Progress
    names = get_uploaded_names()
    log(f"Progress: {len(names)}/TOTAL")

if __name__ == "__main__":
    main()
```

## One Chunk Per Invocation — Script Design Pattern

This script is designed to **exit after uploading one chunk**. The cron/job wrapper must loop:
```bash
# Correct: run in a loop, one chunk per invocation
for i in $(seq 1 34); do
  python3 upload-exe-chunks.py >> /tmp/upload-log.txt 2>&1
  sleep 2
done

# Wrong: expecting the script to drain all chunks in one run
python3 upload-exe-chunks.py  # exits after ONE chunk
```

The script's `for i in range(34): ... break` structure means it finds the first missing chunk, uploads it, then exits. This is intentional for cron reliability (each cron tick = one chunk).

## Important Lessons (from production debugging)

### `curl -w "\nHTTP:%{http_code}"` — HTTP status is ALWAYS on a separate line
The `-w "HTTP:%{http_code}"` flag appends the status on a **new line at the end** of stdout.
When checking the response, you MUST extract and check the HTTP status line FIRST:

```python
# CORRECT: extract the last line for HTTP status check
http_marker = r.stdout.split('\n')[-1] if '\n' in r.stdout else r.stdout
if 'HTTP:201' in http_marker:
    log("SUCCESS")

# WRONG: checking already_exists before isolating HTTP status causes false failures
if "already_exists" in r.stdout:  # DON'T do this without checking HTTP first
```

### GitHub upload API: HTTP 201 + already_exists = SUCCESS (don't retry/delete)
GitHub's upload API sometimes returns **HTTP 201 with `already_exists` in the JSON body**.
This means the asset **was actually created successfully** — the error is informational only.
**Always check `HTTP:201` in the status line before considering any other outcome.**

```python
http_marker = r.stdout.split('\n')[-1]
if 'HTTP:201' in http_marker:
    return True  # Success regardless of already_exists in body
elif 'HTTP:422' in http_marker and "already_exists" in r.stdout:
    # Only here should you delete and retry
```

### Use `/releases/tags/{tag}` NOT `/releases/{id}/assets` for enumeration and deletion
Assets created via `uploads.github.com` may take minutes to appear under the release ID
endpoint, but ARE immediately visible under the tag endpoint:
```bash
# Stale (may miss recent uploads):
gh api repos/OWNER/REPO/releases/RELEASE_ID/assets --jq '.[] | .name'
# Correct source of truth:
gh api repos/OWNER/REPO/releases/tags/v1.0.0 --jq '.assets[] | .name'
```
For deletion, also use the tag endpoint to find the asset ID.

### `gh release view --json` is unreliable for asset state
`gh release view TAG --json assets` returns cached data. Always use `gh api` for state verification.

### `gh release upload` CLI hangs on large files
`gh release upload TAG file --clobber` has no client-side timeout and can hang forever.
Use curl POST to `uploads.github.com` with `--max-time 240` instead.

### Splitting and verification commands
```bash
# Split into 5MB chunks
split -b 5M -d largefile.zip largefile.zip.part
# Produces: largefile.zip.part000, largefile.zip.part001, ...

# Verify all chunks uploaded (source of truth — use tag endpoint):
gh api repos/OWNER/REPO/releases/tags/v1.0.0 --jq '.assets[] | select(.name | contains("YOUR_PREFIX")) | .name' | wc -l

# Check specific chunk:
gh api repos/OWNER/REPO/releases/tags/v1.0.0 --jq '.assets[] | select(.name | contains("part030")) | .name'
```
