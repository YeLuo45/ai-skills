---
name: setup-nodeskclaw
description: Install and start the NoDeskClaw project locally on Windows. Covers cloning, handling Docker Hub mirror fallbacks for PostgreSQL, resolving Windows Python UTF-8 encoding issues, and rebuilding esbuild for Node.js frontend. Use when the user wants to install, run, or verify NoDeskClaw on their local machine.
---

# Setup NoDeskClaw

本技能指南指导如何在 Windows 本地环境下从零开始安装并启动验证 NoDeskClaw，尤其侧重于解决由于网络和 Windows 特定环境引起的各类坑点。

## 前置条件

1. **Python 3.12+** 以及 **uv** 包管理器
2. **Node.js 18+** 以及 npm
3. **Docker Desktop**（仅用于启动内置 PostgreSQL）
4. **Git**

## 一、克隆代码

```powershell
git clone --depth 1 https://github.com/YeLuo45/nodeskclaw.git nodeskclaw
cd nodeskclaw
```

## 二、配置环境变量

基于模板复制配置并设定强制覆盖值。

```powershell
# 1. 复制配置模板
Copy-Item -Force nodeskclaw-backend\.env.example nodeskclaw-backend\.env
Copy-Item -Force nodeskclaw-llm-proxy\.env.example nodeskclaw-llm-proxy\.env

# 2. 为 backend 设置必需的 JWT_SECRET
(Get-Content nodeskclaw-backend\.env) -replace 'JWT_SECRET=change-me-in-production','JWT_SECRET=nodeskclaw-dev-jwt-secret-min-32-chars!!' | Set-Content nodeskclaw-backend\.env -Encoding utf8

# 3. 为 llm-proxy 移除示例中的 HTTPS_PROXY 以防止代理导致报错
(Get-Content nodeskclaw-llm-proxy\.env) | Where-Object { $_ -notmatch '^HTTPS_PROXY=' } | Set-Content nodeskclaw-llm-proxy\.env.tmp -Encoding utf8
Move-Item -Force nodeskclaw-llm-proxy\.env.tmp nodeskclaw-llm-proxy\.env
Add-Content nodeskclaw-llm-proxy\.env "HTTPS_PROXY=" -Encoding utf8
```

## 三、解决数据库启动与网络源限制

由于国内访问 Docker Hub 不稳定，直接运行 `docker compose up -d` 可能会报错 `context deadline exceeded`。解决方法为使用有效镜像源手动拉取并运行。

```powershell
# 1. 使用备用镜像源拉取 PostgreSQL 镜像
docker pull docker.1panel.live/library/postgres:16-alpine
docker tag docker.1panel.live/library/postgres:16-alpine postgres:16-alpine

# 2. 启动数据库容器
docker run -d --name nodeskclaw-pg -p 5432:5432 -e POSTGRES_USER=nodeskclaw -e POSTGRES_PASSWORD=nodeskclaw -e POSTGRES_DB=nodeskclaw -v nodeskclaw_pg_dev:/var/lib/postgresql/data postgres:16-alpine

# 3. 验证本地端口是否可用
$r = Test-NetConnection -ComputerName 127.0.0.1 -Port 5432 -WarningAction SilentlyContinue; $r.TcpTestSucceeded
```

随后更新 `.env` 里的数据库连接指向本地容器。

```powershell
$envContent = Get-Content "nodeskclaw-backend\.env"
$envContent = $envContent -replace 'DATABASE_URL=.*', 'DATABASE_URL=postgresql+asyncpg://nodeskclaw:nodeskclaw@127.0.0.1:5432/nodeskclaw'
Set-Content -Path "nodeskclaw-backend\.env" -Value $envContent -Encoding utf8

$envContent2 = Get-Content "nodeskclaw-llm-proxy\.env"
$envContent2 = $envContent2 -replace 'DATABASE_URL=.*', 'DATABASE_URL=postgresql+asyncpg://nodeskclaw:nodeskclaw@127.0.0.1:5432/nodeskclaw'
Set-Content -Path "nodeskclaw-llm-proxy\.env" -Value $envContent2 -Encoding utf8
```

## 四、安装后端依赖与避坑

安装 uv 依赖：

```powershell
cd nodeskclaw-backend
uv sync

cd ../nodeskclaw-llm-proxy
uv sync
```

**⚠️ 关键注意点：Windows 下的 GBK/UTF-8 编码报错**

在 Windows 环境下运行 FastAPI 启动或进行 Alembic 迁移时，因为读取 `features.yaml` 默认使用 `GBK` 解码，可能会触发：
`UnicodeDecodeError: 'gbk' codec can't decode byte 0xad in position 64: illegal multibyte sequence`

**解决方法**：运行所有 Python / uv 相关命令前，**必须**显式指定环境变量 `$env:PYTHONUTF8='1'`。

```powershell
# 执行数据库迁移
cd nodeskclaw-backend
$env:PYTHONUTF8='1'
uv run alembic upgrade head
```

## 五、安装前端依赖与避坑

前端使用 Vite 配合 vue-tsc 和 esbuild。如果出现如下构建或安装错误：
- `Error: spawn EFTYPE` 
- `vue-tsc 无法识别为 cmdlet 或内部外部命令`

这通常是因为原生构建件 `esbuild` 损坏。

```powershell
cd nodeskclaw-portal

# 若 npm install 无法运行或产物异常，需要彻底清理
Remove-Item -Recurse -Force node_modules -ErrorAction SilentlyContinue
Remove-Item -Force package-lock.json -ErrorAction SilentlyContinue # 按需清理

# 使用干净安装
npm ci
# 或 npm install 
```

## 六、全栈启动

分别打开三个后台进程（或三个独立终端窗口）启动：

```powershell
# 1. 启动后端 (端口 8000)
cd nodeskclaw-backend
$env:PYTHONUTF8='1'
uv run uvicorn app.main:app --reload --port 8000

# 2. 启动 LLM Proxy (端口 8080)
cd nodeskclaw-llm-proxy
$env:PYTHONUTF8='1'
uv run uvicorn app.main:app --reload --port 8080

# 3. 启动前端 Portal (端口 4517)
cd nodeskclaw-portal
npm run dev
```

## 七、启动验证

完成以上步骤后，访问以下地址验证是否成功：

1. **前端界面**: [http://localhost:4517](http://localhost:4517)
2. **后端 API 文档**: [http://localhost:8000/docs](http://localhost:8000/docs)
3. **LLM Proxy 文档**: [http://localhost:8080/docs](http://localhost:8080/docs)

**验证项**：确保能够正常打开登录页面，使用初始账号 `admin`，密码 `nodeskclaw` 能够成功进入系统工作区。
