---
name: godot-web-deploy-headers
description: Godot 4 HTML5 Web 部署踩坑指南 — GitHub Pages 无法运行 Godot 4 Web 导出的根因（SharedArrayBuffer/COOP/COEP）及解决方案
triggers:
  - Godot 4 HTML5 导出后 GitHub Pages 404 或 SharedArrayBuffer 报错
  - Godot 4 Web 导出报 Cross Origin Isolation 错误
  - 考虑降级 Godot 4 到 3.x 以支持 GitHub Pages 部署
---

# Godot 4 Web 部署：SharedArrayBuffer / COOP/COEP 问题

## 核心问题

Godot 4.2 HTML5 导出**始终依赖** `SharedArrayBuffer`，这需要服务器发送以下 HTTP 响应头：
- `Cross-Origin-Opener-Policy: same-origin`
- `Cross-Origin-Embedder-Policy: require-corp`

**GitHub Pages 不支持自定义响应头**，所以即使构建成功，浏览器也无法运行。

## 常见误区

❌ **`variant/thread_support=false` 不能解决此问题**
- 这是 Godot 4.2 架构层面的要求
- 无论是否启用线程，Godot 4 Web 导出都需要 SharedArrayBuffer
- 错误信息 "Cross Origin Isolation" 和 "SharedArrayBuffer" 都会出现

## 解决方案

### 方案 A：换用支持自定义 headers 的托管服务（推荐）

| 服务 | 免费额度 | 自定义 headers | 说明 |
|------|---------|---------------|------|
| **Cloudflare Pages** | 500 builds/月 | ✅ 支持 | 最推荐，免费额度充足 |
| **Netlify** | 100GB/月 | ✅ 支持 | 配置简单 |
| **Vercel** | 100GB/月 | ❌ 不支持 | 不适用 |
| **GitHub Pages** | ✅ | ❌ 不支持 | 不可用 |

#### Netlify 部署（推荐，工作流成熟）

**前置条件**：
1. Netlify 账号 + Personal Access Token (`nfp_xxx`)
2. GitHub repo 已配置 secrets: `NETLIFY_AUTH_TOKEN` 和 `NETLIFY_SITE_ID`

**workflow 配置**（GitHub Actions）：

```yaml
  deploy-netlify:
    needs: build-web
    runs-on: ubuntu-22.04
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Download Web Build
        uses: actions/download-artifact@v4
        with:
          name: web_build
          path: dist/

      - name: Copy netlify.toml for headers
        run: cp netlify.toml dist/

      - name: Deploy to Netlify
        uses: nwtgck/actions-netlify@v3.0
        with:
          publish-dir: ./dist
          production-deploy: true
          deploy-message: "Deploy from GitHub Actions"
        env:
          NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
          NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}
        timeout-minutes: 5
```

**关键**：`netlify.toml` 必须复制到 `dist/` 目录内，不能只在仓库根目录。只在 Netlify site 设置中 API 配置 headers 不生效。

**netlify.toml 格式**（放在 dist/ 内。注意：Godot Web 导出到 `bin/web/`，不是项目根目录）：
```toml
[build]
  publish = "bin/web"

[[headers]]
  for = "/*"
  [headers.values]
    Cross-Origin-Opener-Policy = "same-origin"
    Cross-Origin-Embedder-Policy = "require-corp"
    Cross-Origin-Resource-Policy = "cross-origin"
```

**创建 Netlify site 并获取 site_id**：
```bash
curl -X POST "https://api.netlify.com/api/v1/sites" \
  -H "Authorization: Bearer <token>"
# 返回的 id 即 NETLIFY_SITE_ID
```

**通过 API 设置 secrets**：
```bash
# 需先获取 repo public key
curl -s "https://api.github.com/repos/<owner>/<repo>/actions/secrets/public-key" \
  -H "Authorization: token <gh_token>"

# 用 gh CLI 更简单
echo "<token>" | gh secret set NETLIFY_AUTH_TOKEN --repo <owner>/<repo>
echo "<site_id>" | gh secret set NETLIFY_SITE_ID --repo <owner>/<repo>
```

#### Cloudflare Pages 部署

**Token 要求**：
- **资源类型**：Account（不是 Zone）
- **最低权限**：`Account:Pages:Edit`
- 创建：https://dash.cloudflare.com/profile/api-tokens → Create Custom Token

⚠️ **Zone:Pages 权限不适用**：Zone 级别权限只针对 DNS 区域，不包含 Pages 项目管理。API 返回 `{"code": 7000, "message": "No route for that URI"}` 说明 token 权限范围不对。

**Headers 配置**：在项目根目录添加 `_headers` 文件：
```
/*
  Cross-Origin-Opener-Policy: same-origin
  Cross-Origin-Embedder-Policy: require-corp
```

### 方案 B：降级到 Godot 3.x

