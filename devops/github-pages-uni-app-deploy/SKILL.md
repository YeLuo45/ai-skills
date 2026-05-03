---
name: github-pages-uni-app-deploy
description: uni-app H5 部署到 GitHub Pages 子目录的正确流程（manifest.json router.base 配置 + Git Data API 推送 dist）
---

# uni-app H5 部署到 GitHub Pages（子目录）

## 触发条件
- uni-app 项目需要部署到 GitHub Pages 的子路径（如 `https://user.github.io/repo-name/`）
- GitHub Actions 不可用或不稳定，需要本地构建后推送

## 核心问题
uni-app H5 构建产物中的资源路径是绝对路径 `/assets/...`，如果不配置 `router.base`，部署到子目录后资源 404 导致白屏。

## 标准流程

### 1. 构建前：配置 manifest.json

在 `src/manifest.json` 的 H5 配置中添加：

```json
"h5" : {
    "router" : {
        "base" : "/{REPO_NAME}/"
    }
}
```

其中 `{REPO_NAME}` 是仓库名（如 `future-little-leaders`）。

**关键：此配置必须在构建前完成，构建后修改无效，必须重新构建。**

### 2. 本地构建

```bash
npm install
npm run build:h5

# 关键：创建 .nojekyll，禁用 Jekyll 对 _plugin-*.js 等文件的过滤
touch dist/build/h5/.nojekyll
```

产物在 `dist/build/h5/`。

### 3. 构建后：添加 .nojekyll（关键！）

**uni-app 打包后的文件大量带下划线前缀**（如 `assets/_plugin-vue_export-helper.js`、`chunks/plugins/_plugin-vue_export-helper.js`）。GitHub Pages 默认启用 Jekyll，Jekyll 会忽略文件名以 `_` 开头的文件（认为是草稿/模板），导致这些资源全部 404。

必须在推送前创建 `.nojekyll` 文件禁用 Jekyll：

```bash
touch dist/build/h5/.nojekyll
```

**注意：这个文件必须存在于 gh-pages 分支的根目录**，每次推送 dist 时都要保留。

### 4. 推送 dist 到 gh-pages

两种方式：

**方式 A：Git Data API（网络不稳定时更可靠）**

```python
import urllib.request, json, base64, os, time

token = "ghp_..."
owner, repo = "user", "repo-name"
dist_dir = "dist/build/h5"

files = []
for root, dirs, fnames in os.walk(dist_dir):
    for fname in fnames:
        full_path = os.path.join(root, fname)
        rel_path = os.path.relpath(full_path, dist_dir)
        with open(full_path, "rb") as f:
            content = base64.b64encode(f.read()).decode()
        files.append((rel_path, content))

def upload_blob(content_b64, retries=4):
    for attempt in range(retries):
        try:
            req = urllib.request.Request(
                f"https://api.github.com/repos/{owner}/{repo}/git/blobs",
                data=json.dumps({"content": content_b64, "encoding": "base64"}).encode(),
                headers={"Authorization": f"token {token}", "Content-Type": "application/json"}
            )
            with urllib.request.urlopen(req, timeout=45) as r:
                return json.loads(r.read())["sha"]
        except:
            if attempt < retries - 1:
                time.sleep(3)
    return None

blob_shas = {}
for i, (path, content) in enumerate(files):
    sha = upload_blob(content)
    if sha:
        blob_shas[path] = sha
    if (i+1) % 20 == 0:
        print(f"  {i+1}/{len(files)}")

# .nojekyll 必须包含，禁用 Jekyll（否则 _plugin-*.js 等文件全部被过滤）
with open(os.path.join(dist_dir, ".nojekyll"), "rb") as f:
    nojekyll_sha = upload_blob(base64.b64encode(f.read()).decode())
blob_shas[".nojekyll"] = nojekyll_sha

# 获取当前 gh-pages SHA
req = urllib.request.Request(f"https://api.github.com/repos/{owner}/{repo}/git/ref/heads/gh-pages")
req.add_header("Authorization", f"token {token}")
with urllib.request.urlopen(req, timeout=15) as r:
    ghp_sha = json.loads(r.read())["object"]["sha"]

# 创建 tree
tree_entries = [{"path": p, "mode": "100644", "type": "blob", "sha": s} for p, s in blob_shas.items()]
req = urllib.request.Request(
    f"https://api.github.com/repos/{owner}/{repo}/git/trees",
    data=json.dumps({"tree": tree_entries}).encode(),
    headers={"Authorization": f"token {token}", "Content-Type": "application/json"}
)
with urllib.request.urlopen(req, timeout=30) as r:
    new_tree_sha = json.loads(r.read())["sha"]

# 创建 commit
req = urllib.request.Request(
    f"https://api.github.com/repos/{owner}/{repo}/git/commits",
    data=json.dumps({"message": "Deploy H5 dist", "tree": new_tree_sha, "parents": [ghp_sha]}).encode(),
    headers={"Authorization": f"token {token}", "Content-Type": "application/json"}
)
with urllib.request.urlopen(req, timeout=15) as r:
    new_commit_sha = json.loads(r.read())["sha"]

# 更新 gh-pages
req = urllib.request.Request(
    f"https://api.github.com/repos/{owner}/{repo}/git/refs/heads/gh-pages",
    data=json.dumps({"sha": new_commit_sha}).encode(),
    headers={"Authorization": f"token {token}", "Content-Type": "application/json"}
)
with urllib.request.urlopen(req, timeout=15) as r:
    json.loads(r.read())
```

**方式 B：gh CLI（如网络稳定）**

```bash
gh auth login --with-token <<< 'ghp_...'
gh repo clone user/repo -- --depth=1
cd repo
git checkout gh-pages 2>/dev/null || git checkout --orphan gh-pages
rm -rf *
cp -r dist/build/h5/* .
git add .
git commit -m "Deploy H5 dist"
git push origin gh-pages
```

### 4. 配置 GitHub Pages

```bash
curl -X POST "https://api.github.com/repos/{owner}/{repo}/pages" \
  -H "Authorization: token {token}" \
  -d '{"build_type":"legacy","source":{"branch":"gh-pages","path":"/"}}'
```

### 5. 验证

```bash
curl -s "https://user.github.io/repo-name/" | grep -o 'src="/repo-name/assets/[^"]*"'
```

## 常见问题

### 白屏 + Vue 挂载点显示 `<!--app-html-->`
资源路径未匹配子目录。检查 `manifest.json` 的 `router.base` 是否配置正确，是否在构建前配置。修改后必须重新 `npm run build:h5`。

### 资源 404（特别是带下划线的 .js 文件）

**根因：GitHub Pages 默认启用 Jekyll**，Jekyll 忽略 `_` 开头的文件（认为是模板/草稿）。uni-app 打包产物中大量带 `_plugin-`、`chunks/` 前缀的文件会被静默过滤。

**解法**：在 gh-pages 根目录放 `.nojekyll` 文件。构建完成后：
```bash
touch dist/build/h5/.nojekyll
```
然后把这个文件一起推送到 gh-pages。

### GitHub Actions workflow 持续 failure
通常是 Actions 环境问题。用 Git Data API 直接推送 dist 绕过 Actions。

### API 上传 blob 超时
分小批量上传（每批 5 个），每批之间加 `time.sleep(1)`，约 100 个文件需 5-10 分钟。

### 仓库是私有的
需要先设为 public：`PATCH /repos/{owner}/{repo}` + `{"visibility": "public"}`，或 token 需要 `repo` scope。
