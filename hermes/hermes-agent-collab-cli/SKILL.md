---
name: hermes-agent-collab-cli
description: Hermes Agent collab CLI setup and known __main__.py routing bug workaround
---

# Hermes Agent — collab CLI

## collab 命令可用性格式

```
collab monitor health    # 系统健康
collab monitor events   # 最近事件
collab monitor stats    # 统计信息
collab agent list       # Agent 列表
collab task list        # 任务列表
collab workspace list   # 工作空间列表
```

## 已知问题：__main__.py 路由 Bug

`~/.hermes/collab/__main__.py` 只实现了 `server` 子命令，其他子命令（monitor、agent、task 等）没有透传到 `cli.py`，导致：

```bash
python -m collab monitor health
# 报错: argument command: invalid choice: 'monitor' (choose from 'server')
```

## 解决方案

### 方案 1：Wrapper 脚本（推荐）

创建 `~/bin/collab`：
```bash
mkdir -p ~/bin
cat > ~/bin/collab << 'EOF'
#!/usr/bin/env python3
import sys
from pathlib import Path
collab_dir = Path.home() / ".hermes"
sys.path.insert(0, str(collab_dir))
from collab.cli import main as cli_main
if __name__ == "__main__":
    cli_main()
EOF
chmod +x ~/bin/collab
```

添加到 `~/.bash_aliases`：
```bash
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bash_aliases
```

### 方案 2：直接调用

```bash
cd ~/.hermes && python3 -c "from collab.cli import main; import sys; sys.argv = ['collab', 'monitor', 'health']; main()"
```

## 验证

```bash
source ~/.bash_aliases  # 或新开终端
collab monitor health
# System Health: HEALTHY
#   Connected Agents: 0
#   Events (5min): 0
#   Errors (5min): 0
#   Total Events: 0
```

---

## 协作服务器消息转发（collab-server → AIAgent）

### 架构

collab-server (FastAPI, port 9119) 的 `/api/collab/agents/{agent_id}/message` endpoint 将消息转发给 Hermes AIAgent。

旧方案：使用 ACP adapter (`python -m acp_adapter.entry`) 通过 asyncio stdio 通信。  
新方案（当前）：直接 subprocess 调用 AIAgent。

### 已知问题：API Key 传递失败

**症状**：`collab-server` 调用 agent message 时返回 `APIConnectionError` 或超时。

**根因**：AIAgent 对 `provider="minimax-cn"` 使用 `effective_key = api_key or ""`，这会跳过 `resolve_anthropic_token()` 的所有检查（包括 `MINIMAX_CN_API_KEY`）。

`resolve_anthropic_token()` 只检查：
1. `ANTHROPIC_API_KEY` 环境变量
2. `CLAUDE_CODE_OAUTH_TOKEN`
3. Claude Code 凭证文件
4. `ANTHROPIC_API_KEY`（再次）

**它不检查 `MINIMAX_CN_API_KEY`**。

**修复**：在 subprocess 中，要么显式传递 `api_key` 参数给 AIAgent 构造函数，要么设置 `ANTHROPIC_API_KEY` 环境变量：

```python
# 方式 1：设置 ANTHROPIC_API_KEY（推荐，一行代码）
os.environ["ANTHROPIC_API_KEY"] = os.environ.get("MINIMAX_CN_API_KEY", "")

# 方式 2：显式传递 api_key
ag = AIAgent(api_key=os.environ.get("MINIMAX_CN_API_KEY", ""), ...)
```

### 已知问题：ACP Adapter Asyncio 失败

**症状**：运行 `python -m acp_adapter.entry` 报错 `KeyError: "0 is not registered"`

**根因**：asyncio selector 无法在此沙盒环境中注册 fd 0（标准输入）。这是环境限制，不是代码 bug。

**影响**：ACP adapter 方式的消息转发在此环境不可用。collab-server 已改用 subprocess 直接调用 AIAgent。

### 快速测试消息转发

```bash
# 1. 启动/重启 collab-server
cd ~/.hermes/workspace-dev/proposals/hermes-agent-collab
pkill -f "collaboration.server" 2>/dev/null
nohup ~/.hermes/hermes-agent/venv/bin/python -m collaboration.server --host 0.0.0.0 --port 9119 > /tmp/collab-server.log 2>&1 &
disown

# 2. 测试 endpoint（应返回 "Agent not found"，说明 server 正常）
curl -s -X POST http://localhost:9119/api/collab/agents/test-agent/message \
  -H "Content-Type: application/json" \
  -d '{"content": "hello"}'

# 3. 测试 subprocess 直接调用（验证 API key 传递）
~/.hermes/hermes-agent/venv/bin/python -c "
import subprocess, os, sys
from pathlib import Path
from dotenv import load_dotenv
load_dotenv(Path.home() / '.hermes' / '.env')
os.environ['ANTHROPIC_API_KEY'] = os.environ.get('MINIMAX_CN_API_KEY', '')
script = '''
import sys, os, yaml
from pathlib import Path
sys.path.insert(0, str(Path.home() / \".hermes\" / \"hermes-agent\"))
from run_agent import AIAgent
with open(Path.home() / \".hermes\" / \"config.yaml\") as f:
    cfg = yaml.safe_load(f)
m = cfg.get(\"model\", {})
ag = AIAgent(model=m.get(\"default\",\"MiniMax-M2.7\"), base_url=m.get(\"base_url\",\"\"),
             provider=m.get(\"provider\",\"\"), api_key=os.environ.get(\"MINIMAX_CN_API_KEY\",\"\"),
             platform=\"test\", quiet_mode=True, verbose_logging=False)
print(ag.chat(\"Hi\"), flush=True)
'''
r = subprocess.run([sys.executable, '-c', script], capture_output=True, text=True, timeout=60)
print('stdout:', r.stdout[:100], 'rc:', r.returncode)
"
```

### DirectAgentClient 实现位置

`~/.hermes/workspace-dev/proposals/hermes-agent-collab/collaboration/acp_client.py`  
（虽名为 acp_client，实际是 DirectAgentClient，使用 subprocess 方式）
