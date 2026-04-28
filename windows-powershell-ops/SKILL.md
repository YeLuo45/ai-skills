---
name: windows-powershell-ops
description: Execute Windows-safe PowerShell workflows for downloads, installers, archives, and troubleshooting. Use when the environment is Windows, the shell is PowerShell, the user mentions .ps1, winget, 7-Zip, installer automation, encoding issues, or download failures.
---

# Windows PowerShell Ops

## Use This Skill

Apply this skill when working on Windows hosts where commands must run in PowerShell rather than bash.

## Default Workflow

1. Prefer PowerShell-native syntax and cmdlets.
2. Verify parent directories before creating files or folders.
3. Quote Windows paths with double quotes.
4. For downloads, create the target directory first, then save into a deterministic filename.
5. Validate the result after download with `Get-Item` and check size or existence.
6. For archive extraction, confirm the required extractor exists before downloading large assets when practical.
7. After installation, verify the final executable path and show the launch command.

## Command Conventions

- Use `Invoke-WebRequest`, `Invoke-RestMethod`, `Start-Process`, `Get-Item`, `Test-Path`, `Join-Path`.
- Use `curl.exe` only as a fallback, not PowerShell's `curl` alias.
- Use `powershell -NoProfile -ExecutionPolicy Bypass -File "script.ps1"` for script execution.
- Use `Start-Process -Wait -PassThru` for installers so exit codes can be checked.
- When UAC may appear, tell the user explicitly.

## Encoding And Script Safety

- Default to ASCII in `.ps1` files unless non-ASCII is required.
- If a script contains Chinese or other non-ASCII text and must run in Windows PowerShell 5.1, save it as UTF-8 with BOM.
- If encoding may be unreliable, prefer English log messages inside scripts.

## PowerShell Pitfalls

- Wrap pipeline results in `@(...)` before indexing. A single string result is scalar, and `[0]` returns its first character.
- Example:

```powershell
$items = @(
    @("C:\Program Files\7-Zip\7z.exe") | Where-Object { $_ -and (Test-Path $_) }
)
$first = $items[0]
```

- Do not assume `winget` exists on Windows 10.
- If `winget` is missing, fall back to vendor installers or direct download pages.
- Set TLS explicitly before older PowerShell web requests:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```

## Download And Install Troubleshooting

- If `Invoke-WebRequest` fails, capture the exact error and test whether the host is reachable.
- Distinguish between network failure, path failure, permission failure, and extractor failure.
- If the environment cannot reach the source host, prepare a local script the user can run on a machine with access.
- When a large asset download succeeds, avoid re-downloading it on retries.

## Archive Handling

- `.7z` usually requires `7z.exe`; verify `C:\Program Files\7-Zip\7z.exe` and `C:\Program Files (x86)\7-Zip\7z.exe`.
- Extract with:

```powershell
& "C:\Program Files\7-Zip\7z.exe" x "archive.7z" "-oC:\target" -y
```

- After extraction, locate the real executable recursively because many archives contain one extra top-level folder.

## Response Pattern

When reporting completion:

1. State what was downloaded or installed.
2. State the exact executable or output path.
3. State the main issue encountered, if any.
4. State the fix applied.
