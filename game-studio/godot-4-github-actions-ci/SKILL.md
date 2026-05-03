---
name: godot-4-github-actions-ci
description: Godot 4 GitHub Actions CI 构建指南 - 解决常见的 GitHub Actions 构建问题
---

# Godot 4 GitHub Actions CI 构建指南

## 触发条件
使用 GitHub Actions 自动构建 Godot 4 项目（Windows/macOS/Linux/Web 平台）时参考此技能。

## 已知问题与解决方案

### 1. Windows runner 没有 wget
**问题**：Windows runner 上 `wget` 命令不存在
**解决**：统一使用 `curl -sL <url> -o <output>` 替代 wget

### 2. Godot 导出需要 export_presets.cfg
**问题**：Godot headless 导出时报错 "This project doesn't have an export_presets.cfg file"
**解决**：
- 在项目根目录创建 `export_presets.cfg`
- **重要**：从 `.gitignore` 中移除 `export_presets.cfg`，否则 CI 无法访问
- Preset 名称必须与 Godot 编辑器中的名称完全一致（如 "Windows"、"Linux"、"macOS"、"Web"）

### 3. workflow 中使用 preset 名称而非平台名称
**问题**：错误 `Invalid export preset name: linux.x86_64`
**原因**：Godot 4 的 `--export-release` 参数需要 **preset 名称**（"Linux"），不是平台标识符（"linux.x86_64"）

正确示例：
```bash
./Godot_v4.2.2-stable_linux.x86_64 --headless --export-release "Linux" bin/linux_build
./Godot_v4.2.2-stable_win64.exe --headless --export-release "Windows" bin/windows.exe
```

### 4. macOS 构建产物是 .app 目录
**问题**：Godot macOS 下载后是 `.zip`，解压后是 `Godot.app` 目录，不是单一可执行文件
**注意**：不要对 zip 文件执行 chmod，解压后使用 `Godot.app/Contents/MacOS/Godot` 或直接解压到正确位置

### 5. Web 构建需要导出模板
**问题**：Web 平台导出需要 Godot export templates（~200MB）
```bash
# 下载并安装导出模板
curl -sL https://github.com/godotengine/godot/releases/download/4.2.2-stable/Godot_v4.2.2-stable_export_templates.tpz -o templates.tpz
mkdir -p ~/.local/share/godot/export_templates/4.2.2.stable/
unzip -o -q templates.tpz -d /tmp/templates
mv /tmp/templates/templates/* ~/.local/share/godot/export_templates/4.2.2.stable/
```

### 6. Godot 3.6.2 Linux 二进制命名（容易搞错）
**问题**：Godot 3.6.2 的 Linux 二进制文件名不是 `linux.x86_64`，而是：
- 普通版（含 X11 display）：`Godot_v3.6.2-stable_x11.64.zip`
- Headless 版（CI 用，必须）：`Godot_v3.6.2-stable_linux_headless.64.zip`
**CI 必须用 headless 版本**，因为 GitHub Actions Ubuntu runner 没有 X11 display。

### 7. project.godot 的 [input] 部分 JSON 必须在一行内
**问题**：`Expected '}' or ','` 解析错误
**解决**：input 部分的 JSON 必须在同一行，不能换行

### 8. Godot 4 WebGL GL_INVALID_ENUM 错误
**症状**：浏览器报 `GL_INVALID_ENUM: Invalid cap`，游戏无法启动
**原因**：Godot 4.x web 导出在某些浏览器环境请求不支持的 WebGL extension
**尝试**：将 `renderer/rendering_method` 改为 `gl_compatibility`（可能在部分环境有效）
**最终方案**：迁移到 Godot 3.6 LTS（见 `godot-web-gl-compatibility` 技能）
- `Array[Typed]` 需要确保类型类已加载
- `class_name Item` 定义后，其他脚本引用 Item 时需要确保 Item.gd 先被加载
- 建议在 autoload 脚本中避免循环依赖

### 9. Godot 4 类型声明注意事项
- `Array[Typed]` 需要确保类型类已加载
- `class_name Item` 定义后，其他脚本引用 Item 时需要确保 Item.gd 先被加载
- 建议在 autoload 脚本中避免循环依赖

## 完整 workflow 示例

