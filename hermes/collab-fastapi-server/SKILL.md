---
name: collab-fastapi-server
description: Hermes Agent Collaboration FastAPI 服务器已知问题和修复模式
---

# Hermes Agent Collaboration — FastAPI Server

## 启动命令

```bash
cd ~/.hermes/workspace-dev/proposals/hermes-agent-collab
python3 -m collaboration.server --host 0.0.0.0 --port 9119
```

注意模块名是 `collaboration`，不是 `collab`。

## 已知问题与修复

### 1. RuntimeMonitor 未实例化 (500 错误)

`RuntimeMonitor` 是一个类，不是实例。在 `collab_api.py` 中如果直接引用 `monitor.xxx` 会报错 `Cannot read properties of undefined`。

**修复**：在模块级别实例化：
```python
from collaboration.monitor import RuntimeMonitor
monitor = RuntimeMonitor()
```

### 2. 模块级别变量在函数内部未定义 (500 错误)

如果代码这样写：
```python
def _get_default_managers():
    man = {"agent_registry": AgentRegistry()}
    return man

# 后面这样调用：
agent_registry.get_agents()  # NameError: name 'agent_registry' is not defined
```

**修复**：使用懒加载访问器函数：
```python
_managers = None

def _get_default_managers():
    global _managers
    if _managers is None:
        _managers = {"agent_registry": AgentRegistry(), ...}
    return _managers

def _agent_registry():
    return _get_default_managers()["agent_registry"]
```

### 3. 同步函数在 async endpoint 中阻塞事件循环

`AIAgent.chat()` 是同步的，直接 `await` 会卡住整个事件循环。

**修复**：用线程池执行器：
```python
from concurrent.futures import ThreadPoolExecutor
executor = ThreadPoolExecutor(max_workers=4)

def _hermes_chat(message: str) -> str:
    from hermes.run_agent import AIAgent
    agent = AIAgent(config_path=Path.home() / ".hermes" / "config.yaml")
    return agent.chat(message)

@router.post("/agents/{agent_id}/message")
async def agent_message(agent_id: str, body: MessageBody):
    loop = asyncio.get_event_loop()
    content = await loop.run_in_executor(executor, _hermes_chat, body.content)
    return {"content": content}
```

### 4. 前端 `showTab` 在 async 后 `event.target` 为 undefined

`showTab` 依赖 `event.target` 设置激活 tab，但 `await fetch()` 后 `event` 已失效。

**修复**：传递 `this` 作为参数，并加 selector 回退：
```javascript
function showTab(name, el) {
  document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
  if (el && el instanceof HTMLElement) el.classList.add('active');
  else document.querySelector(`.tab[onclick*="${name}"]`)?.classList.add('active');
  // ... rest of tab logic
}
```

HTML 中：`onclick="showTab('agents', this)"`

### 5. Web UI 不在根路径 `/`

`server.py` 的 `get_web_dist()` 可能返回外部路径（如 `hermes-collab-web/dist`），但 UI 实际在 `collaboration/web/`。

**修复**：优先检查本地 web 目录：
```python
WEB_DIST_LOCAL = Path(__file__).parent / "web"
WEB_DIST_EXT = Path(__file__).parent.parent / "hermes-collab-web" / "dist"
FALLBACK_WEB_DIST = Path("/home/hermes/hermes-collab-web/dist")
```

## 调试命令

```bash
# 查看服务器状态
ps aux | grep collaboration.server

# 重启
kill $(pgrep -f "collaboration.server")
cd ~/.hermes/workspace-dev/proposals/hermes-agent-collab && python3 -m collaboration.server --host 0.0.0.0 --port 9119 &

# 测试 API（启动后）
curl http://localhost:9119/api/collab/agents
curl http://localhost:9119/api/collab/agents/{id}/message -X POST -H "Content-Type: application/json" -d '{"content":"hello"}'
```

## 关键文件

- `~/.hermes/workspace-dev/proposals/hermes-agent-collab/collaboration/server.py` — FastAPI 服务器
- `~/.hermes/workspace-dev/proposals/hermes-agent-collab/collaboration/collab_api.py` — API 路由
- `~/.hermes/workspace-dev/proposals/hermes-agent-collab/collaboration/web/index.html` — Web UI
