---
name: taro
description: Taro v4 微信小程序开发 — 项目创建、构建配置、已知坑点与解决方案
version: 1.0.0
triggers:
  - Taro开发
  - Taro项目创建
  - taro build
  - 微信小程序Taro
metadata:
  hermes:
    tags: [Taro, 微信小程序, React, TypeScript]
    related_skills: [app-development-guide]
---

# Taro v4 开发指南

## 环境要求

- **Node.js >= 20**（Taro v4 强制要求，Node 18 不兼容）
- **npm / yarn / pnpm**
- **微信开发者工具**（Windows/Mac 桌面应用，需单独安装）
- **@tarojs/cli >= 4.0**（推荐 4.2.0）

## Node 20 安装（WSL 环境无 root 权限时）

```bash
# 下载 Node 20 二进制包
curl -fsSL https://nodejs.org/dist/v20.18.0/node-v20.18.0-linux-x64.tar.gz | tar -xz -C /tmp

# 复制到个人目录
cp -r /tmp/node-v20.18.0-linux-x64/bin/* ~/.local/bin/
cp -r /tmp/node-v20.18.0-linux-x64/lib/* ~/.local/lib/

# 验证
node20 --version  # v20.18.0
```

## 项目创建（交互式命令被阻止时的处理）

`npx @tarojs/cli init` 是交互式的，在本环境会被阻止。需要手动搭建项目结构：

### 目录结构

```
my-app/
├── app.json              # 小程序全局配置（微信原生格式）
├── app.config.js          # Taro 入口配置（重要！见下方坑点）
├── babel.config.js
├── tsconfig.json
├── config/
│   └── index.js           # Taro 构建配置
├── src/
│   ├── app.tsx            # 根组件
│   ├── app.css
│   └── pages/
│       └── index/
│           ├── index.tsx
│           └── index.css
└── dist/                  # 构建产物，导入微信开发者工具
```

### 关键配置文件

**app.config.js（Taro v4 必需！）：**
```js
export default defineAppConfig({
  pages: ['pages/index/index'],
  window: {
    navigationBarTitleText: 'My App'
  }
})
```
注意：Taro v4 使用 `defineAppConfig()` 和 `app.config.js`，而不是旧版的 `app.json` 或 `defineApp()`。

**package.json（React + TypeScript）：**
```json
{
  "name": "my-app",
  "scripts": {
    "dev:weapp": "taro build --type weapp --watch",
    "build:weapp": "taro build --type weapp"
  },
  "dependencies": {
    "@tarojs/components": "^4.2.0",
    "@tarojs/plugin-framework-react": "^4.2.0",
    "@tarojs/plugin-platform-weapp": "^4.2.0",
    "@tarojs/react": "^4.2.0",
    "@tarojs/runtime": "^4.2.0",
    "@tarojs/taro": "^4.2.0",
    "react": "^18.2.0"
  },
  "devDependencies": {
    "@babel/preset-react": "^7.24.0",
    "@tarojs/cli": "^4.2.0",
    "@tarojs/webpack5-runner": "^4.2.0",
    "babel-preset-taro": "^4.2.0",
    "typescript": "^5.3.0",
    "webpack": "^5.90.0"
  }
}
```

**坑点：必须手动安装 `@babel/preset-react`**，Taro 的 `babel-preset-taro` 依赖它但不会自动带入。

**config/index.js（最小配置）：**
```js
const config = {
  projectName: 'my-app',
  date: new Date().toISOString().slice(0, 10),
  designWidth: 375,
  sourceRoot: 'src',
  outputRoot: 'dist',
  framework: 'react',
  compiler: 'webpack5',
  mini: {
    compile: { exclude: [] },
    webpackChain(chain) {},
    postcss: {
      cssModules: { enable: true }
    }
  }
};
module.exports = function (merge) {
  return merge({}, config);
};
```

**babel.config.js：**
```js
module.exports = {
  presets: [
    ['taro', { framework: 'react', ts: true }]
  ]
};
```

**tsconfig.json：**
```json
{
  "compilerOptions": {
    "jsx": "react-jsx",
    "module": "CommonJS",
    "strict": true
  }
}
```

## 构建命令

Taro v4 要求 Node 20，必须用 Node 20 执行：
```bash
# 直接调用（需要 Node 20）
/home/hermes/.local/bin/node20 node_modules/@tarojs/cli/bin/taro build --type weapp

# 或修复 shebang 后
./node_modules/.bin/taro build --type weapp
```

## 已知坑点

### 1. Node 18 不兼容
Taro v4 编译时报错：
```
Taro 将不再支持 Node.js 小于 20 的版本
```
解决：必须使用 Node 20。

### 2. `app.config.js` vs `app.json`
Taro v4 使用 `app.config.js`（`defineAppConfig()` 格式），旧版 `app.json` 格式不再作为入口配置。`app.json` 仍然用于微信原生配置（如 window 字段），但 Taro 读取的是 `app.config.js`。

### 3. 缺少 `@babel/preset-react`
使用 React 框架时，必须手动安装：
```bash
npm install -D @babel/preset-react
```
否则报错：`Cannot find module '@babel/preset-react'`

### 4. 交互式 init 被阻止
`npx @tarojs/cli init` 在本环境无法交互执行（command blocked），需要手动创建项目结构。按照上方"项目创建"章节的目录结构和配置文件创建即可。

### 5. `.bin/taro` shebang 问题
通过 npm 安装的 `@tarojs/cli` 的 shebang 是 `#!/usr/bin/env node`，会调用系统 Node 18。修复方法：
```bash
# 方案一：修改 shebang
sed -i '1s|.*|#!/home/hermes/.local/bin/node20|' node_modules/@tarojs/cli/bin/taro

# 方案二：在 package.json scripts 中写绝对路径
"build:weapp": "/home/hermes/.local/bin/node20 node_modules/@tarojs/cli/dist/cli.js build --type weapp"
```

### 6. `npm run build` 输出为空
如果 `npm run build` 没有任何输出且退出码为 0，说明 npm 调用的是 Node 18 而非 Node 20。npm scripts 需要使用完整绝对路径。

## 微信开发者工具导入

构建完成后，将 `dist/` 目录完整复制到 Windows 可访问路径（如 `/mnt/c/Users/.../projects/`），然后：
1. 打开微信开发者工具
2. 导入项目，选择 `dist` 目录
3. 即可在开发者工具中预览和调试

## 常用命令

| 命令 | 说明 |
|------|------|
| `taro build --type weapp` | 构建微信小程序 |
| `taro build --type h5` | 构建 H5 |
| `taro build --type weapp --watch` | 监听模式 |
