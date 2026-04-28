---
name: countdown-manager
description: Manage lightweight file-backed countdown tasks with create, query, remind, close, and delete operations. Use when waiting for user confirmation with a timeout, when a workflow needs default-pass behavior after N minutes, or when OpenClaw main/pm/dev need to track confirmation deadlines.
---

# Countdown Manager

Use this skill when the agent needs a durable countdown instead of relying on memory inside the current turn.

## OpenClaw runtime first

Inside OpenClaw runtime, prefer the built-in `cron` tool for countdowns.

Recommended runtime pattern:

- `schedule.kind="after"`
- `afterMs=<delay-ms>`
- `sessionTarget="main"`
- `wakeMode="now"`
- `payload.kind="systemEvent"`

Why this is the default:

- the server computes the final absolute time
- the agent no longer needs to hand-calculate `atMs`
- stale absolute timestamps are rejected
- timeout events wake `main` immediately instead of waiting for a later heartbeat

Use the PowerShell script in this skill only when you are outside OpenClaw runtime or when you need a local fallback.

## When to use

- Waiting for user confirmation with a fixed timeout
- Applying a default action if the user does not reply in time
- Tracking PRD confirmation or technical-expectation confirmation in OpenClaw
- Querying whether an existing countdown is still active or already expired

## Storage

The manager uses a JSON state file. By default it lives at:

`C:\Users\YeZhimin\.cursor\skills\countdown-manager\countdowns.json`

You can override it with `-StatePath` when testing or when a task needs isolated state.

## Local fallback operations

### 1. Create

Create a countdown task:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\YeZhimin\.cursor\skills\countdown-manager\scripts\countdown-manager.ps1" `
  -Operation create `
  -Id "P-20260412-001-prd-confirm" `
  -Title "PRD completion confirmation" `
  -Context "Wait for boss to confirm PRD completeness" `
  -OwnerAgent "main" `
  -DurationMinutes 5 `
  -DefaultAction "approve_prd_by_timeout"
```

Required fields:

- `-Id`
- `-Title`
- `-OwnerAgent`
- `-DefaultAction`

### 2. Query

Query one task:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\YeZhimin\.cursor\skills\countdown-manager\scripts\countdown-manager.ps1" `
  -Operation query `
  -Id "P-20260412-001-prd-confirm"
```

Query all tasks:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\YeZhimin\.cursor\skills\countdown-manager\scripts\countdown-manager.ps1" `
  -Operation query
```

### 3. Remind

Check whether a task is still active or already expired:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\YeZhimin\.cursor\skills\countdown-manager\scripts\countdown-manager.ps1" `
  -Operation remind `
  -Id "P-20260412-001-prd-confirm"
```

If expired, the script returns `recommended_action` with the default action.

### 4. Close

Mark a task closed after the user confirms:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\YeZhimin\.cursor\skills\countdown-manager\scripts\countdown-manager.ps1" `
  -Operation close `
  -Id "P-20260412-001-prd-confirm" `
  -Resolution "user-confirmed"
```

### 5. Delete

Delete a task that is invalid or no longer needed:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\YeZhimin\.cursor\skills\countdown-manager\scripts\countdown-manager.ps1" `
  -Operation delete `
  -Id "P-20260412-001-prd-confirm" `
  -Resolution "cleanup"
