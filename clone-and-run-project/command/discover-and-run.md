# 命令：检索 → Fork → Clone → Run → Check → CreateBranch

根据用户提供的关键词或仓库地址，执行完整的项目获取与启动流程。

## 触发条件

用户提供以下任一输入：
- GitHub 仓库 URL（如 `https://github.com/org/repo`）
- `owner/repo` 短格式（如 `langchain-ai/langchain`）
- 搜索关键词（如 "ai agent framework python"）

## 执行流程

```
用户输入
  │
  ├─ 是仓库 URL 或 owner/repo？──→ 跳到步骤 2
  │
  └─ 是搜索关键词？──→ 步骤 1：搜索
```

### 步骤 1：搜索（阶段一）

仅在用户提供的是搜索关键词（非具体仓库地址）时执行。

```powershell
gh search repos "<keywords>" --sort stars --limit 10 --json fullName,description,stargazersCount,language,url
```

- 将搜索结果展示给用户，等待用户选择目标仓库。
- 用户选定后，提取 `owner/repo`，进入步骤 2。

### 步骤 2：Fork（阶段二）

询问用户是否需要 Fork（若用户只是想运行体验，可跳过 Fork 直接 Clone）。

**需要 Fork**（准备贡献代码）：
```powershell
gh repo fork <owner>/<repo> --clone
Set-Location <repo-name>
```

**不需要 Fork**（仅体验/学习）：
```powershell
# 跳过 Fork，直接进入步骤 3 Clone
```

### 步骤 3：Clone（阶段三）

若步骤 2 已通过 `--clone` 完成 Clone，跳过此步骤。

```powershell
$repoUrl = "https://github.com/<owner>/<repo>.git"
$repoName = ($repoUrl -split '/')[-1] -replace '\.git$', ''
$targetDir = $repoName
if (Test-Path $targetDir) {
    $targetDir = "$repoName-$(Get-Date -Format 'yyyyMMdd')"
}
git clone $repoUrl $targetDir
Set-Location $targetDir
```

大仓库可用浅克隆加速：
```powershell
git clone --depth 1 $repoUrl $targetDir
```

### 步骤 4：Run（阶段四 + 五 + 六）

按 SKILL.md 阶段四~六顺序执行：

1. **检测项目类型并安装依赖**（阶段四）
   - 扫描 `pyproject.toml`、`package.json`、`Cargo.toml`、`go.mod` 等
   - 执行对应安装命令（`uv sync`、`pnpm install`、`cargo build` 等）

2. **处理外部依赖与配置**（阶段五）
   - 扫描并复制 `*.example*` 配置模板
   - 检测 Docker 依赖，按需启动

3. **启动项目**（阶段六）
   - 根据项目类型执行启动命令
   - 多服务项目按依赖顺序逐个后台启动

### 步骤 5：Check（阶段六 - 验证运行）

验证项目是否成功运行：

```powershell
# 后端健康检查
Invoke-RestMethod -Uri "http://localhost:<port>/api/health" -Method Get

# 前端检查：确认终端日志出现 "Local: http://localhost:<port>"

# Rust 项目
cargo run -- --help
cargo run -- --version
```

- 验证通过 → 输出确认信息，进入步骤 6
- 验证失败 → 分析错误，尝试修复，无法修复的记入 `user-todolist.md`

### 步骤 6：CreateBranch（阶段七）

项目运行验证通过后，创建开发分支：

```powershell
# 询问用户分支用途，推荐命名格式
git checkout -b feature/<branch-name>
```

分支命名建议：
- `feature/xxx` — 新功能
- `fix/xxx` — 修复 bug
- `docs/xxx` — 文档更新
- `refactor/xxx` — 重构

创建完成后提示用户：
- 当前所在分支
- 可以开始修改代码
- 修改完成后使用 `git add -A; git commit -m "message"; git push -u origin <branch>` 提交推送

## 输出

执行完毕后生成：
1. **运行说明文档**（`Run-README.md`）— 按阶段十的模板生成
2. **user-todolist.md**（按需）— 列出需要用户手动完成的事项
3. **终端输出**：当前状态汇总（项目类型、运行端口、当前分支、下一步建议）
