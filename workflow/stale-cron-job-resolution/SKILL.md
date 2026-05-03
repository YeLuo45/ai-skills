---
name: stale-cron-job-resolution
description: When a recurring cron job fires but the intended state has already been achieved — verify, pause, and report instead of redundant writes.
triggers:
  - cron job fires but target is already in desired state
  - cron job has run hundreds of times unnecessarily
  - confirmation timeout type jobs that should have been one-shot
---

# Stale Cron Job Resolution

## When to Use
When a cron job fires but the intended state change has already occurred (proposal already updated, task already completed, etc.), and the job is a recurring `*/5 * * * *` or similar interval that should have been one-shot.

## Problem Pattern
- Cron job fires repeatedly (every N minutes/hours)
- Target entities are already in the desired state
- Job keeps firing unnecessarily, wasting resources

## Resolution Steps

1. **Verify actual state** — Read the proposal-index.md or relevant state file to confirm current status
2. **Check jobs.json** — Find the cron job definition, look at `repeat.completed` count and `enabled` state
3. **If already achieved**: Pause the job and report "already in desired state" instead of making redundant updates
4. **If genuinely pending**: Proceed with the intended action

## Key Insight
A "confirmation timeout" cron should be **one-shot** (no repeat), or should self-disable after first successful execution. A recurring `*/5 * * * *` that checks "is X already done?" will never naturally stop if X was already done before the job was created.

## Example: This Case
- Job `P-20260430-003-005-prd-confirm` created 2026-04-30, recurring every 5 minutes
- Had fired **379 times** by 2026-05-02
- Proposals P-20260430-003/004/005 were already `delivered` + `accepted` since 2026-05-01
- Action: Pause the job with reason "Stale job — already achieved", do NOT make redundant writes to proposal-index.md

## Files
- Cron jobs: `~/.hermes/cron/jobs.json`
- Proposal index: `~/.hermes/proposals/proposal-index.md`
