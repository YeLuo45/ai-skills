---
name: proposal-management
description: Manage proposal lifecycle from intake to delivery across coordinating agents or roles. Use when the user asks to create, update, track, accept, or close a proposal, or when handling PRD confirmation, technical review, acceptance, or revision workflows. Works with any agent platform (Cursor, Hermes, OpenClaw, etc.).
---

# Proposal Management

## Overview

A platform-agnostic skill for managing proposal lifecycles across multi-role workflows (e.g. coordinator / PM / dev). Covers intake, clarification, PRD confirmation, technical review, development handoff, acceptance, and delivery.

## Configuration

Before first use, determine and record the following for your environment:

| Variable | Description | Example |
|----------|-------------|---------|
| `PROPOSALS_ROOT` | Directory holding proposal index and files | `~/.openclaw/workspace/proposals` |
| `TEMPLATES_DIR` | Subdirectory for templates | `${PROPOSALS_ROOT}/templates` |
| `PM_OUTPUT_DIR` | Where PM stores PRD documents | `~/.openclaw/workspace-pm/proposals` |
| `DEV_OUTPUT_DIR` | Where dev stores project artifacts | `~/.openclaw/workspace-dev/proposals` |
| `COORDINATOR` | Primary coordinating role name | `main` / `agent` / `assistant` |
| `REQUESTER` | Who submits requests | `boss` / `user` / `client` |

If these paths are not known, ask the user to provide them. The rest of this skill uses the variable names above.

## Proposal ID Format

`P-YYYYMMDD-XXX` — zero-padded sequential number per day.

To determine the next ID, read `proposal-index.md` and find the highest `XXX` for today's date.

## Proposal States

Use these exact names across all roles — no custom variants:

```
intake → clarifying → prd_pending_confirmation → approved_for_dev → in_dev → in_acceptance → accepted → delivered
                                                                                ↓
                                                                          needs_revision → in_dev
```

## Workflow

```
- [ ] Step 1: Intake – register proposal
- [ ] Step 2: Clarify – up to 3 rounds
- [ ] Step 3: Route to PM if needed
- [ ] Step 4: PRD confirmation gate
- [ ] Step 5: Technical expectations gate (up to 3 rounds)
- [ ] Step 6: Output technical solution
- [ ] Step 7: Hand off to dev
- [ ] Step 8: Acceptance review
- [ ] Step 9: Deliver or revise
```

### Step 1: Register Proposal

1. Read `${PROPOSALS_ROOT}/proposal-index.md` to determine the next ID
2. Copy `${TEMPLATES_DIR}/request-intake-template.md` to `${PROPOSALS_ROOT}/P-YYYYMMDD-XXX.md`
3. Fill in Basic Information and Original Request
4. Add an entry in `proposal-index.md` under Active Proposals with status `intake`

### Step 2: Clarify Requirements

- Ask the requester up to 3 rounds of clarifying questions focused on: goal, scope, constraints, acceptance criteria
- Record each round in the proposal file under Clarification
- After 3 rounds or when clear, record Final Assumptions
- Update status to `clarifying`

### Step 3: Route to PM

If the request is an idea or rough draft, hand off to the PM role for PRD generation.

- PM saves PRD to `${PM_OUTPUT_DIR}/YYYY-MM-DD-<slug>-prd.md`
- Update `PRD Path` in `proposal-index.md` once PM delivers

### Step 4: PRD Confirmation Gate

When PM returns the PRD:

1. Present the PRD to the requester and ask for confirmation
2. Start a confirmation timeout (recommended: 5 minutes)
3. Record the timeout reference in `PRD Confirmation Countdown ID`

**If confirmed**: set `PRD Confirmation` to `confirmed`, cancel the timeout

**If timeout**: set `PRD Confirmation` to `timeout-approved`, record in `Timeout Resolution`

#### Timeout Implementation by Platform

| Platform | Method |
|----------|--------|
| OpenClaw | `cron` with `schedule.kind="at"`, `atMs=<now+300000>`, `payload.kind="systemEvent"` |
| Hermes | `cron` with `wrap_response: true` or manual timer tracking |
| Cursor | Use the countdown-manager skill if available, or track manually with timestamps |
| Other | Record a deadline timestamp and check on next interaction |

### Step 5: Technical Expectations Gate

Before outputting a technical solution:

1. Ask the requester about: stack, performance, cost, deployment, maintainability, dependency constraints
2. Up to 3 rounds of questions
3. Start a confirmation timeout (same mechanism as Step 4)
4. Record in `Technical Expectations Countdown ID`

**If confirmed**: set `Technical Expectations` to `confirmed`, write constraints to `Technical Assumptions Summary`

**If timeout**: set `Technical Expectations` to `timeout-approved`, proceed with current assumptions, record in `Timeout Resolution`

### Step 6: Technical Solution

- Output the technical solution at `${PROPOSALS_ROOT}/P-YYYYMMDD-XXX-tech-solution.md`
- Update status to `approved_for_dev`

### Step 7: Hand Off to Dev

- Update status to `in_dev`
- Dev saves project output to `${DEV_OUTPUT_DIR}/<project-slug>/`
- Update `Project Path` in `proposal-index.md`

### Step 8: Acceptance Review

When dev reports completion, verify all of the following:

**Requirements consistency:**
- Matches requester-confirmed requirements
- Aligns with PRD
- No scope creep or shortcuts

**Functional verification (hands-on, not screenshots only):**
- Core functionality works end-to-end
- No errors in console/logs (warnings OK)
- Existing functionality not broken
- Build succeeds (e.g. `npm run build`, `cargo build`, `go build`)

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

**If accepted**: update status to `accepted` or `delivered`, report to requester

**If not accepted**: update status to `needs_revision`, output structured revision notes:

```markdown
## Revision Notes

- **Issue**: <description>
- **Impact**: <what is affected>
- **Expected fix**: <how to fix and how to verify>
```

Record revision notes in `proposal-index.md` Notes field.

## Dev Delivery Quality Checks

Three hard indicators to verify before accepting:

1. **Build exit code**: must be 0
2. **Output directory not empty**: list core files to confirm
3. **Core source/service files exist**: verify key files are present

If dev claims completion without providing evidence, run the checks yourself.

### Takeover Triggers

The coordinator should take over from dev when:
- Dev fails delivery twice consecutively
- Dev session interrupted by API/quota errors
- Dev session abnormally short (< 30s) yet claims completion
- Fix is simple and clearly identified

### Recording Fixes

When the coordinator directly fixes issues, record in:
1. Project memory file (e.g. `MEMORY.md`) under relevant section
2. Daily log (e.g. `memory/YYYY-MM-DD.md`)
3. Proposal's `Notes` or `Main Fixes Applied` field

## Index Entry Template

When adding to `proposal-index.md`:

```markdown
### P-YYYYMMDD-XXX: <Title>

- `Proposal ID`: `P-YYYYMMDD-XXX`
- `Title`: <title>
- `Owner`: <coordinator>
- `Current Status`: `intake`
- `PRD Path`: (to be filled by PM)
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

## Templates

This skill expects three templates in `${TEMPLATES_DIR}/`:

| Template | Purpose |
|----------|---------|
| `request-intake-template.md` | Initial proposal registration with clarification fields and confirmation gates |
| `proposal-status-template.md` | Status tracking with linked assets, confirmation gates, and revision notes |
| `acceptance-checklist-template.md` | Structured acceptance review with functional/quality/delivery checks |

If templates do not exist at the expected path, create them based on the index entry template above and the acceptance review checklist in Step 8.