Godot 3.x HTML5 导出**不需要** SharedArrayBuffer，GitHub Pages 可以正常运行。

**降级工作量**（项目规模 ~15 个 .gd 文件）：
- `project.godot`: `config_version=5` → `config_version=4`，`config/features` 语法变化
- `autoload` 语法变化
- Typed signals (`signal name(args: Type)`) → `signal name()` + 类型检查移除
- `await` → `yield`（Godot 3 不用 await）
- `Array[String]` → `PoolStringArray` 或普通 `Array`
- `@export` → `export`（Godot 3 不用 @）
- `@onready` → `onready`
- `Color.WHITE` → `Color.white`
- `inventory.remove_at(idx)` → `inventory.remove(idx)`
- `str.rsplit()` 参数顺序可能不同
- CI workflow 需要下载 Godot 3.5.3 + export templates（比 Godot 4 多一步）

**评估：除非有特殊理由必须用 Godot 3.x，否则不推荐降级**

## 验证方法

部署后打开浏览器控制台，检查是否有：
```
The following features required to run Godot projects on the Web are missing:
Cross Origin Isolation
SharedArrayBuffer
```
有则说明 headers 未正确配置。

## 新问题：GL_INVALID_ENUM（headers 正常但 WebGL 渲染失败）

**现象**：COOP/COEP headers 已正确送达（`SharedArrayBuffer` 可用），但浏览器控制台持续报错：
```
[.WebGL-0x...] GL_INVALID_ENUM: Invalid cap.
```
页面显示 "HTML5 canvas appears to be unsupported" 或白屏。

**根因**：Godot 4.2 的 WebGL 渲染器在初始化时请求了某些浏览器不支持的 OpenGL capability。这是 Godot 4.2 的已知 bug，与 headers 无关。

**错误信息演变**（随着版本升级）：
- Godot 4.2 + headers 正常 → `GL_INVALID_ENUM: Invalid cap`（WebGL 初始化失败）
- Godot 4.4.1 + headers 正常 → 不同错误（通常直接显示 canvas 加载中）

**解决方向（经验证）**：

1. ~~升级 Godot 到 4.4.1~~ — ❌ 经验证无效，4.4.1 仍有 GL_INVALID_ENUM。技能内旧说法有误。

2. ~~切换渲染器到 gl_compatibility~~ — ❌ 经验证无效，`renderer/rendering_method="gl_compatibility"` 仍有同样错误。

3. ~~启用多线程模式~~ — `variant/thread_support=true` **不能**解决 GL_INVALID_ENUM。

4. **降级到 Godot 3.x** — 唯一经验证可彻底绕开此问题的方案，但有迁移成本（见方案 B）。

5. **在 Godot Editor 里操作** — 如果 boss 愿意装 Godot Editor（~80MB），可以在本地打开项目，在 Editor → Project Settings → Rendering 里改渲染器为 Compatibility，然后重新 export web。这是无需代码迁移的方案。

**GL_INVALID_ENUM 错误在 Godot 4.x 全系列（4.2.2、4.4.1）均存在**，是 Godot 4 WebGL 渲染器的已知问题。降级到 3.6 LTS 是目前唯一确认有效的解法。

**验证 SharedArrayBuffer 可用**（在浏览器控制台）：
```js
typeof SharedArrayBuffer !== 'undefined'  // 应返回 true
document.crossOriginOpenerPolicy            // 应返回 'same-origin'
document.crossOriginEmbedderPolicy          // 应返回 'require-corp'
```

**游戏资源加载中的诊断**：
- 如果看到 `<progress value="575919" max="44209414">` 这样的进度条，说明 .pck 和 .wasm 正在下载
- "Your browser does not support the canvas tag" 是无 GPU 环境的 fallback 消息，真实浏览器中正常
- 控制台 `[] js_errors: []` 为空 ≠ 游戏正常运行，需检查 canvas 是否实际渲染

## 经验总结

- Godot 4 Web 部署问题 90% 是 headers 配置问题，不是构建问题
- **headers 正常 ≠ Godot 能正常运行** — 还需关注 GL 渲染器初始化错误
- GitHub Actions build 成功 ≠ 网站能正常运行
- 启用 GitHub Pages 本身不会报错，报错的是 Godot 运行时的浏览器检查
- 优先选择支持自定义 headers 的托管服务，降级是最后手段
- **Netlify**：nwtgck/actions-netlify@v3 的 `deploy-netlify` step 会自动应用 netlify.toml，但该文件必须在 `publish-dir` 目录内。仓库根目录的 netlify.toml 不会被读取。
- **验证 headers**：部署后用 `curl -sI https://<url>/index.html | grep -i cross-origin` 检查响应头
- **Cloudflare Pages token 权限**：必须选 Account 级别（不是 Zone），最低权限 `Account:Pages:Edit`；Zone:Pages 权限不包含 Pages 项目管理
