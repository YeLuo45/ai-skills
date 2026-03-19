---
name: backup-openclaw-data
description: Backup OpenClaw user data (~/.openclaw) to a timestamped folder. Use when the user asks to backup, save, export, or archive OpenClaw user data, configuration, credentials, sessions, or workspaces.
---

# Backup OpenClaw User Data

## Overview

OpenClaw user data resides at `~/.openclaw` (Windows: `%USERPROFILE%\.openclaw`). This skill backs up the entire directory to a timestamped folder using `robocopy`.

## Default Paths

| Item | Path |
|------|------|
| Source | `%USERPROFILE%\.openclaw` |
| Backup root | `E:\backup\openclaw` |
| Backup target | `E:\backup\openclaw\<yyyy-MM-dd>` |

If the user specifies a different backup root, use that instead.

## What Gets Backed Up

| Directory/File | Purpose |
|----------------|---------|
| `openclaw.json` | Main configuration |
| `.env` | Environment variables |
| `credentials/` | OAuth tokens, API keys, channel credentials |
| `agents/` | Agent configs, auth profiles, session transcripts |
| `workspace*/` | Agent workspaces (memory, skills, identity files) |
| `memory/` | Agent memory |
| `identity/` | Identity data |
| `browser/` | Browser extension data |
| `canvas/` | Live Canvas data |
| `cron/` | Scheduled tasks |
| `devices/` | Device registrations |
| `extensions/` | Extension data |
| `media/` | Media files |
| `subagents/` | Subagent data |
| `telegram/` | Telegram channel data |
| `*.json.bak*` | Config backups |

## Backup Procedure

### Step 1: Validate Paths

```powershell
$source = "$env:USERPROFILE\.openclaw"
$backupRoot = "E:\backup\openclaw"

if (-not (Test-Path $source)) { Write-Error "Source not found: $source"; return }
if (-not (Test-Path $backupRoot)) { New-Item -ItemType Directory -Path $backupRoot -Force }
```

### Step 2: Create Timestamped Folder

```powershell
$dateStr = Get-Date -Format 'yyyy-MM-dd'
$backupDir = Join-Path $backupRoot $dateStr
New-Item -ItemType Directory -Path $backupDir -Force
```

If a folder for today already exists and the user wants a second backup, append a sequence number: `yyyy-MM-dd_2`, `yyyy-MM-dd_3`, etc.

### Step 3: Copy Data with robocopy

```powershell
robocopy $source $backupDir /E /COPY:DAT /R:1 /W:1 /NP /NFL /NDL /NJH
```

Flags explained:
- `/E` — copy subdirectories including empty ones
- `/COPY:DAT` — copy Data, Attributes, Timestamps
- `/R:1 /W:1` — retry once, wait 1 second (avoid hanging on locked files)
- `/NP /NFL /NDL /NJH` — suppress progress, file list, dir list, job header for cleaner output

**robocopy exit codes**: 0 = no changes, 1 = files copied successfully, 2 = extra files in dest, 3 = 1+2. Codes 0-7 are success; 8+ indicates errors.

### Step 4: Verify

```powershell
Get-ChildItem $backupDir -Force | Format-Table Name, LastWriteTime, Length -AutoSize
```

Compare the listing against the source to confirm completeness.

### Step 5: Report

Summarize to the user:
- Backup location (full path)
- Number of files/directories copied (from robocopy summary)
- Total size
- Any errors or skipped files

## Restore (If Needed)

To restore from a backup:

```powershell
$backupDir = "E:\backup\openclaw\2026-03-20"
$target = "$env:USERPROFILE\.openclaw"
robocopy $backupDir $target /E /COPY:DAT /R:1 /W:1 /NP
```

**Warning**: Restoring will overwrite current user data. Recommend backing up current state first.

## Customization

The user may customize:
- **Backup root**: Change `E:\backup\openclaw` to any path
- **Date format**: Default is `yyyy-MM-dd`, can include time for multiple daily backups (`yyyy-MM-dd_HHmm`)
- **Exclude patterns**: Add `/XD` or `/XF` flags to robocopy to exclude specific dirs/files
