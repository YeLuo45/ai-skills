---
name: openclaw-proposal-management
description: Manage OpenClaw proposal lifecycle from intake to delivery across main/pm/dev agents. Use when the user asks to create, update, track, accept, or close a proposal, or when handling PRD confirmation, technical expectations, acceptance review, or revision workflows.
---

# OpenClaw Proposal Management

## Overview

This skill manages the full lifecycle of proposals in the OpenClaw multi-agent workspace (`main` / `pm` / `dev`). It covers intake, clarification, PRD confirmation with countdown, technical expectations confirmation, development handoff, acceptance review, and final delivery.

## Paths

| Item | Path |
|------|------|
| Proposal index | `~/.openclaw/workspace/proposals/proposal-index.md` |
| Proposal files | `~/.openclaw/workspace/proposals/P-YYYYMMDD-XXX*.md` |
| Templates | `~/.openclaw/workspace/proposals/templates/` |
| PM output | `~/.openclaw/workspace-pm/proposals/` |
| Dev output | `~/.openclaw/workspace-dev/proposals/` |

## Proposal ID Format

`P-YYYYMMDD-XXX` where `XXX` is a zero-padded sequential number per day.

To determine the next ID, read `proposal-index.md` and find the highest `XXX` for today's date.

## Proposal States

States must use these exact names (no custom variants):

```
intake → clarifying → prd_pending_confirmation → approved_for_dev → in_dev → in_acceptance → accepted → delivered
                                                                                ↓
                                                                          needs_revision (loops back to in_dev)
```

## Workflow

Copy this checklist and work through it:

```
- [ ] Step 1: Intake – register proposal
- [ ] Step 2: Clarify – up to 3 rounds
- [ ] Step 3: Route to PM if needed
- [ ] Step 4: PRD confirmation gate (5-min countdown)
- [ ] Step 5: Technical expectations gate (5-min countdown, up to 3 rounds)
- [ ] Step 6: Output technical solution
- [ ] Step 7: Hand off to dev
- [ ] Step 8: Acceptance review
- [ ] Step 9: Deliver or revise
```

### Step 1: Register Proposal

1. Read `proposal-index.md` to determine the next proposal ID
2. Copy `templates/request-intake-template.md` to `proposals/P-YYYYMMDD-XXX.md`
3. Fill in Basic Information and Original Request
4. Add an entry in `proposal-index.md` under Active Proposals with status `intake`

### Step 2: Clarify Requirements

- Ask up to 3 rounds of clarifying questions focused on: goal, scope, constraints, acceptance criteria
- Record each round in the proposal file under Clarification
- After 3 rounds or when clear, record Final Assumptions
- Update status to `clarifying` in `proposal-index.md`

### Step 3: Route to PM

If the request is an idea or rough draft, hand off to `pm` for PRD generation.

- PM saves PRD to `~/.openclaw/workspace-pm/proposals/YYYY-MM-DD-<slug>-prd.md`
- Update `PRD Path` in `proposal-index.md` once PM delivers

### Step 4: PRD Confirmation Gate

When PM returns the PRD:

1. Present the PRD to boss and ask for confirmation
2. Create a 5-minute countdown via OpenClaw cron:

```json
{
  "name": "P-YYYYMMDD-XXX-prd-confirm",
  "schedule": { "kind": "at", "atMs": "<Date.now() + 300000>" },
  "sessionTarget": "main",
  "wakeMode": "now",
  "payload": {
    "kind": "systemEvent",
    "text": "提案 P-YYYYMMDD-XXX PRD确认超时，默认通过处理。"
  }
}
```

3. Record the cron job ID in `PRD Confirmation Countdown ID`

**If confirmed**: set `PRD Confirmation` to `confirmed`, close the countdown

**If timeout**: wait for cron system event, set `PRD Confirmation` to `timeout-approved`, record in `Timeout Resolution`

### Step 5: Technical Expectations Gate

Before outputting a technical solution:

1. Ask boss about stack, performance, cost, deployment, maintainability, dependency constraints
2. Up to 3 rounds of questions
3. Create a 5-minute countdown (same cron pattern, name: `P-YYYYMMDD-XXX-tech-confirm`)
4. Record in `Technical Expectations Countdown ID`

**If confirmed**: set `Technical Expectations` to `confirmed`, write confirmed constraints to `Technical Assumptions Summary`

**If timeout**: set `Technical Expectations` to `timeout-approved`, proceed with current assumptions, record in `Timeout Resolution`

### Step 6: Technical Solution

- Output the technical solution document at `proposals/P-YYYYMMDD-XXX-tech-solution.md`
- Update status to `approved_for_dev`

### Step 7: Hand Off to Dev

- Update status to `in_dev`
- Dev saves project output to `~/.openclaw/workspace-dev/proposals/<project-slug>/`
- Update `Project Path` in `proposal-index.md`

### Step 8: Acceptance Review

When dev reports completion, check these items:

**Requirements consistency:**
- Matches boss-confirmed requirements
- Aligns with PRD
- No scope creep or shortcuts

**Functional verification (hands-on, not just screenshots):**
- Core functionality works end-to-end
- Console has no errors (warnings OK)
- Existing functionality not broken
- Build succeeds (`npm run build` or equivalent)

**Delivery completeness:**
- File paths provided
- Startup/access instructions provided
- Verification results or screenshots provided

**Quality:**
- No obvious gaps
- No UI/logic conflicts
- Known limitations documented

Update status to `in_acceptance` during review.

### Step 9: Deliver or Revise

**If accepted**: update status to `accepted` or `delivered`, report to boss

**If not accepted**: update status to `needs_revision`, output structured revision notes:

```markdown
## 返修意见

- **问题**: <description>
- **影响**: <what is affected>
- **期望修复**: <how to fix and verify>
```

Record revision notes in `proposal-index.md` Notes field.

## Dev Delivery Quality Checks

Three hard indicators to verify before accepting dev delivery:

1. **Build exit code**: must be 0
2. **Output directory not empty**: list core files
3. **Core service files exist**: list service directory

If dev claims completion without providing these, run the checks yourself.

### Takeover Triggers

Take over from dev when any of these occur:
- Dev fails delivery twice consecutively
- Dev session interrupted by API errors (429/quota)
- Dev session runtime abnormally short (< 30s and claims done)
- Fix is simple and clearly identified

### Recording Fixes

When main directly fixes issues, record in:
1. `MEMORY.md` under relevant section
2. `memory/YYYY-MM-DD.md` daily log
3. Proposal's `Notes` or `Main Fixes Applied` field

## Index Entry Template

When adding to `proposal-index.md`:

```markdown
### P-YYYYMMDD-XXX: <Title>

- `Proposal ID`: `P-YYYYMMDD-XXX`
- `Title`: <title>
- `Owner`: `main`
- `Current Status`: `intake`
- `PRD Path`: (to be filled by pm)
- `Technical Solution`: (to be filled)
- `Project Path`: (to be filled by dev)
- `Acceptance`: -
- `PRD Confirmation`: pending
- `PRD Confirmation Countdown ID`: -
- `Technical Expectations`: pending
- `Technical Expectations Countdown ID`: -
- `Last Update`: YYYY-MM-DD
- `Notes`:
```

## Additional Resources

- Request intake template: [templates/request-intake-template.md](~/.openclaw/workspace/proposals/templates/request-intake-template.md)
- Proposal status template: [templates/proposal-status-template.md](~/.openclaw/workspace/proposals/templates/proposal-status-template.md)
- Acceptance checklist: [templates/acceptance-checklist-template.md](~/.openclaw/workspace/proposals/templates/acceptance-checklist-template.md)
