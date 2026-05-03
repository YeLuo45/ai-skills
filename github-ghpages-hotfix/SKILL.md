---
name: github-ghpages-hotfix
description: GitHub gh-pages 热修复 Workflow — 更新部署产物时避免 422 错误
category: devops
tags: [github, gh-pages, deployment, hotfix]
version: 1.0.0
---

# GitHub gh-pages 热修复 Workflow

## 背景
gh-pages 分支有独立历史，直接用 GitHub Trees API 创建 commit 会报 422（非线性历史不允许无父commit）。

## 标准流程

### 方案A：clone + 修改 + push（推荐）
```bash
# 1. 克隆 gh-pages（浅克隆加速）
git clone --depth=1 --branch=gh-pages https://github.com/Yeluo45/别踩白块.git /tmp/gp-hotfix
cd /tmp/gp-hotfix

# 2. 替换 dist 目录
rm -rf dist
cp -r /path/to/new/dist dist

# 3. 提交并推送
git add -A
git commit -m "fix: 更新游戏逻辑"
git push origin gh-pages
```

### 方案B：git worktree（备用）
```bash
cd /path/to/repo
git worktree add /tmp/gp-push gh-pages
cd /tmp/gp-push
rm -rf dist && cp -r ../dist .
git add -A && git commit -m "fix" && git push
cd /path/to/repo && git worktree remove /tmp/gp-push
```

## 常见错误
- `422 Unprocessable Entity` → 用了 hash-object/mktree/commit-tree 无历史方式，避免
- 构建产物不更新 → 先确认 MD5 变了；Vite 缓存 bug 时直接删除 dist 后重新 build
- gh-pages 根目录有独立 index.html → GitHub Pages 服务的是根级，不是 dist/index.html

## Vite 缓存 bug workaround
修改源码后 build MD5 不变：
```bash
rm -rf dist && npm run build
ls -la dist/assets/*.js  # 确认 MD5 变化
```

## Vite 代码分割优化（减少首屏加载体积）

当 gh-pages 带宽受限时，大 JS 包会导致部分用户下载超时。

**目标**：首屏只加载 <50KB，vendor chunks 异步加载

```typescript
// vite.config.ts build.rollupOptions.output.manualChunks
manualChunks(id) {
  if (id.includes('node_modules/react/')) return 'vendor-react'
  if (id.includes('node_modules/zustand/')) return 'vendor-zustand'
  if (id.includes('node_modules/dexie/')) return 'vendor-dexie'
  if (id.includes('node_modules/@uiw/')) return 'vendor-editor'
  if (id.includes('node_modules/prosemirror/')) return 'vendor-prosemirror'
  if (id.includes('node_modules/codemirror/')) return 'vendor-codemirror'
  if (id.includes('node_modules/react-beautiful-dnd/')) return 'vendor-dnd'
  if (id.includes('node_modules/markdown-it/') || id.includes('node_modules/remark-')) return 'vendor-markdown'
  return 'vendor-misc'  // catch-all，但会较大
}
```

验证首屏只加载主 index.js：
```bash
cat dist/index.html | grep 'src='
# 确认只有 <script type="module" src="/path/assets/index-XXX.js">
```

## REST API 直接更新 gh-pages（当 git push 被阻塞时）

**场景**：git push 超时，但 GitHub API 可用。

**流程**（4步）：
1. `GET /git/refs/heads/gh-pages` → 获取远程当前 SHA
2. `POST /git/blobs` → 上传所有 dist 文件
3. `POST /git/trees?base_tree=<远程tree_sha>` → 只传变更文件，GitHub 自动合并未变的
4. `POST /git/commits?parents=[<远程SHA>]` → 创建 commit（fast-forward）
5. `PATCH /git/refs/heads/gh-pages` → 更新指针

**关键**：先 GET ref 获取远程当前 SHA，以它为 parent 创建新 commit，这样是 fast-forward 不会 422。

如果 dist 包含 >1MB 的大文件导致 blob 上传超时，改用 **GitHub Actions workflow** 方案触发云端构建：
```python
# 1. 先推送构建配置（通过 contents API）
PUT /repos/{owner}/{repo}/contents/.github/workflows/deploy.yml
body: {"content": "<base64_workflow>", "branch": "master"}

# 2. 触发 workflow
POST /repos/{owner}/{repo}/actions/workflows/deploy.yml/dispatches
body: {"ref": "master"}
```