```

## OpenClaw usage rules

For `main`:

1. After receiving a PRD from `pm`, ask whether the PRD is complete.
2. Immediately create a 5-minute countdown with OpenClaw `cron`.
3. Prefer `schedule.kind="after"` and `wakeMode="now"`.
4. If the user confirms, remove the cron job.
5. If the user does not reply in time, let the cron `systemEvent` drive the timeout action and record timeout approval.

Before outputting a technical solution:

1. Ask about technical expectations such as stack, performance, cost, deployment, or dependency constraints.
2. Keep the conversation within 3 rounds.
3. Create a 5-minute countdown for that confirmation stage with OpenClaw `cron`.
4. On timeout, let the cron `systemEvent` proceed with the current explicit assumptions.

## OpenClaw runtime invocation examples

Use these examples first when the agent is running inside OpenClaw.

### 1. PRD returned by `pm`: create PRD confirmation countdown

```json
{
  "action": "add",
  "job": {
    "name": "P-20260412-001-prd-confirm",
    "schedule": { "kind": "after", "afterMs": 300000 },
    "sessionTarget": "main",
    "wakeMode": "now",
    "payload": {
      "kind": "systemEvent",
      "text": "【倒计时到期】提案 P-20260412-001 PRD确认超时，默认通过处理。请将 PRD Confirmation 更新为 timeout-approved 并继续技术诉求确认阶段。"
    }
  }
}
```

### 2. User confirmed PRD: remove countdown

```json
{
  "action": "remove",
  "jobId": "<the prd confirm cron job id>"
}
```

### 3. Before technical solution output: create technical-expectation countdown

```json
{
  "action": "add",
  "job": {
    "name": "P-20260412-001-tech-confirm",
    "schedule": { "kind": "after", "afterMs": 300000 },
    "sessionTarget": "main",
    "wakeMode": "now",
    "payload": {
      "kind": "systemEvent",
      "text": "【倒计时到期】提案 P-20260412-001 技术诉求确认超时，按当前明确假设默认通过。请将 Technical Expectations 更新为 timeout-approved 并输出技术方案。"
    }
  }
}
```

### 4. User confirmed technical expectations: remove countdown

```json
{
  "action": "remove",
  "jobId": "<the tech confirm cron job id>"
}
```

### 5. Wrong or duplicated countdown: remove countdown

```json
{
  "action": "remove",
  "jobId": "<the invalid cron job id>"
}
```

## Local fallback examples

Use the following examples as the default calling checklist for `main`.

### 1. PRD returned by `pm`: create PRD confirmation countdown

When `main` has received a PRD and is about to ask whether the PRD is complete:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\YeZhimin\.cursor\skills\countdown-manager\scripts\countdown-manager.ps1" `
  -Operation create `
  -Id "P-20260412-001-prd-confirm" `
  -Title "PRD completeness confirmation" `
  -Context "Wait for boss to confirm whether the PRD is complete enough to proceed" `
  -OwnerAgent "main" `
  -DurationMinutes 5 `
  -DefaultAction "approve_prd_by_timeout"
```

### 2. User confirmed PRD: close countdown

When the user explicitly says the PRD is OK:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\YeZhimin\.cursor\skills\countdown-manager\scripts\countdown-manager.ps1" `
  -Operation close `
  -Id "P-20260412-001-prd-confirm" `
  -Resolution "user-confirmed-prd"
```

### 3. Need to check whether PRD confirmation timed out: remind

When `main` comes back to the task and needs to know whether it can default-pass:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\YeZhimin\.cursor\skills\countdown-manager\scripts\countdown-manager.ps1" `
  -Operation remind `
  -Id "P-20260412-001-prd-confirm"
```

If the returned JSON shows:

- `status = "active"`: keep waiting or continue the current conversation
- `status = "expired"`: apply `recommended_action`, record timeout approval in `proposals`, then close the task

### 4. Before technical solution output: create technical-expectation countdown

When `main` is about to ask about stack, performance, cost, deployment, or dependency constraints:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\YeZhimin\.cursor\skills\countdown-manager\scripts\countdown-manager.ps1" `
  -Operation create `
  -Id "P-20260412-001-tech-confirm" `
  -Title "Technical expectations confirmation" `
  -Context "Wait for boss to confirm technical expectations before outputting the technical solution" `
  -OwnerAgent "main" `
  -DurationMinutes 5 `
  -DefaultAction "accept_current_technical_assumptions"
```

### 5. User confirmed technical expectations: close countdown

When the user has replied with the required technical preferences or has accepted the current assumptions:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\YeZhimin\.cursor\skills\countdown-manager\scripts\countdown-manager.ps1" `
  -Operation close `
  -Id "P-20260412-001-tech-confirm" `
  -Resolution "user-confirmed-technical-expectations"
```

### 6. Need to check whether technical-expectation confirmation timed out: remind

When `main` has asked up to 3 rounds or returns later and needs a timeout decision:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\YeZhimin\.cursor\skills\countdown-manager\scripts\countdown-manager.ps1" `
  -Operation remind `
  -Id "P-20260412-001-tech-confirm"
```

If the returned JSON shows `expired`, `main` should:

1. use the returned `recommended_action`
2. write the current technical assumptions into the proposal record
3. mark the confirmation as timeout-approved
4. continue to output the technical solution

### 7. Cleanup invalid or duplicated countdowns