```yaml
name: Build
on:
  push:
    branches: [master]

jobs:
  build:
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        include:
          - os: ubuntu-22.04
            artifact_name: linux_x86_64
            godot_binary: Godot_v4.2.2-stable_linux.x86_64
            godot_archive: Godot_v4.2.2-stable_linux.x86_64.zip
            preset_name: Linux
          - os: windows-2022
            artifact_name: windows.exe
            godot_binary: Godot_v4.2.2-stable_win64.exe
            godot_archive: Godot_v4.2.2-stable_win64.exe.zip
            preset_name: Windows
          - os: macos-14
            artifact_name: macos.zip
            godot_binary: Godot.app
            godot_archive: Godot_v4.2.2-stable_macos.universal.zip
            preset_name: macOS

    steps:
      - uses: actions/checkout@v4
      - name: Download Godot
        run: |
          curl -sL https://github.com/godotengine/godot/releases/download/4.2.2-stable/${{ matrix.godot_archive }} -o ${{ matrix.godot_archive }}
          unzip -o -q ${{ matrix.godot_archive }}
      - name: Build
        run: |
          mkdir -p bin
          ./${{ matrix.godot_binary }} --headless --export-release "${{ matrix.preset_name }}" bin/${{ matrix.artifact_name }}
      - uses: actions/upload-artifact@v4
        with:
          name: ${{ matrix.artifact_name }}
          path: bin/${{ matrix.artifact_name }}

  build-web:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - name: Download Godot
        run: |
          curl -sL https://github.com/godotengine/godot/releases/download/4.2.2-stable/Godot_v4.2.2-stable_linux.x86_64.zip -o godot.zip
          unzip -o -q godot.zip && chmod +x Godot_v4.2.2-stable_linux.x86_64
      - name: Download Templates
        run: |
          curl -sL https://github.com/godotengine/godot/releases/download/4.2.2-stable/Godot_v4.2.2-stable_export_templates.tpz -o templates.tpz
          mkdir -p ~/.local/share/godot/export_templates/4.2.2.stable/
          unzip -o -q templates.tpz -d /tmp/templates
          mv /tmp/templates/templates/* ~/.local/share/godot/export_templates/4.2.2.stable/
      - name: Build Web
        run: |
          mkdir -p bin/web
          ./Godot_v4.2.2-stable_linux.x86_64 --headless --export-release "Web" bin/web/index.html
      - uses: actions/upload-artifact@v4
        with:
          name: web_build
          path: bin/web/
```

## GitHub Pages 部署失败排查

### deploy-gh-pages 失败，Actions 日志显示 404
**症状**：`actions/deploy-pages@v4` 步骤失败，错误信息包含 404，但 build-web 步骤成功
**原因**：GitHub Pages 从未在仓库设置中启用，即使 workflow 配置正确也会失败
**排查**：用 `gh api repos/{owner}/{repo}/pages` 检查，返回 404 表示未配置
**解决**：通过 API 启用 GitHub Pages：
```bash
gh api repos/{owner}/{repo}/pages --method POST -f build_type=workflow -f source[branch]=master -f source[path]=/ 
```
或者在 GitHub 网页端：Settings → Pages → Source 选择 GitHub Actions

## GitHub Pages 无法部署 Godot Web（COOP/COEP 限制）

### 问题
Godot 4.x HTML5 导出需要 `SharedArrayBuffer`，而 `SharedArrayBuffer` 需要 Cross-Origin-Isolation。GitHub Pages **不支持设置 COOP/COEP 响应头**，这意味着：
- 即使 GitHub Pages 部署成功，Godot 4 web 导出会报 `Cross-Origin Isolation required!` 错误
- 游戏无法运行

### 解决方案
迁移到支持自定义响应头的平台，如 **Netlify**：
```toml
# netlify.toml
[[headers]]
  for = "/web_build/*"
    [headers.values]
      Cross-Origin-Opener-Policy = "same-origin"
      Cross-Origin-Embedder-Policy = "require-corp"
```

参考 workflow 示例（Netlify 部署）：
```yaml
  deploy-netlify:
    needs: build-web
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v4
        with:
          name: web_build
          path: dist/
      - run: cp netlify.toml dist/
      - uses: nwtgck/actions-netlify@v3.0
        with:
          publish-dir: ./dist
          production-deploy: true
        env:
          NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
          NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}
```

## .gitignore 注意事项

确保以下文件/目录不被忽略：
- `export_presets.cfg` - 必须提交到仓库供 CI 使用
- `.godot/` - 可以忽略（运行时生成）
- `bin/` - CI 输出目录，不需要提交
- `netlify.toml` - Netlify 部署必须，随 web_build 一起 cp 到 dist/
