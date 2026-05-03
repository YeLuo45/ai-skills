---
name: expo-web-github-pages-deploy
description: Deploy Expo (React Native) web exports to GitHub Pages — fixes underscore-prefixed dirs, absolute asset paths, and git subtree push workflow
category: devops
---

# Expo Web → GitHub Pages 部署指南

## 问题

`npx expo export --platform web` 输出的静态文件部署到 GitHub Pages 子目录时出现 404。

## 已知问题

### 1. 绝对路径问题

Expo 导出的 `index.html` 使用绝对路径：

```html
<link rel="shortcut icon" href="/favicon.ico" />
<script src="/_expo/static/js/web/AppEntry-xxx.js" defer></script>
```

在根路径部署（`https://username.github.io/repo/`）时正常；
在子目录部署（`https://username.github.io/calculator-app/`）时 404。

**修复：** 改为相对路径：

```bash
sed -i 's|href="/favicon.ico"|href="favicon.ico"|g' dist/index.html
sed -i 's|src="/_expo/|src="_expo/|g' dist/index.html
# 如果还重命名了 _expo：
sed -i 's|src="_expo/|src="expo-static/|g' dist/index.html
```

### 2. 下划线目录被 Jekyll 忽略

`_expo`、`_chunk`、`_plugin-*` 等目录在 GitHub Pages 上返回 404（GitHub Pages 默认用 Jekyll 处理，Jekyll 忽略以 `_` 开头的文件和目录）。

**修复（二选一）：**

**方案 A（推荐）：** 重命名目录去掉下划线

```bash
cd dist
mv _expo expo-static
# 然后更新 index.html 中的引用：
sed -i 's|src="_expo/|src="expo-static/|g' index.html
```

**方案 B：** 添加 `.nojekyll`

```bash
touch dist/.nojekyll
```

方案 A 更干净，不影响 Jekyll 对其他文件的处理。

### 3. `npx expo export` 不支持 `--base-path`

Expo 的 `export` 命令没有 `--base-path` 或类似参数来自动重写资源路径。必须手动 patch 或使用 Vite 等其他构建工具。

## 部署流程（git subtree 方式）

当 `dist/` 已 commit 到 source repo 时，使用 `git subtree push`：

```bash
# 1. 确保 dist/ 在 source repo 中
git add -f dist/
git commit -m "Build web export"

# 2. 推送到 gh-pages 子树
git subtree push --prefix=dist origin gh-pages
```

如果 `dist/` 不在 git 中（.gitignore），用 `git checkout --orphan` 方式：

```bash
git clone https://github.com/OWNER/REPO.git /tmp/ghpages
cd /tmp/ghpages
git checkout --orphan gh-pages
git reset --hard
cp -r /path/to/project/dist/* .
touch .nojekyll  # 如果用方案 B
git add .
git commit -m "Deploy"
git push origin gh-pages
```

## 验证

部署后访问 `https://username.github.io/repo-name/`，检查：

1. 页面是否正常加载（不是空白页）
2. 浏览器 Network 面板无 404 资源
3. JS bundle 可访问：`https://username.github.io/repo-name/expo-static/static/js/web/AppEntry-xxx.js`

## 目录结构（gh-pages 正确示例）

```
gh-pages/
  index.html           ← 直接在根目录
  expo-static/         ← 不是 _expo
    static/js/web/
      AppEntry-xxx.js
  assets/
  favicon.ico
```

## 相关技能

- `github-pages-underscore-404` — 下划线文件 404 的通用说明
- `github-pages-deploy` — 完整的 GitHub Pages 部署工作流
