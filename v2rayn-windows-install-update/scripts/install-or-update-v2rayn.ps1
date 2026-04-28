param(
    [string]$Version,
    [switch]$LatestStable,
    [switch]$LatestPrerelease,
    [string]$AssetName = "v2rayN-windows-64-SelfContained-With-Core.7z",
    [string]$InstallRoot = "$env:USERPROFILE\Apps\v2rayN",
    [string]$SevenZipInstallerUrl = "https://www.7-zip.org/a/7z2600-x64.exe",
    [switch]$AutoInstall7Zip,
    [switch]$Launch,
    [switch]$ForceRedownload
)

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Get-SevenZip {
    $cmd = Get-Command "7z" -ErrorAction SilentlyContinue
    $fromPath = if ($cmd) { $cmd.Source } else { $null }
    $candidates = @(
        @(
            $fromPath,
            "${env:ProgramFiles}\7-Zip\7z.exe",
            "${env:ProgramFiles(x86)}\7-Zip\7z.exe"
        ) | Where-Object { $_ -and (Test-Path $_) }
    )
    if ($candidates.Count -gt 0) { return $candidates[0] }
    return $null
}

function Install-SevenZipSilent {
    param([string]$Url)

    $installerPath = Join-Path $env:TEMP "7zip-installer.exe"
    Write-Host "[7-Zip] Downloading: $Url"
    Invoke-WebRequest -Uri $Url -OutFile $installerPath -UseBasicParsing
    Write-Host "[7-Zip] Silent install starting. Approve UAC if prompted."
    $process = Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        throw "7-Zip installer exit code: $($process.ExitCode)"
    }
    Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
}

function Resolve-Version {
    if ($LatestStable -and $LatestPrerelease) {
        throw "Use only one of -LatestStable or -LatestPrerelease."
    }

    if ($Version) {
        return $Version
    }

    $headers = @{ "User-Agent" = "Cursor-Agent" }

    if ($LatestStable) {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/2dust/v2rayN/releases/latest" -Headers $headers
        return $release.tag_name
    }

    if ($LatestPrerelease) {
        $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/2dust/v2rayN/releases?per_page=10" -Headers $headers
        $release = $releases | Where-Object { -not $_.draft } | Select-Object -First 1
        if (-not $release) {
            throw "No non-draft release found from GitHub API."
        }
        return $release.tag_name
    }

    throw "Provide -Version, -LatestStable, or -LatestPrerelease."
}

function Ensure-SevenZip {
    $seven = Get-SevenZip
    if ($seven) { return $seven }

    if (-not $AutoInstall7Zip) {
        throw "7-Zip not found. Re-run with -AutoInstall7Zip or install 7-Zip manually."
    }

    Install-SevenZipSilent -Url $SevenZipInstallerUrl
    $seven = Get-SevenZip
    if (-not $seven) {
        throw "7-Zip installation finished but 7z.exe was not found."
    }
    return $seven
}

$resolvedVersion = Resolve-Version
$sevenZipPath = Ensure-SevenZip

$downloadsDir = Join-Path $InstallRoot "downloads"
$archivePath = Join-Path $downloadsDir ("{0}-{1}" -f $resolvedVersion, $AssetName)
$extractRoot = Join-Path $InstallRoot $resolvedVersion
$downloadUrl = "https://github.com/2dust/v2rayN/releases/download/$resolvedVersion/$AssetName"

New-Item -ItemType Directory -Path $downloadsDir -Force | Out-Null
New-Item -ItemType Directory -Path $extractRoot -Force | Out-Null

if ($ForceRedownload -or -not (Test-Path $archivePath) -or (Get-Item $archivePath).Length -lt 1MB) {
    Write-Host "[v2rayN] Downloading: $downloadUrl"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $archivePath -UseBasicParsing -Headers @{ "User-Agent" = "Cursor-Agent" }
} else {
    Write-Host "[v2rayN] Reusing existing archive: $archivePath"
}

Write-Host "[v2rayN] Extracting to: $extractRoot"
& $sevenZipPath x $archivePath "-o$extractRoot" -y | Out-Null

$exe = Get-ChildItem -Path $extractRoot -Filter "v2rayN.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $exe) {
    throw "Extraction completed but v2rayN.exe was not found under $extractRoot"
}

$metadataPath = Join-Path $InstallRoot "latest-installed.txt"
$metadata = @(
    "version=$resolvedVersion"
    "asset=$AssetName"
    "archive=$archivePath"
    "exe=$($exe.FullName)"
)
Set-Content -Path $metadataPath -Value $metadata -Encoding ASCII

Write-Host "[v2rayN] Version: $resolvedVersion"
Write-Host "[v2rayN] Archive: $archivePath"
Write-Host "[v2rayN] Executable: $($exe.FullName)"
Write-Host "[v2rayN] Metadata: $metadataPath"

if ($Launch) {
    Start-Process -FilePath $exe.FullName
}
