---
name: npm-global-install-wsl
description: npm 全局安装权限问题解决 — 适用于WSL/Linux环境权限受限的情况
triggers:
  - npm全局安装权限拒绝
  - npm install -g 失败
  - npm global bin permission denied
---

# npm 全局安装权限问题解决

## 问题

在 WSL/Linux 环境下执行 `npm install -g` 时报错：
```
npm ERR! permissions of the file and its containing directories
```

## 根本原因

系统级 npm 全局目录（`/usr/lib/node_modules` 或 `/usr/local/lib/node_modules`）需要 root 权限。

## 解决方案

### 1. 配置 npm 使用用户目录

```bash
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
export PATH=~/.npm-global/bin:$PATH
```

### 2. 安装全局包

```bash
npm install -g <package>
# 或
yarn add global <package>
pnpm add -g <package>
```

### 3. 验证

```bash
~/.npm-global/bin/<package> --version
```

---

## Node.js 版本兼容性

| Node.js | 可用 vite 版本 |
|---------|---------------|
| 18.x | vite 4.x (最高4.5.0) |
| 20.19+ / 22.12+ | vite 5.x |

> 注意：vite 5+ 需要 Node.js 20.19+ 或 22.12+，在 Node 18 上会报 `ReferenceError: CustomEvent is not defined`

---

## 常见问题

### 权限错误
```
npm ERR! permissions of the file...
```
→ 使用用户目录方案（见上文"解决方案"）

### Node版本不匹配
```
ReferenceError: CustomEvent is not defined
```
→ vite版本与Node版本不匹配，见下方兼容性表

### 网络超时（大包）
electron、pm2等超大包（>100MB）下载易中断：
- 方案1：重试几次可能成功
- 方案2：切换npm registry
```bash
# 切换到淘宝镜像
npm config set registry https://registry.npmmirror.com
# 切回官方
npm config set registry https://registry.npmjs.org
```

### Electron安装失败
electron包有postinstall脚本需要下载Chromium，常因网络问题中断：
- 可用`nw`(nwjs)作为替代，轻量级桌面应用框架
```bash
npm install -g nw nwjs-builder
```
- 或在项目本地安装而非全局

## WSL开发桌面应用的限制

WSL无原生GUI支持，Electron/NW.js等桌面框架无法直接运行和调试：
- 编码和打包可在WSL完成
- 实际运行调试需在Windows本机
- 考虑使用远程开发（Windows上VS Code SSH到WSL）

---

## 快速检查命令

```bash
# 检查 Node 版本
node --version

# 检查 npm 全局目录
npm config get prefix

# 检查已安装的全局包
npm list -g --depth=0
```

---

## 适用环境

- WSL (Windows Subsystem for Linux)
- Linux 系统用户目录（非 root 用户）
- 权限受限的共享主机环境
