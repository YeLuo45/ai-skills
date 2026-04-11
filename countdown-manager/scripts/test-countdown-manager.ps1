param()

$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $PSScriptRoot "countdown-manager.ps1"
$tempRoot = Join-Path $env:TEMP ("countdown-manager-test-" + [guid]::NewGuid().ToString())
$statePath = Join-Path $tempRoot "state.json"
$taskId = "test-task-001"

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

try {
    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

    if (-not (Test-Path $scriptPath)) {
        throw "Missing manager script: $scriptPath"
    }

    $createOutput = & $scriptPath `
        -Operation create `
        -StatePath $statePath `
        -Id $taskId `
        -Title "Test Countdown" `
        -Context "test-context" `
        -OwnerAgent "main" `
        -DurationMinutes 5 `
        -DefaultAction "approve_by_timeout"

    $createResult = $createOutput | ConvertFrom-Json
    Assert-True ($createResult.status -eq "active") "Create did not return active status."

    $queryOutput = & $scriptPath -Operation query -StatePath $statePath -Id $taskId
    $queryResult = $queryOutput | ConvertFrom-Json
    Assert-True ($queryResult.id -eq $taskId) "Query did not return the expected task."

    $remindOutput = & $scriptPath -Operation remind -StatePath $statePath -Id $taskId
    $remindResult = $remindOutput | ConvertFrom-Json
    Assert-True ($remindResult.status -eq "active") "Remind should keep an active task active before expiry."

    $closeOutput = & $scriptPath `
        -Operation close `
        -StatePath $statePath `
        -Id $taskId `
        -Resolution "user-confirmed"
    $closeResult = $closeOutput | ConvertFrom-Json
    Assert-True ($closeResult.status -eq "closed") "Close did not mark the task as closed."

    $deleteOutput = & $scriptPath -Operation delete -StatePath $statePath -Id $taskId
    $deleteResult = $deleteOutput | ConvertFrom-Json
    Assert-True ($deleteResult.status -eq "deleted") "Delete did not mark the task as deleted."

    Write-Output "PASS: countdown-manager create/query/remind/close/delete"
}
finally {
    if (Test-Path $tempRoot) {
        Remove-Item -Recurse -Force $tempRoot
    }
}
