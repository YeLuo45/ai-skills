---
name: ai-subscription-web
description: AI 订阅内容聚合 Web 应用开发规范 — React + Vite + Ant Design + IndexedDB。多端独立架构（Web/小程序/PC），AI 模型适配器，RSS 抓取，CORS 代理，GitHub Pages 部署。适用场景：新项目初始化、RSS/Atom/JSON API 抓取功能开发、AI 模型接入（MiniMax/小米/智谱/Claude/Gemini）、GitHub Pages 部署。
category: software-development
---

# AI Subscription Web — 开发规范与技能

## 项目概述

AI 订阅内容聚合 Web 应用，提案 ID：`P-20260412-008`，已部署至 GitHub Pages：
- **访问地址**：https://yeluo45.github.io/ai-subscription/
- **GitHub 仓库**：https://github.com/YeLuo45/ai-subscription

## 技术栈

| 层 | 技术 | 说明 |
|----|------|------|
| 前端框架 | React 18 + Vite + TypeScript | `vite.config.ts` 中 `base: '/ai-subscription/'` |
| UI 组件库 | Ant Design 5 | 按需引入，主题定制 |
| 状态/存储 | React hooks + IndexedDB (Dexie) | localStorage 存订阅/设置，IndexedDB 存内容 |
| RSS 抓取 | 自研 `feedParser.ts` | allorigins CORS 代理 |
| AI 摘要 | 自研 `aiAdapter.ts` | 多模型 fallback 适配器 |
| 部署 | GitHub Actions | `.github/workflows/deploy.yml`，master 分支触发 |

## 目录结构

```
ai-subscription/
├── ai-subscription-web/           # Web 端主项目
│   ├── src/
│   │   ├── services/
│   │   │   ├── aiAdapter.ts       # AI 模型调用适配器
│   │   │   ├── feedParser.ts      # RSS/Atom/JSON API 抓取 + CORS 代理
│   │   │   ├── notifications.ts   # 浏览器通知
│   │   │   └── scheduler.ts       # 定时任务
│   │   ├── pages/
│   │   │   ├── Subscriptions.tsx  # 订阅源管理
│   │   │   ├── ContentList.tsx    # 内容列表
│   │   │   ├── Settings.tsx       # 设置页（模型配置）
│   │   │   └── Summary.tsx        # AI 摘要页
│   │   ├── types/index.ts         # 类型定义（含 PRESET_SUBSCRIPTIONS）
│   │   ├── utils/storage.ts       # localStorage 读写
│   │   └── App.tsx                # 根组件（含日志 Drawer）
│   └── vite.config.ts
├── shared/                         # 跨端共享代码
│   ├── ai-model-adapter.ts        # 共享 AI 适配器（miniapp/pc 用）
│   └── model-registry.ts          # 模型注册中心（独立系统）
├── ai-subscription-miniapp/        # uni-app 小程序端
├── ai-subscription-pc/             # Electron PC 端
└── docs/                           # 项目文档（Hermes 提案体系）
    ├── index.md                    # 文档索引
    ├── proposal.md                 # 原始提案 + 优化记录
    ├── prd.v1.md                   # PRD
    └── technical-solution.v1.md     # 技术方案
```

## 核心服务规范

### 1. RSS 抓取 — `feedParser.ts`

**CORS 代理**：使用 `cors-proxy-fallback-pattern` skill 中的并发竞争策略。
直连优先 + 多代理并发竞争（`Promise.allSettled`），不串行等待。

> 注意：单个 `api.allorigins.win` 对某些 URL（如 hnrss.org）会超时，不要单独使用。

**支持的格式**：RSS 2.0、Atom、JSON API（自动检测）

**预设订阅源**（`types/index.ts` 中的 `PRESET_SUBSCRIPTIONS`）：
- Hacker News、GitHub Trending、InfoQ、TechCrunch、MIT Tech Review
- VentureBeat AI、机器之心、AI Weekly、36氪、量子位
- 少数派、Solidot、品玩、极客公园

### 2. AI 模型适配器 — `aiAdapter.ts`

**URL 必须正确**（以下为验证过的正确端点）：

| 模型 | Provider | 正确 Base URL | 模型名 |
|------|----------|--------------|--------|
| MiniMax M2.7 | `minimax` | `https://api.minimax.chat/v1` | `MiniMax-M2.7` |
| 小米 MiLM | `xiaomi` | `https://api.xiaomimimo.com/v1` | `MiLM` |
| 智谱 GLM-4 | `zhipu` | `https://open.bigmodel.cn/api/paas/v4` | `glm-4` |
| Claude 3.5 | `claude` | `https://api.anthropic.com/v1` | `claude-3-5-sonnet-20241022` |
| Gemini 2.0 | `gemini` | `https://generativelanguage.googleapis.com/v1beta` | `gemini-2.0-flash` |

