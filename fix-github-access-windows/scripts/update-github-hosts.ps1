param(
    [string[]]$SourceUrls = @(
        "https://raw.hellogithub.com/hosts"
    ),
    [string]$HostsPath = "C:\Windows\System32\drivers\etc\hosts",
    [string]$BackupDir = "",
    [string]$LogPath = "$env:TEMP\update-github-hosts.log",
    [switch]$InstallSwitchHosts,
    [switch]$SkipDnsFlush,
    [switch]$SkipVerify
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Write-Log {
    param(
        [string]$Message
    )

    $directory = Split-Path -Parent $LogPath
    if ($directory) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogPath -Value "[$timestamp] $Message"
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-ArgumentList {
    $parts = @(
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", "`"$PSCommandPath`""
    )

    foreach ($entry in $PSBoundParameters.GetEnumerator()) {
        if ($entry.Value -is [switch]) {
            if ($entry.Value.IsPresent) {
                $parts += "-$($entry.Key)"
            }
            continue
        }

        if ($entry.Value -is [System.Array]) {
            foreach ($item in $entry.Value) {
                $parts += "-$($entry.Key)"
                $parts += "`"$item`""
            }
            continue
        }

        $parts += "-$($entry.Key)"
        $parts += "`"$($entry.Value)`""
    }

    return ($parts -join " ")
}

function Ensure-Administrator {
    if (Test-IsAdministrator) {
        Write-Log "Running with administrator privileges."
        return
    }

    Write-Host "Elevation required. Re-launching as administrator..."
    Write-Log "Elevation required. Launching elevated PowerShell."
    $argumentList = Get-ArgumentList
    $process = Start-Process -FilePath "powershell.exe" -ArgumentList $argumentList -Verb RunAs -PassThru -Wait
    if ($null -ne $process -and $process.ExitCode -ne 0) {
        Write-Log "Elevated process exited with code $($process.ExitCode)."
        throw "Elevated run failed with exit code $($process.ExitCode)."
    }
    Write-Log "Elevated process completed successfully."
    exit 0
}

function Get-BackupDirectory {
    if ($BackupDir) {
        return $BackupDir
    }

    $root = Split-Path -Parent $PSScriptRoot
    return (Join-Path $root "backups")
}

function Download-HostsBlock {
    param(
        [string[]]$Urls
    )

    $errors = @()
    foreach ($url in $Urls) {
        try {
            Write-Host "Downloading hosts from $url"
            $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 30
            $content = $response.Content
            if (-not $content) {
                throw "Remote hosts payload is empty."
            }

            if ($content -notmatch "# GitHub520 Host Start" -or $content -notmatch "# GitHub520 Host End") {
                throw "Remote hosts payload does not contain the GitHub520 markers."
            }

            return @{
                Url = $url
                Content = $content
            }
        } catch {
            $message = "$url -> $($_.Exception.Message)"
            $errors += $message
            Write-Warning $message
        }
    }

    throw "Failed to download hosts from all sources.`n$($errors -join "`n")"
}

function Update-ManagedBlock {
    param(
        [string]$CurrentContent,
        [string]$RemoteBlock
    )

    $normalizedBlock = ($RemoteBlock.TrimEnd("`r", "`n") + "`r`n")
    $pattern = "(?ms)^# GitHub520 Host Start\r?\n.*?^# GitHub520 Host End\r?\n?"

    if ([regex]::IsMatch($CurrentContent, $pattern)) {
        return [regex]::Replace($CurrentContent, $pattern, $normalizedBlock)
    }

    $prefix = $CurrentContent.TrimEnd("`r", "`n")
    if ($prefix.Length -eq 0) {
        return $normalizedBlock
    }

    return ($prefix + "`r`n`r`n" + $normalizedBlock)
}

function Backup-HostsFile {
    param(
        [string]$SourcePath,
        [string]$TargetDirectory
    )

    New-Item -ItemType Directory -Path $TargetDirectory -Force | Out-Null
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = Join-Path $TargetDirectory "hosts-$timestamp.bak"
    Copy-Item -Path $SourcePath -Destination $backupPath -Force
    return $backupPath
}

function Install-SwitchHostsIfRequested {
    if (-not $InstallSwitchHosts.IsPresent) {
        return
    }

    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if (-not $winget) {
        Write-Warning "winget was not found. Skipping SwitchHosts installation."
        return
    }

    Write-Host "Installing SwitchHosts with winget..."
    & $winget.Source install --id oldj.switchhosts --exact --source winget --accept-source-agreements --accept-package-agreements --disable-interactivity --scope user
}

function Show-VerifyResult {
    param(
        [string]$HostName
    )

    try {
        $dns = Resolve-DnsName -Name $HostName -ErrorAction Stop | Where-Object { $_.Type -eq "A" } | Select-Object -ExpandProperty IPAddress
        $tcp = Test-NetConnection -ComputerName $HostName -Port 443 -InformationLevel Detailed
        [pscustomobject]@{
            HostName = $HostName
            IPv4 = ($dns -join ", ")
            Tcp443 = [bool]$tcp.TcpTestSucceeded
        }
    } catch {
        [pscustomobject]@{
            HostName = $HostName
            IPv4 = "n/a"
            Tcp443 = $false
        }
    }
}

Write-Log "Script start. User=$env:USERNAME Admin=$(Test-IsAdministrator)"

try {
    Ensure-Administrator
    Install-SwitchHostsIfRequested

    $resolvedBackupDir = Get-BackupDirectory
    Write-Log "Using backup directory: $resolvedBackupDir"
    $downloaded = Download-HostsBlock -Urls $SourceUrls
    Write-Log "Downloaded hosts from: $($downloaded.Url)"
    $current = Get-Content -Path $HostsPath -Raw
    $backup = Backup-HostsFile -SourcePath $HostsPath -TargetDirectory $resolvedBackupDir
    Write-Log "Backup created: $backup"
    $updated = Update-ManagedBlock -CurrentContent $current -RemoteBlock $downloaded.Content

    $ascii = New-Object System.Text.ASCIIEncoding
    [System.IO.File]::WriteAllText($HostsPath, $updated, $ascii)
    Write-Log "Hosts file updated: $HostsPath"

    Write-Host "Hosts updated from $($downloaded.Url)"
    Write-Host "Backup saved to $backup"

    if (-not $SkipDnsFlush.IsPresent) {
        Write-Host "Flushing DNS cache..."
        ipconfig /flushdns | Out-Host
        Write-Log "DNS cache flushed."
    }

    if (-not $SkipVerify.IsPresent) {
        Write-Host ""
        Write-Host "Connectivity summary:"
        @(
            "github.com",
            "api.github.com",
            "raw.githubusercontent.com"
        ) | ForEach-Object { Show-VerifyResult -HostName $_ } | Format-Table -AutoSize | Out-Host
        Write-Log "Connectivity summary completed."
    }
} catch {
    Write-Log "ERROR: $($_.Exception.Message)"
    throw
}