When `main` created the wrong id or duplicated a countdown:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\YeZhimin\.cursor\skills\countdown-manager\scripts\countdown-manager.ps1" `
  -Operation delete `
  -Id "P-20260412-001-tech-confirm" `
  -Resolution "cleanup-invalid-or-duplicate"
```

### 8. Recommended id convention for `main`

Use stable ids so one proposal can have multiple independent countdowns:

```text
P-YYYYMMDD-XXX-prd-confirm
P-YYYYMMDD-XXX-tech-confirm
P-YYYYMMDD-XXX-acceptance-confirm
```

For the current OpenClaw flow, the first two are the required defaults.

## Main speech templates and command mapping

Use this section when `main` needs a direct pairing between user-facing wording and the countdown command.

### Scenario 1: Ask whether the PRD is complete

**User-facing message template**

```text
PRD 已整理完成。请确认这份 PRD 是否已经足够完善，可以进入下一步。

如果你 5 分钟内没有回复，我会按“默认通过”继续推进，并在提案记录里注明这是超时通过。
```

**OpenClaw runtime command**

```json
{
  "action": "add",
  "job": {
    "name": "P-20260412-001-prd-confirm",
    "schedule": { "kind": "after", "afterMs": 300000 },
    "sessionTarget": "main",
    "wakeMode": "now",
    "payload": {
      "kind": "systemEvent",
      "text": "【倒计时到期】提案 P-20260412-001 PRD确认超时，默认通过处理。请将 PRD Confirmation 更新为 timeout-approved 并继续技术诉求确认阶段。"
    }
  }
}
```

**Local fallback command**

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\YeZhimin\.cursor\skills\countdown-manager\scripts\countdown-manager.ps1" `
  -Operation create `
  -Id "P-20260412-001-prd-confirm" `
  -Title "PRD completeness confirmation" `
  -Context "Wait for boss to confirm whether the PRD is complete enough to proceed" `
  -OwnerAgent "main" `
  -DurationMinutes 5 `
  -DefaultAction "approve_prd_by_timeout"
```

**Proposal record update**

- `PRD Confirmation`: `pending`
- `PRD Confirmation Countdown ID`: the countdown id above

### Scenario 2: User explicitly approved the PRD

**User-facing message template**

```text
收到，我将把这份 PRD 视为已确认，并继续进入技术诉求确认阶段。
```

**OpenClaw runtime command**

```json
{
  "action": "remove",
  "jobId": "<the prd confirm cron job id>"
}
```

**Local fallback command**

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\YeZhimin\.cursor\skills\countdown-manager\scripts\countdown-manager.ps1" `
  -Operation close `
  -Id "P-20260412-001-prd-confirm" `
  -Resolution "user-confirmed-prd"
```

**Proposal record update**

- `PRD Confirmation`: `confirmed`
- `Timeout Resolution`: leave empty unless timeout had already happened

### Scenario 3: PRD confirmation timed out

**User-facing message template**

```text
由于 5 分钟内未收到你的确认，我将按默认规则把 PRD 视为通过，并继续推进后续步骤。
```

**OpenClaw runtime command**

超时时由 cron 的 `systemEvent` 自动投递，不需要先执行本地 `remind`。

如果需要人工清理任务：

```json
{
  "action": "remove",
  "jobId": "<the prd confirm cron job id>"
}
```

**Local fallback command**

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\YeZhimin\.cursor\skills\countdown-manager\scripts\countdown-manager.ps1" `
  -Operation remind `
  -Id "P-20260412-001-prd-confirm"
```

If using the local fallback and `status` is `expired`, then close it:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\YeZhimin\.cursor\skills\countdown-manager\scripts\countdown-manager.ps1" `
  -Operation close `
  -Id "P-20260412-001-prd-confirm" `
  -Resolution "timeout-approved-prd"
```

**Proposal record update**

- `PRD Confirmation`: `timeout-approved`
- `Timeout Resolution`: `approve_prd_by_timeout`

### Scenario 4: Ask for technical expectations before the technical solution

**User-facing message template**

```text
在我输出技术方案前，还需要先确认你的技术诉求。请优先告诉我你对技术栈、性能、成本、部署方式、可维护性或第三方依赖限制的要求。