**常见错误 URL（不要用）**：
- ❌ `https://api.minimax.chat/v` — 缺少 `/1`
- ❌ `https://account.platform.minimax.io` — 小米旧域名
- ❌ `https://api.minimaxi.com/anthropic` — MiniMax CN 端点（非标准路径）

**调用格式**：
```typescript
// OpenAI 兼容格式（minimax、xiaomi、zhipu、gemini）
POST ${apiBaseUrl}/chat/completions
Body: { model, messages: [{role, content}], temperature, max_tokens }

// Claude 专用格式
POST ${apiBaseUrl}/messages
Headers: { 'x-api-key': apiKey, 'anthropic-version': '2023-06-01' }
Body: { model, messages: [{role, content}], temperature, max_tokens }

// Gemini 格式
POST ${apiBaseUrl}/models/${modelName}:generateContent?key=${apiKey}
```

**多模型 Fallback**：`AISummarizer` 按优先级顺序尝试各模型，第一个成功即返回。

### 3. 设置存储 — `utils/storage.ts`

```typescript
// 设置键
'ai_settings' → AppSettings (subscriptions, models, pushSettings)

// 内容存储（每个订阅源独立 key）
`ai_sub_content_${subscriptionId}` → ContentItem[] (最多50条)
```

### 4. 抓取日志系统

**类型定义**（`types/index.ts`）：
```typescript
export interface FetchLogEntry {
  id: string;
  subscriptionId: string;
  subscriptionName: string;
  url: string;
  level: 'success' | 'fail' | 'pending';
  message: string;
  duration?: number; // ms
  itemCount?: number;
  error?: string;
  timestamp: string;
}
export const MAX_FETCH_LOGS = 100;
```

**实现要点**：
- `fetchSubscription` 在 App.tsx 中改造，try/catch 三阶段调用 `addFetchLog`
- 状态存储在 App 组件的 `fetchStatus` state（用于表格 Badge）
- Header 右侧 🐛 按钮控制 Drawer 日志面板（Timeline 展示）
- 表格每行名称列通过 `getStatusBadge(record)` 显示 Badge

## 开发工作流

### 本地启动

```bash
cd ai-subscription-web
npm install
npm run dev     # 开发: http://127.0.0.1:5173
npm run build   # 生产构建
```

### 提交规范

每次提交应包含：
1. 改动的文件列表
2. 改动原因（对应哪个 issue/提案）

```bash
git add -A
git commit -m "fix: 修复 MiniMax API URL /v → /v1
- ai-subscription-web/src/services/aiAdapter.ts
- shared/ai-model-adapter.ts
- 同步修正 miniapp/pc 端相同问题"
git push origin master
```

### GitHub Pages 部署

GitHub Actions 自动监听 master 分支推送：
- Build：`npm ci && npm run build`（工作目录 `ai-subscription-web`）
- 产物上传：`actions/upload-pages-artifact@v3`
- 部署：`actions/deploy-pages@v4`

部署地址：`https://yeluo45.github.io/ai-subscription/`

**强制刷新缓存**：用户按 **Ctrl+Shift+R** 清除 HTTP 缓存

## 常见问题排查

### 抓取失败（CORS 错误）

1. 检查 `feedParser.ts` 是否正确使用 `needsProxy()` / `withProxy()`
2. 确认 allorigins.win 服务正常：`curl "https://api.allorigins.win/raw?url=https://hnrss.org/frontpage"`
3. 某些 RSS 源（如 Google News）无法通过代理，抓取失败属于正常

### AI 模型测试失败

1. 确认设置页中配置的 API Key 有效
2. 检查 Base URL 是否正确（见上方 AI 模型适配器表格）
3. 打开 DevTools → Network 面板，查看实际请求的 URL
4. 如果 URL 是旧的（`api.minimax.chat/v` 而非 `/v1`），说明浏览器缓存了旧 JS，执行 Ctrl+Shift+R

### 页面空白（GitHub Pages 部署后）

1. 检查浏览器控制台是否有 404 错误（JS/CSS 文件）
2. 确认 `vite.config.ts` 中 `base: '/ai-subscription/'` 正确
3. 确认 `dist/index.html` 中 asset 路径是相对路径（`./assets/`）而非绝对路径（`/ai-subscription/assets/`）

### 日志 Drawer 不显示

1. 确认 `App.tsx` 已导入 `Drawer`, `Timeline`, `Badge`, `Tag` 等组件
2. 检查 `fetchLogs` state 是否正确更新
3. 确认 `SubscriptionsPage` props 中传入了 `fetchStatus`
