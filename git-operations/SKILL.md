---
name: git-operations
description: Search GitHub repositories (global or user-owned), fork repos, clone and run projects, push, pull, and manage remotes via gh CLI and git. Use when the user asks to search repos, fork a project, clone, push, pull, sync with remote, or perform any git/GitHub workflow.
---

# Git Operations

通过 `gh` CLI 和 `git` 在 Windows PowerShell 下执行 GitHub 仓库检索、Fork、Clone 并运行、推送、拉取等操作。

## 前置条件

### gh CLI

本技能的 GitHub 操作（搜索、Fork、创建 PR 等）依赖 [GitHub CLI (`gh`)](https://cli.github.com/)。

**检测**：
```powershell
gh --version
```

**安装**：
```powershell
winget install GitHub.cli
```
安装后刷新 PATH：
```powershell
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
```

**登录认证**：
```powershell
gh auth status
```
若未登录，引导用户执行：
```powershell
gh auth login
```
选择 `GitHub.com` → `HTTPS` → 浏览器登录。将此步骤记入 `user-todolist.md`（需要用户手动完成浏览器授权）。

### git

**检测**：`git --version`。未安装则：`winget install Git.Git`

---

## 功能一：搜索仓库

### 全网搜索

根据用户提供的关键词搜索 GitHub 公开仓库：

```powershell
gh search repos "<keywords>" --limit 10
```

**常用过滤参数**：

| 参数 | 说明 | 示例 |
|------|------|------|
| `--language` | 按语言过滤 | `--language python` |
| `--sort` | 排序方式：stars, forks, updated | `--sort stars` |
| `--order` | 排序方向 | `--order desc` |
| `--match` | 匹配范围：name, description, readme | `--match name` |
| `--limit` | 结果数量（默认 30） | `--limit 20` |
| `--topic` | 按 topic 过滤 | `--topic machine-learning` |
| `--stars` | 按 star 数过滤 | `--stars ">=1000"` |

**组合示例**：
```powershell
# 搜索 Python 领域 star 超过 1000 的 AI 项目
gh search repos "ai agent" --language python --sort stars --stars ">=1000" --limit 10

# 按名称精确匹配
gh search repos "langchain" --match name --sort stars --limit 5
```

**输出详细信息**：
```powershell
# JSON 格式输出更多字段
gh search repos "<keywords>" --limit 10 --json fullName,description,stargazersCount,language,url
```

### 搜索我的仓库

列出当前登录用户的仓库：

```powershell
# 列出自己所有仓库
gh repo list --limit 50

# 按关键词过滤自己的仓库
gh repo list --limit 50 | Select-String "<keyword>"

# JSON 格式，获取更多信息
gh repo list --json name,description,url,isPrivate,primaryLanguage --limit 50
```

**搜索指定用户/组织的仓库**：
```powershell
gh repo list <owner> --limit 30
```

### 查看仓库详情

```powershell
gh repo view <owner>/<repo>
```

---

## 功能二：Fork 仓库

将目标仓库 Fork 到当前用户的 GitHub 账号下：

```powershell
gh repo fork <owner>/<repo>
```

**常用参数**：

| 参数 | 说明 |
|------|------|
| `--clone` | Fork 后自动 clone 到本地 |
| `--remote` | 自动添加 upstream 远程（默认 true） |
| `--fork-name` | 指定 Fork 后的仓库名 |

**推荐用法**（Fork + Clone 一步完成）：
```powershell
gh repo fork <owner>/<repo> --clone
```

此命令会：
1. 在 GitHub 上 Fork 仓库到当前用户账号
2. Clone Fork 后的仓库到本地（目录名为仓库名）
3. 自动配置 `origin`（你的 Fork）和 `upstream`（原始仓库）两个远程

**仅 Fork 不 Clone**：
```powershell
gh repo fork <owner>/<repo> --clone=false
```

**从 URL Fork**：
```powershell
gh repo fork https://github.com/some-org/some-project --clone
```

---

## 功能三：Clone 并运行

### 基本 Clone

```powershell
git clone <repo-url> [target-dir]
```

**通过 gh clone**（自动处理 GitHub 短格式）：
```powershell
gh repo clone <owner>/<repo> [target-dir]
```

**Clone 指定分支**：
```powershell
git clone -b <branch> <repo-url>
```

**浅克隆（加速大仓库）**：
```powershell
git clone --depth 1 <repo-url>
```

### Clone 后运行项目

Clone 完成后，调用 `clone-and-run-project` 技能完成项目检测、依赖安装和运行。参考该技能的 Phase 3–9 流程。

简要流程：
1. 检测项目类型（`package.json`、`pyproject.toml`、`Cargo.toml`、`go.mod` 等）
2. 安装依赖（`pnpm install`、`uv sync`、`cargo build` 等）
3. 准备配置文件（复制 `.env.example` → `.env` 等）
4. 启动项目并验证

---

## 功能四：推送（Push）

### 推送到已有远程

```powershell
git add -A
git commit -m "commit message"
git push
```

### 首次推送（设置上游跟踪）

```powershell
git push -u origin <branch>
```

### 推送到新建远程仓库

若本地项目尚未关联远程仓库：

**方式一：通过 gh 创建远程仓库并推送**：
```powershell
# 在 GitHub 上创建仓库（公开）
gh repo create <repo-name> --public --source=. --push

# 或私有仓库
gh repo create <repo-name> --private --source=. --push
```
`--source=.` 指定当前目录为源，`--push` 自动推送。

**方式二：手动添加远程**：
```powershell
git init
git add -A
git commit -m "Initial commit"
git remote add origin https://github.com/<user>/<repo>.git
git push -u origin master
```

### 推送标签

```powershell
git tag v1.0.0
git push origin v1.0.0

# 推送所有标签
git push origin --tags
```

### 强制推送（慎用）

```powershell
# 仅在用户明确要求时使用，警告覆盖风险
git push --force-with-lease
```

---

## 功能五：拉取（Pull）

### 基本拉取

```powershell
git pull
```

### 拉取并变基

```powershell
git pull --rebase
```

### 从上游同步（Fork 场景）

Fork 的仓库需要定期从上游同步更新：

**方式一：通过 gh 同步 Fork（推荐）**：
```powershell
gh repo sync --source <upstream-owner>/<repo>
```
或在 Fork 的仓库目录中直接执行：
```powershell
gh repo sync
```

**方式二：手动同步**：
```powershell
# 确认 upstream 已配置
git remote -v

# 若未配置 upstream
git remote add upstream https://github.com/<original-owner>/<repo>.git

# 拉取上游更新
git fetch upstream

# 合并到当前分支
git merge upstream/main

# 推送到自己的 Fork
git push origin main
```

### 拉取指定分支

```powershell
git fetch origin <branch>
git checkout <branch>
```

---

## 功能六：分支与远程管理

### 分支操作

```powershell
# 查看所有分支
git branch -a

# 创建并切换
git checkout -b <new-branch>

# 删除本地分支
git branch -d <branch>

# 删除远程分支
git push origin --delete <branch>
```

### 远程管理

```powershell
# 查看远程列表
git remote -v

# 添加远程
git remote add <name> <url>

# 修改远程 URL
git remote set-url <name> <new-url>

# 删除远程
git remote remove <name>
```

---

## 功能七：Pull Request

### 创建 PR

```powershell
# 推送当前分支
git push -u origin HEAD

# 创建 PR（交互式）
gh pr create --title "PR title" --body "PR description"

# 指定目标分支
gh pr create --base main --title "PR title" --body "description"
```

### 查看与管理 PR

```powershell
# 列出 PR
gh pr list

# 查看 PR 详情
gh pr view <number>

# 合并 PR
gh pr merge <number> --merge

# Review PR
gh pr review <number> --approve
```

---

## 完整工作流示例

### 示例一：搜索 → Fork → Clone → 修改 → 推送 → PR

```powershell
# 1. 搜索项目
gh search repos "awesome-tool" --sort stars --limit 5

# 2. Fork 并 Clone
gh repo fork owner/awesome-tool --clone
Set-Location awesome-tool

# 3. 创建功能分支
git checkout -b feature/my-change

# 4. ... 修改代码 ...

# 5. 提交并推送
git add -A
git commit -m "feat: add my feature"
git push -u origin feature/my-change

# 6. 创建 PR 到上游
gh pr create --title "feat: add my feature" --body "description of changes"
```

### 示例二：本地项目 → 创建远程 → 推送

```powershell
# 在项目目录中
git init
git add -A
git commit -m "Initial commit"

# 创建远程仓库并推送
gh repo create my-project --public --source=. --push
```

### 示例三：同步上游更新到 Fork

```powershell
# 在 Fork 的本地仓库中
gh repo sync
git pull
```

---

## 注意事项

- **PowerShell 语法**：多命令用分号 `;` 连接，**不使用 `&&`**（PowerShell 5.x 不支持）。
- **认证问题**：`gh` 的 HTTPS 操作需要先 `gh auth login`。`git push` 若提示认证失败，用 `gh auth setup-git` 配置 git 使用 gh 的凭据。
- **大仓库 Clone 慢**：使用 `--depth 1` 浅克隆，之后按需 `git fetch --unshallow`。
- **网络问题**：出现 `fatal: unable to access` 或 `Could not resolve host` 时，检查网络/代理设置。可设置代理：
  ```powershell
  git config --global http.proxy http://proxy:port
  git config --global https.proxy http://proxy:port
  ```
- **Fork 已存在**：若 Fork 目标仓库已经 Fork 过，`gh repo fork` 会提示已存在并直接使用已有 Fork。
- **Clone 后运行项目**：需结合 `clone-and-run-project` 技能进行项目检测和启动，参考该技能的完整流程。
