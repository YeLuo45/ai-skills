---
name: hermes-collab-frontend-debug
description: Hermes 协作面板前端调试 - React 状态问题定位与修复，包含字段名映射、React Fiber introspection 和生产构建分析
tags: [hermes, react, frontend, debugging, websocket]
---

# Hermes Collaboration Frontend Debugging

## Context

Hermes 协作面板 (`http://172.24.124.156:9119/`) 的"与Agent对话"功能无法发送消息。问题根源是**前端字段名与后端不一致**导致 React 状态无法正确更新。

## 关键文件

- `/home/hermes/hermes-collab-web/src/components/ChatModal.tsx` - 聊天弹窗组件
- `/home/hermes/hermes-collab-web/src/useWebSocket.ts` - WebSocket 连接管理
- `/home/hermes/hermes-collab-web/src/types.ts` - TypeScript 类型定义

## 发现的 Bug（多层级）

### Bug 1: API 字段名错误

**问题**: 前端发送 `{ message: currentInput }`，后端期望 `{ content: ... }`

**位置**: ChatModal.tsx 的 sendMessage 函数

```javascript
// 错误
body: JSON.stringify({ message: currentInput })

// 正确
body: JSON.stringify({ content: currentInput })
```

**响应字段**: 前端用 `data.response || data.message`，后端返回 `data.content`

```javascript
// 错误
content: data.response || data.message || "收到消息"

// 正确
content: data.content || "收到消息"
```

### Bug 2: Agent ID 字段不匹配（致命）

**问题**: 后端 WebSocket 发送的 agent 数据用 `agent_id` 字段，但前端 ChatModal.tsx 访问 `agent.id`

**现象**: Console 显示 `[DEBUG] Agent clicked: undefined 测试架构师`

**修复**: 在 useWebSocket.ts 添加 transformAgent 函数：

```typescript
const transformAgent = (a: any) => ({
  id: a.id || a.agent_id,
  name: a.name,
  description: a.description,
  workspaceId: a.workspaceId || a.workspace_id,
  status: a.status || 'online',
  capabilities: a.capabilities || [],
});

const transformedAgents = data.payload.agents.map(transformAgent);
```

### Bug 3: types.ts 缺少 workspaceId 字段

**修复**: 在 Agent 接口添加 `workspaceId?: string`

## 调试方法

### 1. React Fiber Introspection（调试状态不更新）

当 `browser_type` 无法触发 React 的 `onChange` 时，用这个方法检查 React 内部状态：

```javascript
// 检查 textarea 的 __reactFiber$ 属性
document.querySelector('textarea[placeholder="输入消息..."]').__reactFiber$)

// 在元素上找 state node
el => el.dispatchEvent(new InputEvent('input', { bubbles: true }))
```

### 2. 生产构建分析（定位变量映射）

Vite 生产构建后，变量名被压缩。用以下方法定位：

```bash
# 检查特定 API 调用的压缩结果
grep -o 'content:[a-z]' dist/assets/*.js
grep -o '"message":[a-z]' dist/assets/*.js
```

关键映射（压缩后）：
- `content:le` = `content: data.content`
- `pe.content` = `data.content`
- `j` = `chatAgentId`
- `H` = `currentInput`
- `Z` = `setInputValue`
- `b` = `sendMessage`

### 3. Console Debug 日志

在 ChatModal.tsx 添加调试日志：

```javascript
console.log('[DEBUG] Agent clicked:', agent.id, agent.name);
console.log('[DEBUG] sendMessage called', { inputValue, chatAgentId, isLoading });
```

## 部署流程

```bash
cd /home/hermes/hermes-collab-web
npm run build
# 修改 dist/index.html 中的 JS 文件引用
# 重新上传到服务器
```

## 关键教训

1. **browser_type 不触发 React onChange**: 自动化工具（如 `browser_type`）不会触发 React 的 synthetic event，需要用 `nativeSetter + Event` 手动触发

2. **后端用 `agent_id`，前端用 `id`**: 这是最隐蔽的 bug，Console 显示 `undefined` 容易误判为"点击事件没触发"

3. **字段名一致性**: 前后端 API 交互必须确保字段名完全一致，常见错误：
   - `message` vs `content`
   - `response` vs `content`
   - `id` vs `agent_id`
   - `workspace_id` vs `workspaceId`

4. **生产构建后变量压缩**: 调试生产问题时，需要分析压缩后的变量映射
