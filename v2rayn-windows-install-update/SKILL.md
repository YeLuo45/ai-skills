---
name: v2rayn-windows-install-update
description: Install or update v2rayN on Windows, especially the SelfContained and With-Core packages. Use when the user asks to install, upgrade, re-download, unpack, or launch v2rayN on Windows, or when a v2rayN release URL or asset filename is provided.
---

# v2rayN Windows Install And Update

## Use This Skill

Apply this skill for Windows installation or upgrade tasks involving `v2rayN`, especially:

- release URLs such as `https://github.com/2dust/v2rayN/releases/...`
- assets like `v2rayN-windows-64-SelfContained-With-Core.7z`
- requests to update to the latest stable or latest prerelease

## Default Choices

- Default asset: `v2rayN-windows-64-SelfContained-With-Core.7z`
- Default install root: `C:\Users\<user>\Apps\v2rayN`
- Prefer versioned folders so upgrades do not overwrite older installs immediately.
- Verify `v2rayN.exe` after extraction and return its exact path.

## Workflow

1. Confirm Windows + PowerShell environment.
2. Decide the target version:
   - explicit version from the user
   - latest stable
   - latest prerelease
3. Ensure `7z.exe` is available, or install 7-Zip if the user allows it.
4. Download the selected release asset.
5. Extract into a versioned directory.
6. Find `v2rayN.exe` recursively because the archive may contain an extra folder layer.
7. Optionally launch the app.
8. Report the installed version, archive path, and executable path.

## Update Rules

- Use the same script for fresh install and update.
- For explicit versions, install into `<InstallRoot>\<version>`.
- For latest stable or latest prerelease, resolve the version from GitHub API first, then install into that versioned folder.
- Reuse an existing archive unless the user requests a forced re-download.
- Do not delete older installed versions unless the user explicitly asks.

## Script

Use the bundled script:

`scripts/install-or-update-v2rayn.ps1`

## Recommended Commands

Install an explicit version:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\18332\.cursor\skills\v2rayn-windows-install-update\scripts\install-or-update-v2rayn.ps1" -Version "7.0.1" -AutoInstall7Zip
```

Update to latest stable:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\18332\.cursor\skills\v2rayn-windows-install-update\scripts\install-or-update-v2rayn.ps1" -LatestStable -AutoInstall7Zip
```

Update to latest prerelease and launch:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\Users\18332\.cursor\skills\v2rayn-windows-install-update\scripts\install-or-update-v2rayn.ps1" -LatestPrerelease -AutoInstall7Zip -Launch
```

## If Download Fails

- Confirm whether the machine can access `github.com`.
- If GitHub is blocked, report the exact failing host and keep any already-downloaded archive.
- If 7-Zip auto-install fails, tell the user to install 7-Zip manually from the official site and rerun the script.
