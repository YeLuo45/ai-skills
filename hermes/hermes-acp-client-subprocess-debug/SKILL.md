---
name: hermes-acp-client-subprocess-debug
description: Debug Hermes ACP Client subprocess errors - ValueError Invalid format specifier and set literal bugs in ag.chat()
---

# Hermes ACP Client Subprocess Debug Guide

## Problem
Agent responses fail with "Agent error: invalid response" or "ValueError: Invalid format specifier" when using `ag.chat()` in the Hermes collaboration system.

## Root Causes (Two Bugs)

### Bug 1: Set Literal Instead of String
```python
# WRONG - {..} creates a set!
result = ag.chat({json.dumps(content)})

# CORRECT - pass string directly
result = ag.chat(content)
```

### Bug 2: F-String Nested Brace Parsing
When generating Python scripts inline via subprocess, f-strings with nested braces cause `ValueError: Invalid format specifier`:

```python
# WRONG - braces in json.dumps() confuse Python's f-string parser
script = f"""
content = {json.dumps(content)}
result = ag.chat(content)
"""

# This fails because Python sees {json.dumps(content)} as a format spec
```

## Solution Pattern

Build the script using string list joining instead of f-strings:

```python
def _build_script(self, content, session_id=None):
    content_json = json.dumps(content)  # Serialize once
    session_str = session_id or ""
    
    script_parts = [
        "import sys, os, yaml, json",
        "sys.path.insert(0, '/home/hermes/.hermes/proposals/workspace-dev/proposals/hermes-agent-collab')",
        "from collaboration.acp_client import AgentConfig, HermesAgent",
        "",
        f"content = {content_json}",
        f"session_id = '{session_str}'" if session_str else "session_id = None",
        "",
        "try:",
        "    ...",
        "except Exception as e:",
        "    print(f'ERROR: {{e}}')",
    ]
    return "\n".join(script_parts)
```

## Key Insight
When generating Python code as a string inside Python code:
- NEVER put `{...}` inside an f-string that contains dict/list literals
- Use `json.dumps()` for content serialization BEFORE the generated script
- Use explicit string concatenation or list joining instead of f-string interpolation for script building

## Verification
Test locally first:
```bash
cd /home/hermes/.hermes/proposals/workspace-dev/proposals/hermes-agent-collab
python3.12 -c "
import asyncio
from collaboration.acp_client import DirectAgentClient
async def test():
    client = DirectAgentClient()
    result = await client.send_message('你好')
    print('Content:', result.content)
asyncio.run(test())
"
```

Expected output: `Content: 你好 boss！有什么需要我帮忙的？`

## Server Restart Required
Code changes in `acp_client.py` require server restart:
```bash
ps aux | grep collaboration.server | grep -v grep
kill <PID>
python3 -m collaboration.server --host 0.0.0.0 --port 9119 &
```

## File Location
`/home/hermes/.hermes/proposals/workspace-dev/proposals/hermes-agent-collab/collaboration/acp_client.py`
