---
name: karpathy-guidelines
description: Behavioral guidelines to reduce common LLM coding mistakes. Use when writing, reviewing, or refactoring code to avoid overcomplication, make surgical changes, surface assumptions, and define verifiable success criteria.
version: 1.0.0
author: Hermes Agent (adapted from andrej-karpathy-skills by multica-ai)
license: MIT
hermes:
  category: software-development
  tags: [coding-guidelines, simplicity, surgical-changes, goal-driven, assumptions, karpathy]
  related_skills: [systematic-debugging, test-driven-development, writing-plans]
  trigger_conditions:
    - When writing new code
    - When editing existing code
    - When reviewing code changes
    - When planning implementation approaches
    - When receiving vague or ambiguous requests
---

# Karpathy Guidelines

Behavioral guidelines to reduce common LLM coding mistakes, derived from [Andrej Karpathy's observations](https://x.com/karpathy/status/2015883857489522876) on LLM coding pitfalls.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks (typo fixes, obvious one-liners), use judgment — not every change needs full rigor.

## The Four Principles

| Principle | Addresses |
|-----------|-----------|
| **Think Before Coding** | Wrong assumptions, hidden confusion, missing tradeoffs |
| **Simplicity First** | Overcomplication, bloated abstractions |
| **Surgical Changes** | Orthogonal edits, touching code you shouldn't |
| **Goal-Driven Execution** | Leverage through tests-first, verifiable success criteria |

---

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### Trigger: Vague Requests

When the user says "do X" without specifics, clarify before coding:

```
Request: "Make the search faster"

Could mean:
1. Lower latency (< 100ms vs current 500ms) — add indexes, cache
2. Higher throughput (more concurrent searches) — async, pooling
3. Better UX (perceived speed) — progressive results

Current search: ~500ms typical query
Which aspect matters most?
```

### Trigger: Hidden Assumptions

When you catch yourself assuming something unspoken:

```
Request: "Add a feature to export user data"

I'm assuming:
- Export ALL users (what about pagination? privacy?)
- Downloadable file (vs API endpoint? email?)
- Which fields to include?

What's the actual use case?
```

---

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If 200 lines could be 50, rewrite it.

**Ask yourself:** "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### Anti-Pattern: Over-Abstraction

**User Request:** "Add a function to calculate discount"

**Wrong (Overengineered):**
```python
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Protocol

class DiscountStrategy(ABC):
    @abstractmethod
    def calculate(self, amount: float) -> float:
        pass

class PercentageDiscount(DiscountStrategy):
    def __init__(self, percentage: float):
        self.percentage = percentage
    def calculate(self, amount: float) -> float:
        return amount * (self.percentage / 100)
# ... 50+ lines of setup for a simple calculation
```

**Right (Simple):**
```python
def calculate_discount(amount: float, percent: float) -> float:
    """Calculate discount amount. percent should be 0-100."""
    return amount * (percent / 100)
```

### Anti-Pattern: Speculative Features

**User Request:** "Save user preferences to database"

**Wrong (Added what wasn't asked):**
```python
def save(self, user_id: int, prefs: dict,
         merge: bool = True,
         validate: bool = True,
         notify: bool = False,
         cache: bool = True) -> bool:
    # 50 lines handling caching, validation, notifications...
```

**Right (Just what was asked):**
```python
def save_preferences(db, user_id: int, preferences: dict):
    db.execute(
        "UPDATE users SET preferences = ? WHERE id = ?",
        (json.dumps(preferences), user_id)
    )
```

Add complexity **only when the requirement actually emerges**.

---

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

**The test:** Every changed line should trace directly to the user's request.

### Anti-Pattern: Drive-by Refactoring

**Request:** "Fix the bug where empty emails crash the validator"

**Wrong (Changed too much):**
```diff
  def validate_user(user_data):
-     # Check email format
-     if not user_data.get('email'):
+     """Validate user data."""
+     email = user_data.get('email', '').strip()
+     if not email:
          raise ValueError("Email required")
-     if '@' not in user_data['email']:
+     if '@' not in email or '.' not in email.split('@')[1]:
+         raise ValueError("Invalid email")
+     # Also validate username (nobody asked for this)
+     username = user_data.get('username', '').strip()
+     if len(username) < 3:
+         raise ValueError("Username too short")
      return True
```

**Right (Surgical):**
```diff
  def validate_user(user_data):
      # Check email format
-     if not user_data.get('email'):
+     email = user_data.get('email', '')
+     if not email or not email.strip():
          raise ValueError("Email required")
      # Basic email validation
-     if '@' not in user_data['email']:
+     if '@' not in email:
          raise ValueError("Invalid email")
      return True
```

### Anti-Pattern: Style Drift

**Request:** "Add logging to the upload function"

**Wrong (Changed quotes, added type hints, reformatted):**
```diff
- def upload_file(file_path, destination):
+ def upload_file(file_path: str, destination: str) -> bool:
+     """Upload file to destination."""
      try:
-         with open(file_path, 'rb') as f:
+         with open(file_path, "rb") as f:  # quote style changed
              data = f.read()
```

**Right (Match existing style):**
```diff
+ import logging
+ logger = logging.getLogger(__name__)
+
  def upload_file(file_path, destination):
+     logger.info(f'Starting upload: {file_path}')
      try:
          with open(file_path, 'rb') as f:
              data = f.read()
```

---

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

| Instead of... | Transform to... |
|--------------|-----------------|
| "Add validation" | "Write tests for invalid inputs, then make them pass" |
| "Fix the bug" | "Write a test that reproduces it, then make it pass" |
| "Refactor X" | "Ensure tests pass before and after" |

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

**Strong success criteria** let you loop independently.
**Weak criteria** ("make it work") require constant clarification.

### Anti-Pattern: Vague Goals

**Request:** "Fix the authentication system"

**Wrong:**
```
I'll review the code, identify issues, make improvements, and test.
```

**Right:**
```
To "fix authentication," I need to define success criteria.
What's the specific issue?

If "users stay logged in after password change":

Plan:
1. Write test: Change password → verify old session invalidated
   Verify: Test fails (reproduces bug)
2. Implement: Invalidate sessions on password change
   Verify: Test passes
3. Check edge cases: Multiple sessions, concurrent changes
   Verify: Additional tests pass
4. Verify no regression: Existing auth tests still pass

What's the specific auth issue?
```

### Multi-Step Verification Template

For complex tasks:

```
Plan:
1. [Add basic in-memory rate limiting] 
   Verify: curl 11 times → 429 on requests 11+
2. [Extract to middleware]
   Verify: Rate limits apply to /users and /posts
3. [Add Redis backend]
   Verify: Rate limit persists across app restarts

Each step independently verifiable and deployable.
Start with step 1?
```

---

## Hermes Agent Integration

### When to Load This Skill

Load `karpathy-guidelines` when:
- Writing new code or adding features
- Editing existing code (especially bug fixes)
- Reviewing code changes
- Planning implementation approaches
- Receiving vague or ambiguous requests
- Catching yourself about to make speculative changes

### How to Apply

**Before coding (Think + Simplicity):**
1. What am I assuming that wasn't stated?
2. Is there a simpler approach?
3. What could go wrong if I over-engineer this?

**When editing (Surgical):**
1. What specific lines does the request require me to change?
2. Did my changes create any orphans?
3. Am I touching code outside the request?

**When planning (Goal-Driven):**
1. What does success look like?
2. How can I verify it works?
3. What's the minimal first step?

### Detection: Violations in Self-Check

Red flags that you're violating these guidelines:

| Signal | Principle Violated |
|--------|-------------------|
| Implementing more than was asked | Simplicity First |
| Changing adjacent code/style | Surgical Changes |
| Picking an interpretation silently | Think Before Coding |
| "Make it work" without clear criteria | Goal-Driven |
| "While I'm here" additions | Surgical Changes |
| Abstracting single-use code | Simplicity First |

### Examples in Hermes Context

**Vague request handled well:**
```
User: "Make the API better"
Agent: "Better" could mean:
  1. Faster response times?
  2. Better error messages?
  3. More endpoints?
  4. Documentation?
Which aspect should I focus on?
```

**Surgical fix:**
```
Request: "Fix the null pointer on line 42"
Agent: 
1. Read the code around line 42
2. Identify: null comes from user_data.get('field')
3. Add null check only for that specific case
4. No style changes, no adjacent code touched
```

**Goal-driven execution:**
```
Request: "Add user authentication"
Agent: Before implementing, clarify:
1. What type? (JWT, session, OAuth?)
2. What endpoints need auth?
3. What's the verification criteria?
4. What's the minimal viable scope?
```

---

## Tradeoff Note

These guidelines bias toward **caution over speed**. For trivial tasks:
- Simple typo fixes
- Obvious one-liners
- Documentation updates
- Single-line config changes

Use judgment — not every change needs the full rigor.

The goal is reducing costly mistakes on non-trivial work, not slowing down simple tasks.

## Quality Metrics

These guidelines are working if:
- **Fewer unnecessary changes in diffs** — Only requested changes appear
- **Fewer rewrites due to overcomplication** — Code is simple the first time
- **Clarifying questions come before implementation** — Not after mistakes
- **Clean, minimal PRs** — No drive-by refactoring or "improvements"

## Related Principles

- **systematic-debugging**: Phase 1 (Root Cause) aligns with Think Before Coding
- **test-driven-development**: Tests-first approach aligns with Goal-Driven Execution
- **writing-plans**: Multi-step plans align with Goal-Driven Execution verification loops
