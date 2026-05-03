---
name: hermes-collab-web-deploy
description: Hermes 协作面板前端部署要点 — API路径问题、构建产物路径、数据模型转换
---

# Hermes Collab Web 前端部署要点

## 概述

Hermes 协作面板前端（hermes-collab-web）的部署有两个独立组件：

1. **React 前端** (`/home/hermes/hermes-collab-web/`) - Vite + React 构建
2. **FastAPI 后端** (`/home/hermes/.hermes/collab/`) - 协作服务器

## 关键发现

### 1. API 路径前缀问题

- **问题**：前端 `api.ts` 中 `API_BASE = '/api'`，但后端 FastAPI router 的 prefix 是 `/api/collab`
- **表现**：`GET /api/agents 404 (Not Found)`
- **修复**：`API_BASE = '/api/collab'`

### 2. 后端数据模型转换

后端返回 `agent_id`，前端期望 `id`。需要在 API 调用时进行转换：

```typescript
// 后端返回格式
{ agent_id: "xxx", name: "Test", role: "dev", status: "online", ... }

// 前端期望格式
{ id: "xxx", name: "Test", role: "dev", status: "idle", ... }
```

### 3. Status 状态映射

后端状态：`online` | `offline` | `busy` | `away` | `error`
前端状态：`idle` | `thinking` | `working` | `waiting` | `error` | `offline`

映射规则：`online` → `idle`，其余直接映射。

### 4. 构建产物路径

- React 构建输出：`/home/hermes/hermes-collab-web/dist/`
- Collab Server 期望：`/home/hermes/.hermes/hermes-collab-web/dist/`
- **必须手动复制**：`cp -r /home/hermes/hermes-collab-web/dist /home/hermes/.hermes/hermes-collab-web/`

### 5. ChatModal 硬编码路径

`ChatModal.tsx` 中直接使用 `fetch('/agents/...')` 而不是使用 `api.ts`，导致路径不一致。修复为 `fetch('/api/collab/agents/...')`。

## 部署步骤

```bash
cd /home/hermes/hermes-collab-web
npm run build
mkdir -p /home/hermes/.hermes/hermes-collab-web
cp -r dist /home/hermes/.hermes/hermes-collab-web/

# 重启协作服务器（如需要）
pkill -f "collab.server"
python3 -m collab.server --host 0.0.0.0 --port 9119 &
```

## 相关文件

- 前端源码：`/home/hermes/hermes-collab-web/src/`
- 后端代码：`/home/hermes/.hermes/collab/`
- 协作服务器启动：`python3 -m collab.server --host 0.0.0.0 --port 9119`

## 已知问题

- 消息转发机制缺失：EventBus 没有 handler 处理 AGENT_MESSAGE 事件
- AgentProfile 没有 `endpoint` 字段，无法指示如何联系 Agent 进程
- 需要提案 P-20260424-002 来修复消息转发机制
