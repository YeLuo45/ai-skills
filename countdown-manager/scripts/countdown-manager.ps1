[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("create", "query", "remind", "close", "delete")]
    [string]$Operation,

    [string]$StatePath = (Join-Path (Split-Path $PSScriptRoot -Parent) "countdowns.json"),

    [string]$Id,
    [string]$Title,
    [string]$Context,
    [string]$OwnerAgent,
    [int]$DurationMinutes = 5,
    [string]$DefaultAction,
    [string]$Resolution,
    [string]$Note
)

$ErrorActionPreference = "Stop"

function Ensure-StateFile {
    param([string]$Path)

    $directory = Split-Path -Parent $Path
    if ($directory -and -not (Test-Path $directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }

    if (-not (Test-Path $Path)) {
        [pscustomobject]@{
            tasks = @()
        } | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding UTF8
    }
}

function Read-State {
    param([string]$Path)

    Ensure-StateFile -Path $Path
    $raw = Get-Content -Path $Path -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return [pscustomobject]@{ tasks = @() }
    }

    $state = $raw | ConvertFrom-Json
    if ($null -eq $state.tasks) {
        $state | Add-Member -NotePropertyName tasks -NotePropertyValue @()
    }
    return $state
}

function Write-State {
    param(
        [string]$Path,
        [object]$State
    )

    $State | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding UTF8
}

function Get-TasksArray {
    param([object]$State)

    $tasks = @()
    if ($null -ne $State.tasks) {
        $tasks = @($State.tasks)
    }
    return $tasks
}

function Find-TaskIndex {
    param(
        [array]$Tasks,
        [string]$TaskId
    )

    for ($i = 0; $i -lt $Tasks.Count; $i++) {
        if ($Tasks[$i].id -eq $TaskId) {
            return $i
        }
    }
    return -1
}

function Require-TaskId {
    param([string]$TaskId)

    if ([string]::IsNullOrWhiteSpace($TaskId)) {
        throw "Parameter -Id is required for operation."
    }
}

function Emit-Json {
    param([object]$Payload)

    $Payload | ConvertTo-Json -Depth 10 -Compress
}

$state = Read-State -Path $StatePath
$tasks = @(Get-TasksArray -State $state)
$now = Get-Date

switch ($Operation) {
    "create" {
        Require-TaskId -TaskId $Id

        if ([string]::IsNullOrWhiteSpace($Title)) {
            throw "Parameter -Title is required for create."
        }

        if ([string]::IsNullOrWhiteSpace($OwnerAgent)) {
            throw "Parameter -OwnerAgent is required for create."
        }

        if ([string]::IsNullOrWhiteSpace($DefaultAction)) {
            throw "Parameter -DefaultAction is required for create."
        }

        if ((Find-TaskIndex -Tasks $tasks -TaskId $Id) -ge 0) {
            throw "Countdown task already exists: $Id"
        }

        $deadline = $now.AddMinutes($DurationMinutes)
        $task = [pscustomobject]@{
            id               = $Id
            title            = $Title
            context          = $Context
            owner_agent      = $OwnerAgent
            created_at       = $now.ToString("o")
            deadline_at      = $deadline.ToString("o")
            duration_minutes = $DurationMinutes
            status           = "active"
            default_action   = $DefaultAction
            resolution       = $null
            note             = $Note
        }

        $tasks = @($tasks + $task)
        $state.tasks = $tasks
        Write-State -Path $StatePath -State $state
        Emit-Json -Payload $task
        break
    }

    "query" {
        if ([string]::IsNullOrWhiteSpace($Id)) {
            Emit-Json -Payload ([pscustomobject]@{ tasks = $tasks })
            break
        }

        $index = Find-TaskIndex -Tasks $tasks -TaskId $Id
        if ($index -lt 0) {
            throw "Countdown task not found: $Id"
        }

        Emit-Json -Payload $tasks[$index]
        break
    }

    "remind" {
        Require-TaskId -TaskId $Id
        $index = Find-TaskIndex -Tasks $tasks -TaskId $Id
        if ($index -lt 0) {
            throw "Countdown task not found: $Id"
        }

        $task = $tasks[$index]
        if ($task.status -eq "active") {
            $deadline = [datetime]::Parse($task.deadline_at)
            if ($now -ge $deadline) {
                $task.status = "expired"
                if ([string]::IsNullOrWhiteSpace($task.resolution)) {
                    $task.resolution = "timeout-ready"
                }
                $tasks[$index] = $task
                $state.tasks = $tasks
                Write-State -Path $StatePath -State $state
            }
        }

        $recommendedAction = if ($task.status -eq "expired") {
            $task.default_action
        }
        else {
            $null
        }

        Emit-Json -Payload ([pscustomobject]@{
            id                 = $task.id
            status             = $task.status
            deadline_at        = $task.deadline_at
            default_action     = $task.default_action
            recommended_action = $recommendedAction
            resolution         = $task.resolution
        })
        break
    }

    "close" {
        Require-TaskId -TaskId $Id
        $index = Find-TaskIndex -Tasks $tasks -TaskId $Id
        if ($index -lt 0) {
            throw "Countdown task not found: $Id"
        }

        $task = $tasks[$index]
        $task.status = "closed"
        $task.resolution = if ([string]::IsNullOrWhiteSpace($Resolution)) { "closed" } else { $Resolution }
        if (-not [string]::IsNullOrWhiteSpace($Note)) {
            $task.note = $Note
        }

        $tasks[$index] = $task
        $state.tasks = $tasks
        Write-State -Path $StatePath -State $state
        Emit-Json -Payload $task
        break
    }

    "delete" {
        Require-TaskId -TaskId $Id
        $index = Find-TaskIndex -Tasks $tasks -TaskId $Id
        if ($index -lt 0) {
            throw "Countdown task not found: $Id"
        }

        $task = $tasks[$index]
        $task.status = "deleted"
        $task.resolution = if ([string]::IsNullOrWhiteSpace($Resolution)) { "deleted" } else { $Resolution }
        if (-not [string]::IsNullOrWhiteSpace($Note)) {
            $task.note = $Note
        }

        $tasks[$index] = $task
        $state.tasks = $tasks
        Write-State -Path $StatePath -State $state
        Emit-Json -Payload $task
        break
    }
}