我最多会追问 3 轮；如果你 5 分钟内没有回复，我会按当前明确假设默认通过并继续输出技术方案。
```

**OpenClaw runtime command**

```json
{
  "action": "add",
  "job": {
    "name": "P-20260412-001-tech-confirm",
    "schedule": { "kind": "after", "afterMs": 300000 },
    "sessionTarget": "main",
    "wakeMode": "now",
    "payload": {
      "kind": "systemEvent",
      "text": "【倒计时到期】提案 P-20260412-001 技术诉求确认超时，按当前明确假设默认通过。请将 Technical Expectations 更新为 timeout-approved 并输出技术方案。"
    }
  }
}
```

**Local fallback command**

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\YeZhimin\.cursor\skills\countdown-manager\scripts\countdown-manager.ps1" `
  -Operation create `
  -Id "P-20260412-001-tech-confirm" `
  -Title "Technical expectations confirmation" `
  -Context "Wait for boss to confirm technical expectations before outputting the technical solution" `
  -OwnerAgent "main" `
  -DurationMinutes 5 `
  -DefaultAction "accept_current_technical_assumptions"
```

**Proposal record update**

- `Technical Expectations`: `pending`
- `Technical Expectations Countdown ID`: the countdown id above

### Scenario 5: User explicitly confirmed technical expectations

**User-facing message template**

```text
收到，我将按这些技术诉求作为约束，继续输出技术方案。
```

**OpenClaw runtime command**

```json
{
  "action": "remove",
  "jobId": "<the tech confirm cron job id>"
}
```

**Local fallback command**

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\YeZhimin\.cursor\skills\countdown-manager\scripts\countdown-manager.ps1" `
  -Operation close `
  -Id "P-20260412-001-tech-confirm" `
  -Resolution "user-confirmed-technical-expectations"
```

**Proposal record update**

- `Technical Expectations`: `confirmed`
- `Technical Assumptions Summary`: replace with the confirmed constraints instead of assumptions

### Scenario 6: Technical expectations timed out

**User-facing message template**

```text
由于 5 分钟内未收到进一步确认，我将按当前已经明确的技术假设继续推进，并输出技术方案。
```

**OpenClaw runtime command**

超时时由 cron 的 `systemEvent` 自动投递，不需要先执行本地 `remind`。

如果需要人工清理任务：

```json
{
  "action": "remove",
  "jobId": "<the tech confirm cron job id>"
}
```

**Local fallback command**

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\YeZhimin\.cursor\skills\countdown-manager\scripts\countdown-manager.ps1" `
  -Operation remind `
  -Id "P-20260412-001-tech-confirm"
```

If using the local fallback and `status` is `expired`, then close it:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\YeZhimin\.cursor\skills\countdown-manager\scripts\countdown-manager.ps1" `
  -Operation close `
  -Id "P-20260412-001-tech-confirm" `
  -Resolution "timeout-approved-technical-expectations"
```

**Proposal record update**

- `Technical Expectations`: `timeout-approved`
- `Technical Assumptions Summary`: write the current explicit assumptions
- `Timeout Resolution`: `accept_current_technical_assumptions`

### Scenario 7: Wrong or duplicate countdown id

**User-facing message template**

```text
我发现当前倒计时记录有重复或误建，先清理旧记录，再继续按正确的提案阶段推进。
```

**OpenClaw runtime command**

```json
{
  "action": "remove",
  "jobId": "<the invalid cron job id>"
}
```

**Local fallback command**

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\YeZhimin\.cursor\skills\countdown-manager\scripts\countdown-manager.ps1" `
  -Operation delete `
  -Id "P-20260412-001-tech-confirm" `
  -Resolution "cleanup-invalid-or-duplicate"
```

### Scenario 8: Minimal operator checklist for `main`

1. Ask the question first.
2. Inside OpenClaw runtime, create the countdown immediately with `cron` using `schedule.kind="after"` and `wakeMode="now"`.
3. Record the countdown id in `proposals/templates/request-intake-template.md` or the actual proposal status file.
4. If the user replies, remove the cron job and update the proposal record to `confirmed`.
5. If the user does not reply, let the cron `systemEvent` trigger the default action.
6. Only use local `remind`/`close` flows when operating outside OpenClaw runtime.

## Notes

- In OpenClaw runtime, background delivery comes from `cron`, not from this PowerShell script.
- The local PowerShell fallback does not run in the background.
- Local reminder behavior depends on the agent invoking `remind`.
- Use unique ids so different proposal stages do not collide.
