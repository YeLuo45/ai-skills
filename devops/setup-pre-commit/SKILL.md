---
name: setup-pre-commit
description: 配置 Husky 预提交钩子，包含 lint-staged、Prettier、类型检查和测试。源自 mattpocock/skills/setup-pre-commit。
category: devops
---

# Setup Pre-Commit Hooks

配置 Husky 预提交钩子，包含 lint-staged（Prettier）、类型检查和测试。

## 安装内容

- **Husky** 预提交钩子
- **lint-staged** 对所有暂存文件运行 Prettier
- **Prettier** 配置（如果缺失）
- **typecheck** 和 **test** 脚本在预提交钩子中

## 安装步骤

### 1. 检测包管理器

检查：
- `package-lock.json` → npm
- `pnpm-lock.yaml` → pnpm
- `yarn.lock` → yarn
- `bun.lockb` → bun

未明确时默认使用 npm。

### 2. 安装依赖

```bash
npm install -D husky lint-staged prettier
```

### 3. 初始化 Husky

```bash
npx husky init
```

这会创建 `.husky/` 目录并添加 `"prepare": "husky"` 到 package.json。

### 4. 创建 `.husky/pre-commit`

写入以下内容（Husky v9+ 不需要 shebang）:

```
npx lint-staged
npm run typecheck
npm run test
```

将 `npm` 替换为检测到的包管理器。如果仓库没有 `typecheck` 或 `test` 脚本，忽略这些行并告知用户。

### 5. 创建 `.lintstagedrc`

```json
{
  "*": "prettier --write"
}
```

## 触发场景
- 用户想要添加预提交钩子
- 设置 Husky
- 配置 lint-staged
- 添加提交时的格式化/类型检查/测试
