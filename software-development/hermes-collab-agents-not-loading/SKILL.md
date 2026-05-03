---
name: hermes-collab-agents-not-loading
description: 调试 Hermes 协作面板 Agent/Task 不显示的问题 — 前后端双重 bug 排查
tags: [hermes, collaboration, debugging, websocket, frontend, backend]
---

# Hermes 协作面板 Agent/Task 不显示排查

## 问题
访问 http://172.24.124.156:9119/ 显示 "Agent 状态：在线 0 / 0" 和 "任务列表：0 个任务"，但后端实际有数据。

## 根本原因（双重 bug）

### Bug 1 — 前端 API 解析错误
文件：`/home/hermes/hermes-collab-web/src/api.ts`

`agentApi.list()` 收到后端 `{agents: [...]}` 对象，但代码直接调 `res.data.map()`，导致 `f.data.map is not a function`。

修复：
```typescript
// 错误：request<any[]> 期待返回数组
return request<any[]>('GET', '/agents').then(res => {
  if (res.success && res.data) {
    res.data = res.data.map((a) => ({  // ❌ res.data 是 {agents: [...]} 对象，不是数组
// 正确：
return request<any>('GET', '/agents').then(res => {
  if (res.success && res.data) {
    const agents = res.data.agents || [];
    res.data = agents.map((a: any) => ({  // ✅
```

### Bug 2 — 后端 WebSocket init 硬编码空数组
文件：`/home/hermes/workspace-dev/proposals/hermes-agent-collab/collaboration/collab_api.py`

WebSocket 连接时发送的 `init` 消息中 agents/tasks/skills 是硬编码的空数组。

```python
# 错误：
await websocket.send_json({
    "type": "init",
    "payload": {
        "agents": [],    # ❌ 硬编码
        "tasks": [],     # ❌ 硬编码
        "skills": []     # ❌ 硬编码
    }
})

# 正确：
await websocket.send_json({
    "type": "init",
    "payload": {
        "agents": [a.to_dict() for a in _agent_registry().list_agents()],
        "tasks": [t.to_dict() for t in _task_manager().list_tasks()],
        "skills": [s.to_dict() for s in _skill_system().list_skills()]
    }
})
```

注意：`list_agents()` 返回 Agent 对象列表，需要 `.to_dict()` 才能 JSON 序列化。

## 调试方法

### 1. 确认症状
浏览器访问页面，检查显示的 agent/task 数量。

### 2. 检查前端 JS 是否加载正确版本
```javascript
// 浏览器控制台
document.querySelector('script[type=module]')?.src
```

### 3. 验证后端 REST API
```bash
curl -s http://172.24.124.156:9119/api/collab/agents
curl -s http://172.24.124.156:9119/api/collab/tasks
```
如果 API 返回有数据但页面不显示 → 前端问题。

### 4. 检查 WebSocket init 消息（关键步骤）
```bash
curl -s --include --no-buffer \
  -X GET "http://172.24.124.156:9119/api/collab/ws" \
  -H "Connection: Upgrade" -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ=="
```
返回的 `init` 消息中 `payload.agents` 如果是 `[]` → 后端 bug。

### 5. 找服务器进程
```bash
ps aux | grep "collaboration.server" | grep -v grep
```

### 6. 重启服务器
```bash
kill <PID>
cd ~/.hermes/workspace-dev/proposals/hermes-agent-collab
python3 -m collaboration.server --host 0.0.0.0 --port 9119 &
```

## 关键文件路径

| 用途 | 路径 |
|------|------|
| 前端 React 源码（可写） | `/home/hermes/hermes-collab-web/` |
| 前端构建产物（服务器使用） | `~/.hermes/hermes-collab-web/dist/` |
| 后端源码 | `~/.hermes/workspace-dev/proposals/hermes-agent-collab/collaboration/` |
| 全局 collab 数据 | `~/.hermes/collab/` |
| 服务器启动命令 | `python3 -m collaboration.server`（注意不是 `collab.server`） |

## 教训

1. **同一症状可能有多个 bug 同时存在**：这次前端和后端各有一个 bug 导致同一个显示问题
2. **WebSocket init 消息容易被忽略**：容易假设它包含正确数据，实际可能是硬编码
3. **服务器加载的 dist 可能不是最近构建的**：需要确认 `~/.hermes/hermes-collab-web/dist/` 是否同步
4. **重启服务器才能让后端修改生效**：uvicorn 不会自动 reload Python 代码
