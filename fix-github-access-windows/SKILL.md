---
name: fix-github-access-windows
description: Use when working on Windows with PowerShell and GitHub is slow, unavailable, images fail to load, clone/raw access hangs, or hosts and SwitchHosts should be used to restore access.
---

# Fix GitHub Access on Windows

## When To Use

- Windows + PowerShell environment
- `github.com` opens slowly or times out
- `api.github.com` or `raw.githubusercontent.com` is unstable
- GitHub images are broken
- `git clone` / raw file fetches are slow because DNS or hosts mappings are stale

## Quick Start

1. Check basic connectivity first:
   - `Resolve-DnsName github.com`
   - `Test-NetConnection github.com -Port 443`
   - `curl.exe -I --connect-timeout 10 --max-time 20 https://api.github.com`
2. Prefer the maintained hosts source:
   - `https://raw.hellogithub.com/hosts`
3. Use the bundled script to update the managed GitHub block in Windows hosts:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\YeZhimin\.cursor\skills\fix-github-access-windows\scripts\update-github-hosts.ps1"
```

The script self-elevates, backs up the current hosts file, replaces only the `GitHub520` managed block, flushes DNS, and prints a connectivity summary.

## SwitchHosts Path

If the user specifically wants `SwitchHosts`:

1. Install it with `winget` when available:

```powershell
winget install --id oldj.switchhosts --exact --source winget --accept-source-agreements --accept-package-agreements --disable-interactivity --scope user
```

2. Run `SwitchHosts` as administrator.
3. Add a new rule:
   - Type: `Remote`
   - Title: `GitHub Hosts`
   - URL: `https://raw.hellogithub.com/hosts`
   - Auto Refresh: `1 hour`
4. Enable the rule, then refresh DNS if needed:

```powershell
ipconfig /flushdns
```

If `SwitchHosts` cannot be downloaded because `github.com` itself times out, fall back to the bundled PowerShell script first.

## Verification

Use these checks after updating:

```powershell
Resolve-DnsName github.com
Resolve-DnsName api.github.com
Resolve-DnsName raw.githubusercontent.com
Test-NetConnection github.com -Port 443
curl.exe -I --connect-timeout 10 --max-time 20 https://api.github.com
curl.exe -I --connect-timeout 10 --max-time 20 https://raw.githubusercontent.com
```

Notes:
- `api.github.com` and `raw.githubusercontent.com` are usually better machine-check targets than `https://github.com/`.
- If the GitHub homepage still hangs but API/raw access succeeds, report that clearly instead of claiming the entire site is fixed.

## Common Failures

- Access denied when writing `hosts`
  - Run elevated. The bundled script will re-launch with UAC.
- `SwitchHosts` says it cannot write `hosts`
  - Run `SwitchHosts` as administrator and verify `C:\Windows\System32\drivers\etc\hosts` is not read-only.
- Remote hosts source downloads but homepage still times out
  - Update the managed block anyway, flush DNS, and verify `api.github.com` / `raw.githubusercontent.com` separately.
- Download source is unreachable
  - Use `winget` if possible; otherwise rely on the PowerShell script with the default HelloGitHub source.
