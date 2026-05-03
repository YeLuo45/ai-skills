---
name: hermes-collab-debug
description: Debugging Hermes collaboration server message forwarding issues - architectural analysis of broken event-based message routing
tags: [hermes, collaboration, websocket, event-bus, architecture]
---

# Hermes Collaboration Server Debugging

## Context
The Hermes collaboration server at `http://172.24.124.156:9119/` has a broken message forwarding mechanism. When users send messages to agents via the web UI, the system attempts to call external LLM APIs directly instead of routing to actual Hermes Agent processes.

## Key Files
- `/home/hermes/.hermes/collab/collab_api.py` - Main API router, contains `send_agent_message()` endpoint
- `/home/hermes/.hermes/collab/events.py` - EventBus implementation
- `/home/hermes/.hermes/collab/agent_registry.py` - AgentRegistry
- `/home/hermes/.hermes/collab/models.py` - AgentProfile model
- `/home/hermes/hermes-collab-web/src/components/ChatModal.tsx` - Frontend chat UI

## Root Cause
The `send_agent_message()` endpoint (line 261-281 in collab_api.py):
1. Only emits an `agent.message` event via EventBus
2. Returns immediately with success
3. **No handler is registered** in EventBus to process AGENT_MESSAGE events
4. No message routing or forwarding logic exists

Additionally:
- `AgentProfile` model lacks `endpoint` field - no information about how to reach Agent processes
- Messages are "fire and forget" - no response mechanism

## Architecture Issue
```
User → ChatModal.tsx → POST /api/collab/agents/{id}/message
     → send_agent_message() → emit_agent_message() → (no handler) → return
     → ChatModal catches HTTP success but gets no actual response
```

The frontend expects a `response` field in the API return (line 77-79 of ChatModal.tsx):
```javascript
content: data.response || data.message || "收到消息"
```

## Investigation Method
1. Browser navigation to collaboration server
2. JavaScript console inspection for page structure
3. Code review of backend (collab_api.py, events.py, models.py)
4. Frontend code review (ChatModal.tsx)

## Fix Attempted: Subprocess Approach (Failed)

**First fix** (commit `74469db`): Added `load_dotenv(Path.home() / ".hermes" / ".env")` to subprocess script in `collab_api.py`. This addressed the missing API key issue.

**However**: Even with `.env` loaded, subprocess cannot connect to MiniMax API:
```
API call failed (attempt 1/3): APIConnectionError
Connection error.
```
Root cause: subprocess has a different network stack than the running Hermes Agent process. The running Agent can reach `https://api.minimaxi.com/anthropic`, but a newly spawned subprocess cannot.

## Fix Achieved: DirectAgentClient (subprocess + ANTHROPIC_API_KEY)

**Working solution** (commit `51ef8f8`): DirectAgentClient subprocess approach works reliably when:
1. `load_dotenv()` loads `.env`
2. `os.environ["ANTHROPIC_API_KEY"]` is set explicitly (NOT just MINIMAX_CN_API_KEY)

**Root cause of earlier failures**: AIAgent doesn't auto-read MINIMAX_CN_API_KEY for provider="minimax-cn". It looks for `ANTHROPIC_API_KEY` specifically.

**Verification**: 3/3 consecutive tests passed with normal response latency.

**Key insight**: curl/httpx/requests from venv python CAN reach the API fine. The issue was specifically in AIAgent's token resolution:
- AIAgent with provider="minimax-cn" checks `ANTHROPIC_API_KEY` env var
- `.env` file contains `MINIMAX_CN_API_KEY` (different name)
- Solution: explicitly copy `MINIMAX_CN_API_KEY` → `ANTHROPIC_API_KEY` in subprocess script

## Fix Attempted: ACP Adapter (Abandoned)

**Decision**: ACP adapter approach hit asyncio selector fd permission error:
```
PermissionError: [Errno 1] Operation not permitted
KeyError: '0 is not registered'
```
This occurs in sandboxed environments where asyncio's selectors module can't register stdin fd.

**ACP still valid architecturally**: For other environments (non-sandboxed), ACP adapter remains the cleaner approach since it:
- Reuses running Hermes Agent's network stack and session state
- Doesn't spawn new LLM session per request

## Key Learnings

1. **subprocess 网络隔离**: 真实原因不是网络栈隔离，而是 API key 名称不匹配
2. **.env 加载时机**: 需要在 subprocess 脚本开头显式加载，不能依赖环境变量继承
3. **ANTHROPIC_API_KEY vs MINIMAX_CN_API_KEY**: AIAgent 对 minimax-cn provider 只认 ANTHROPIC_API_KEY
4. **ACP vs Gateway**: Gateway 用于外部 IM 平台集成，ACP 用于内部组件通信
5. **asyncio stdio 限制**: 在沙箱环境下，asyncio selectors 对 stdin fd 的注册会被拒绝
6. **venv python 网络正常**: curl/httpx/requests 都可以从 venv python 调通 API

## 新发现的 Bug：Python Set 字面量陷阱

在 `acp_client.py` 的脚本模板中曾出现以下错误：

```python
# 错误代码
result = ag.chat({json.dumps(content)})  # { ... } 是 SET 字面量，不是 dict！
```

`{json.dumps(content)}` 在 Python 中会被解释为**set literal（集合字面量）**，而不是包含单个元素的字典。正确写法应该是：

```python
# 正确代码
result = ag.chat(content)  # 直接传字符串，不需要 json.dumps
```

**症状**：调用 agent 时返回 `"Agent error: invalid response: ..."`，因为 AIAgent 收到的是 set 对象，导致 `AttributeError: 'set' object has no attribute 'replace'`

**根本原因**：在 f-string 脚本模板中，双重花括号 `{{ }}` 用于转义，但 `{json.dumps(content)}` 没有被转义，被 Python 解释器当成 set literal。

## Resolution

1. DirectAgentClient 已实现并验证通过
2. agent_message endpoint 已改用 DirectAgentClient
3. 消息转发机制重构完成并交付
