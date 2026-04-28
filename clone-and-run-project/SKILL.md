---
name: project-lifecycle
description: Full-lifecycle project skill covering search, fork, clone, run, verify, branch, push, pull, PR, and upstream sync via gh CLI and git on Windows PowerShell. Also generates Run-README.md and user-todolist.md. Use when the user asks to search repos, fork, clone, run, set up, push, pull, create branches, sync with remote, create PRs, or perform any git/GitHub workflow.
---

# Project Lifecycle

在 Windows PowerShell 下通过 `gh` CLI 和 `git` 完成项目全生命周期管理：搜索 → Fork → Clone → 安装运行 → 验证 → 分支管理 → Push/Pull → PR。

## 快捷命令

本技能提供两个预定义命令流程，位于 `command/` 目录：

| 命令文件 | 说明 | 典型触发 |
|----------|------|----------|
| `command/discover-and-run.md` | 检索 → Fork → Clone → Run → Check → CreateBranch | 用户提供仓库 URL、owner/repo 或搜索关键词 |
| `command/evolve-and-push.md` | 分析经验 → CreateBranch → 进化技能 → Push | 用户要求总结经验、更新技能文件 |

使用时先读取对应命令文件，按其中的步骤执行。

---

## 前置条件

### gh CLI

GitHub 操作（搜索、Fork、创建 PR 等）依赖 [GitHub CLI (`gh`)](https://cli.github.com/)。

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

### gh 未安装时的降级策略

若 `gh` 安装失败或用户不愿安装，仍可完成大部分流程：

| 功能 | gh 可用 | gh 不可用（降级方案） |
|------|---------|----------------------|
| 搜索仓库 | `gh search repos` | 用 WebSearch 搜索 `github <keywords> repository`，从结果中提取 `owner/repo` |
| Fork | `gh repo fork` | 引导用户在浏览器打开仓库页面点击 Fork，记入 `user-todolist.md` |
| Clone | `gh repo clone` | `git clone https://github.com/<owner>/<repo>.git` |
| 创建 PR | `gh pr create` | 引导用户在浏览器创建 PR，记入 `user-todolist.md` |

**关键原则**：`gh` 不可用不应阻断 Clone → Run 流程；搜索和 Fork 可降级，Clone 和 Run 完全不依赖 `gh`。

### git

**检测**：`git --version`。未安装则：`winget install Git.Git`

---

## 阶段一：搜索与发现

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

## 阶段二：Fork 仓库

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

## 阶段三：Clone 项目

### 准备工作目录

1. 用户提供 git 仓库链接（如 `https://github.com/org/repo.git`），或指向已有本地目录。
2. 从链接提取仓库名称作为目标文件夹名。
3. 若目标文件夹已存在，在名称后追加日期后缀（格式 `repo-YYYYMMDD`），仍冲突则加 `-N`。
4. 在**当前工作区父目录**或用户指定位置创建文件夹。

```powershell
$repoUrl = "https://github.com/org/my-project.git"
$repoName = ($repoUrl -split '/')[-1] -replace '\.git$', ''
$targetDir = $repoName
if (Test-Path $targetDir) {
    $targetDir = "$repoName-$(Get-Date -Format 'yyyyMMdd')"
}
```

### 克隆仓库

```powershell
git clone $repoUrl $targetDir; Set-Location $targetDir
```

- 若用户指定了分支：`git clone -b <branch> $repoUrl $targetDir`
- 克隆失败时报告错误，不继续后续步骤。

**通过 gh clone**（自动处理 GitHub 短格式）：
```powershell
gh repo clone <owner>/<repo> [target-dir]
```

**浅克隆（加速大仓库）**：
```powershell
git clone --depth 1 <repo-url>
```

### Clone 失败处理

1. **SSL 错误**（`OpenSSL SSL_connect: SSL_ERROR_SYSCALL`）：常见于网络不稳定或代理配置问题。处理策略：
   - 直接重试一次（偶发性网络波动）
   - 检查并清除残留的 git 代理配置（见注意事项 - 网络问题）
   - 若从搜索结果中选择了仓库，**尝试克隆备选仓库**而非反复重试同一个

2. **多仓库备选策略**：当搜索结果有多个候选仓库时，按 star 数从高到低依次尝试 Clone。第一个失败后立即尝试第二个，避免在网络问题上浪费时间。

---

## 阶段四：安装依赖

按优先级检测项目类型，匹配到即执行对应安装命令：

| 检测文件 | 项目类型 | 安装命令 |
|----------|----------|----------|
| `pyproject.toml` + `uv.lock` | Python (uv) | `uv sync`（见下方 uv 注意事项） |
| `pyproject.toml` + `requirements.txt` | Python (pip) | `python -m pip install -e .` |
| `pyproject.toml`（无 uv.lock） | Python (modern) | 检查是否有 `[tool.uv]` 段或项目 README 提及 uv；若有则 `uv sync`，否则 `python -m pip install -e .` |
| `requirements.txt` | Python | `python -m pip install -r requirements.txt` |
| `package.json` | Node.js | 根据锁文件和 `packageManager` 字段选择（见下方） |
| `Cargo.toml` | Rust | `cargo build`（见下方 Rust 注意事项） |
| `go.mod` | Go | `go mod download` |
| `pom.xml` | Java (Maven) | `mvn install -DskipTests` |
| `build.gradle` / `build.gradle.kts` | Java/Kotlin (Gradle) | `gradle build -x test` |
| `docker-compose.yml` + `Dockerfile` | Docker | `docker-compose build` |
| `justfile` | just 任务运行器 | 先阅读 justfile 内容，优先查找 Windows 专用目标（见下方） |
| `Makefile` | Make | 先阅读 Makefile 内容理解可用目标，再决定执行 |

对于**混合项目**（同时有后端 + 前端子目录如 `console/`、`frontend/`、`web/`、`website/`、`ui/`），分别检测并安装。

### justfile 项目关键注意事项

1. **检测 `justfile`**：项目根目录存在 `justfile`（大小写不敏感）表示项目使用 [just](https://github.com/casey/just) 任务运行器。`just` 类似 `make`，但语法更简单且**原生支持 Windows**。

2. **检测 Windows 专用目标**：许多跨平台项目在 justfile 中定义了 `win-` 前缀的 Windows 专用构建目标。阅读 justfile 内容，查找：
   - `win-total-dbg` / `win-total-rls`：Windows 下构建并运行（debug/release）
   - `win-bld-dbg` / `win-bld-rls`：仅构建
   - `win-run-dbg` / `win-run-rls`：仅运行（需先构建）
   - `run-ui` / `run-ui-windows`：启动 UI
   - `set windows-shell`：justfile 中若有此行，说明项目已适配 Windows
   ```powershell
   just --list   # 列出所有可用目标
   ```

3. **`just` 未安装时**：先安装 just（参考 setup-dev-environment 技能），再执行 justfile 中的目标。

4. **justfile 中的依赖链**：just 目标之间有依赖关系（如 `win-total-dbg` 依赖 `win-bld-dbg`），阅读整个 justfile 理解依赖链后再决定执行哪个目标。

5. **just 目标的路径分隔符**：justfile 中可能用变量处理跨平台路径：
   ```
   s := if os() == "windows" { "\\" } else { "/" }
   ```
   这意味着项目已考虑了 Windows 兼容性。

### uv 项目关键注意事项

1. **识别 uv 项目**：存在 `uv.lock` 文件，或 `pyproject.toml` 中有 `[tool.uv]` 段，或 README/Makefile 中使用 `uv run` / `uv sync` 命令。

2. **`uv sync` 会自动创建 venv**：无需手动 `python -m venv .venv`，`uv sync` 会在项目目录下自动创建 `.venv`。

3. **Python 版本要求**：`uv sync` 会检查 `pyproject.toml` 中 `requires-python` 字段。若系统 Python 不满足要求，uv 会**自动下载**对应版本的 Python（如 `cpython-3.12.9`），这在首次运行时可能耗费数分钟。
   - 若要使用系统已安装的 Python：`uv sync --python python`
   - 若要指定 Python 版本：`uv sync --python 3.12`

4. **`uv sync` 首次安装可能极慢**：需要下载大量依赖包（如 100+ 个包），特别是含大型 wheel 文件的项目（如 `onnxruntime`、`pandas`、`numpy` 等）。必须设置 `block_until_ms: 0` 后台执行，然后轮询终端文件：
   - 出现 `Installed N packages` → 安装成功
   - 出现 `error:` / `Failed to download` → 安装失败，可能是网络问题
   - 轮询间隔建议 30s → 60s → 120s 指数退避

5. **网络/DNS 失败**：uv 下载包时可能报 `Could not connect, are you offline?` 或 `dns error: 不知道这样的主机`。这是网络问题，等网络恢复后重试 `uv sync` 通常可解决。记入 `user-todolist.md`。

6. **`uv run` 执行命令**：uv 项目中不需要手动激活 venv，直接用 `uv run <command>` 即可：
   ```powershell
   uv run uvicorn app:app --port 8000
   uv run python -m pytest
   uv run langgraph dev
   ```

### Python (pip) 项目关键注意事项

1. **始终使用 `python -m pip`** 而非直接调用 `pip`，避免 PATH 不一致问题。

2. **`requirements.txt` 文件编码异常**：部分项目的 `requirements.txt` 使用 UTF-16 LE 编码（文件开头出现 `ÿþ` BOM 标记，内容中每个字符间有空格）。pip 无法直接解析此类文件。**处理方法**：
   - 读取文件后检查是否出现 `ÿþ` 前缀或字符间异常空格
   - 若确认编码异常，手动提取包名，重写为 UTF-8 编码的 `requirements.txt`
   - 或直接用 `python -m pip install <package>` 逐个安装核心依赖

3. **`requirements.txt` 含不兼容的依赖**：旧项目的 `requirements.txt` 中可能包含与当前 Python 版本不兼容的包（如 `py2exe` 仅支持 Python 3.6–3.9、`pyinstaller` 旧版等打包工具）。**处理策略**：
   - 当 `pip install -r requirements.txt` 整体失败时，**分析哪些是运行时核心依赖、哪些是打包/开发工具**
   - 打包工具（`py2exe`、`cx_Freeze`、`pyinstaller` 等）和开发工具（`pytest`、`flake8`、`black` 等）通常不影响项目运行，可跳过
   - **阅读主入口文件**（如 `main.py`）的 `import` 语句，确定实际运行所需的核心依赖
   - 仅安装核心依赖即可运行项目，例如 Pygame 游戏只需 `python -m pip install pygame`
   - 在 `Run-README.md` 中说明跳过了哪些不兼容的依赖及原因

4. **检查 `pyproject.toml` 中的 CLI 入口**：
   ```toml
   [project.scripts]
   copaw = "copaw.cli.main:cli"
   ```
   若存在 `[project.scripts]`，记录命令名称（如 `copaw`），安装后需验证该命令是否可用。

5. **`pip install -e .` 耗时极长**：依赖多的项目安装可能需 **5–15 分钟**。必须设置 `block_until_ms: 0` 立即后台执行，然后轮询终端文件检查进度：
   - 检查是否出现 `Successfully installed ...` 行（安装成功）
   - 检查是否出现 `ERROR:` 行（安装失败）
   - 轮询间隔建议 30s → 60s → 120s 指数退避

6. **用户目录安装**：若出现 `Defaulting to user installation because normal site-packages is not writeable`，说明包安装到了 `%APPDATA%\Python\PythonXXX\`，此时 `[project.scripts]` 定义的 CLI 命令可能不在 PATH 中。**解决方案**：使用 `python -m <module>` 替代 CLI 命令。

7. **C 扩展构建失败**：某些依赖需要编译 C 扩展。若构建失败，确认已安装 Visual C++ Build Tools。

8. **网络不稳定**：`pip install` 可能因 DNS 失败中断，应记入 `user-todolist.md`。

### Node.js 项目注意事项

1. **选择包管理器**（按优先级）：
   - 检查 `package.json` 中的 `packageManager` 字段（如 `"packageManager": "pnpm@10.26.2"`），优先使用指定的包管理器和版本。
   - 否则按锁文件判断：`pnpm-lock.yaml` → pnpm，`yarn.lock` → yarn，`package-lock.json` → npm。
   - 若指定了 pnpm 但系统未安装：`npm install -g pnpm`（或 `corepack enable`）。

2. **Node.js 版本要求**：部分现代项目要求 Node.js 22+（如使用 Next.js 16+），检查 README 或 `package.json` 的 `engines` 字段。

3. 前端子目录（`console/`、`frontend/`）通常需要单独安装和构建。

### Hermit 依赖管理器注意事项

部分项目使用 [Hermit](https://cashapp.github.io/hermit/) 管理开发依赖（Rust、Node、just 等）。检测：项目中存在 `bin/hermit` 或 `bin/activate-hermit`。

1. **Hermit 仅支持 Linux/macOS**：Hermit 是 bash 脚本 + 平台特定二进制，**不支持 Windows 原生 PowerShell**。不要尝试在 PowerShell 中执行 `source bin/activate-hermit`。
2. **WSL 中也可能不可用**：若项目从 Windows 克隆（Git 默认使用 CRLF），shell 脚本会有 `\r\n` 换行符，在 WSL/bash 中报 `$'\r': command not found`。此外 `bin/hermit` 是 Windows 二进制（PE 格式），在 WSL 的 Linux 环境中无法执行。
3. **Windows 下的替代方案**：忽略 Hermit，直接使用系统安装的工具（Rust、Node、just 等）。阅读 `bin/hermit.hcl` 或 Hermit 配置确认项目需要哪些工具及版本，然后手动安装对应版本。
4. **检查 justfile 中的 Windows 目标**：使用 Hermit 的项目通常也提供了 justfile，其中的 `win-*` 目标不依赖 Hermit，可直接在 Windows 上使用。

### Rust 项目关键注意事项

1. **Cargo 可能不在 PATH 中**：即使已安装 Rust，当前 shell 会话的 PATH 可能未包含 Cargo。先检测，若不在 PATH 则手动加入：
   ```powershell
   if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
       if (Test-Path "$env:USERPROFILE\.cargo\bin\cargo.exe") {
           $env:Path = "$env:USERPROFILE\.cargo\bin;" + $env:Path
       } else {
           # Cargo 未安装，需先安装 Rust（参考 setup-dev-environment 技能）
       }
   }
   ```

2. **未安装 Rust 时的静默安装**：无需用户手动操作，可直接下载并静默安装：
   ```powershell
   $rustupUrl = "https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe"
   $dest = "$env:TEMP\rustup-init.exe"
   Invoke-WebRequest -Uri $rustupUrl -OutFile $dest -UseBasicParsing
   Start-Process -FilePath $dest -ArgumentList "-y" -Wait -NoNewWindow
   $env:Path = "$env:USERPROFILE\.cargo\bin;" + $env:Path
   ```
   **前置条件**：需要 Visual C++ Build Tools，否则编译含 C/C++ 依赖的 crate 会失败。

3. **Rustup 工具链同步失败**：首次安装或 `cargo` 首次执行时，rustup 会自动同步/下载工具链。可能出现：
   - `could not rename downloaded file` / `could not rename component file`：文件被其他进程（杀毒软件、OneDrive、另一个终端）锁定。**解决方法**：关闭其他终端和可能锁文件的程序，重新执行。
   - `detected conflict: 'bin\rust-gdb'`：工具链文件冲突。**解决方法**：
     ```powershell
     rustup toolchain uninstall stable
     rustup default stable
     ```
   - 若反复失败，尝试清空缓存后重装：
     ```powershell
     Remove-Item -Recurse -Force "$env:USERPROFILE\.rustup\downloads" -ErrorAction SilentlyContinue
     Remove-Item -Recurse -Force "$env:USERPROFILE\.rustup\tmp" -ErrorAction SilentlyContinue
     rustup default stable
     ```

4. **Windows 符号链接权限问题（error 1314）**：某些 crate（如 `v8-goose`、`rusty_v8`、`deno_core`）在构建时需要创建符号链接（symlink），Windows 默认不允许普通用户创建符号链接，报错：
   ```
   symlink_dir failed: Os { code: 1314, kind: Uncategorized, message: "客户端没有所需的特权。" }
   thread 'main' panicked at ... Failed to create symlink
   ```
   **解决方法（按优先级）**：
   1. **开启 Windows 开发者模式**（推荐，一劳永逸）：
      ```powershell
      # 检查是否已开启
      $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
      (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
      # 若返回 1 则已开启；否则需手动开启：
      # 设置 → 隐私和安全 → 针对开发人员 → 开发人员模式 → 开启
      ```
      开启后需**重新打开终端**再构建。
   2. **以管理员身份运行终端**：右键 PowerShell → 以管理员身份运行，然后执行构建命令。
   - 将此要求记入 `user-todolist.md` 和运行说明文档。

5. **编译耗时极长**：Rust 项目首次编译需下载并编译所有 crate，依赖多的项目（如 100+ crate）可能耗时 **5–30 分钟**。必须设置 `block_until_ms: 0` 后台执行（或设置足够大的 timeout，如 `block_until_ms: 600000`），然后轮询终端文件：
   - 出现 `Finished` → 编译成功
   - 出现 `error[E` / `error: ` / `error: failed to run custom build command` → 编译失败
   - 出现 `warning:` 但最终有 `Finished` → 编译成功（warning 不影响）
   - 出现 `warning: spurious network error` → 网络不稳定但 cargo 会自动重试，通常不影响最终结果
   - 轮询间隔建议 30s → 60s → 120s 指数退避

6. **Feature flags 与条件编译**：Rust 项目的 `Cargo.toml` 可能定义了多个 features，默认 features 中的某些依赖可能在 Windows 上编译失败（如需要 CMake、C 编译器、系统库等）。处理策略：
   - **先尝试默认编译**：`cargo build`
   - **若失败**，检查错误信息中涉及的 crate（如 `libsql-ffi`、`openssl-sys`）。阅读 `Cargo.toml` 的 `[features]` 段，找出该 crate 属于哪个 feature
   - **禁用问题 feature 重试**：`cargo build --no-default-features --features feat1,feat2,...` 指定不含问题 crate 的 feature 组合
   - 典型案例：`libsql-ffi` 需要 CMake 和 C 编译器来编译嵌入式 SQLite；若项目同时支持 PostgreSQL，可用 `--no-default-features --features postgres` 绕过
   - 将 feature 选择记录到生成的运行说明文档中

7. **Rust + Electron/Node 混合项目**：部分项目（如 goose）是 Rust 后端 + Electron 前端的混合架构。构建流程通常为：
   1. 先构建 Rust 二进制（`cargo build` 或 `cargo run -p <server> --bin <binary>`）
   2. 复制二进制到 `ui/desktop/src/bin/` 等前端资源目录
   3. 安装前端依赖（`npm install`）
   4. 启动 Electron（`npm run start-gui`）
   - justfile 中的 `win-total-dbg` / `win-total-rls` 通常封装了这整个流程。
   - 若 justfile 有 Windows 目标，优先使用它；否则手动按上述步骤执行。

8. **`cargo run` 的参数传递**：Rust 项目的 CLI 参数需要在 `--` 之后传递：
   ```powershell
   cargo run -- --help          # 查看项目自身的帮助
   cargo run -- status          # 执行项目的 status 子命令
   cargo run -- onboard         # 执行 onboard 子命令
   ```
   若使用了非默认 features，每次 `cargo run` 都需带上：
   ```powershell
   cargo run --no-default-features --features postgres,html-to-markdown -- --help
   ```

9. **交互式 setup/onboard 向导**：许多 Rust 项目在首次运行时需要执行配置向导（如 `goose configure`），这通常需要用户手动输入。检测方法：
   - 阅读 `main.rs` 查找 `onboard`、`setup`、`init`、`configure`、`wizard` 等关键字
   - 阅读 README / CONTRIBUTING.md 中的 Configuration / Setup 章节
   - 检查是否有 `--no-onboard`、`--skip-setup` 等跳过标志
   - 若需要交互式配置，记入 `user-todolist.md`，不要尝试自动化

10. **数据库依赖**：Rust 项目常依赖 PostgreSQL、SQLite 等。若项目代码中有 `--no-db` 标志，可先用该标志验证基本启动：
    ```powershell
    cargo run -- --no-db --no-onboard --help    # 仅验证二进制可执行
    cargo run -- status                          # 查看系统状态
    ```

11. **验证方式**：Rust 项目的验证优先级：
    1. `cargo run -- --help`：验证二进制能正常启动并输出帮助信息
    2. `cargo run -- --version`：验证版本信息
    3. `cargo run -- status` / `cargo run -- doctor`：若有诊断子命令
    4. 完整启动并检查日志输出

---

## 阶段五：外部依赖与配置

### 检测并启动外部依赖

1. 检查项目是否依赖 MongoDB、Redis、PostgreSQL、MySQL 等。
   - 扫描 `.env.example`、`docker-compose.yml`、`config.yaml`、`config.example.yaml` 等配置文件。
2. 若有 `docker-compose.yml` 且包含数据库服务，尝试：
   ```powershell
   docker compose up -d <db-services>
   ```
3. **Docker 不可用的情况**：Windows 上 Docker Desktop 可能未启动或未安装（报 `open //./pipe/dockerDesktopLinuxEngine: The system cannot find the file specified`）。此时：
   - 提示用户启动 Docker Desktop
   - 若项目支持非 Docker 方式运行（如 Local Sandbox），改用本地方式
   - 记入 `user-todolist.md`

### 准备配置文件

1. **扫描所有配置模板文件**：不仅限于 `.env.example`，还应检测：
   - `config.example.yaml` → `config.yaml`
   - `config.example.json` → `config.json`
   - `settings.example.toml` → `settings.toml`
   - 任何 `*.example.*` 模式的文件
   - 子目录中的配置模板（如 `frontend/.env.example` → `frontend/.env`）

   ```powershell
   # 扫描所有 .example 模板文件并复制
   Get-ChildItem -Recurse -Filter "*.example*" -File | ForEach-Object {
       $target = $_.FullName -replace '\.example', ''
       if (-not (Test-Path $target)) {
           Copy-Item $_.FullName $target
           Write-Host "Created: $target"
       }
   }
   ```

2. **也可参考 Makefile**：许多项目在 Makefile 中有 `config` 或 `init` 目标，能看出需要复制哪些配置文件。阅读 Makefile 内容提取 `cp` / `copy` 命令。

3. **前端直连配置**：若项目有反向代理（如 nginx），但本地无法运行 nginx，需在前端 `.env` 中配置直接连接后端：
   ```
   NEXT_PUBLIC_BACKEND_BASE_URL=http://localhost:8001
   NEXT_PUBLIC_LANGGRAPH_BASE_URL=http://localhost:2024
   ```
   检测方法：在前端源码中搜索 `NEXT_PUBLIC_` 或 `VITE_` 开头的环境变量，在 `.env.example` 中找到对应注释掉的行并取消注释。

4. 提示用户检查 `.env` 和 `config.yaml` 中的 API Key、密码等敏感配置。

---

## 阶段六：启动与验证

### 单服务项目

根据项目类型启动：

| 项目类型 | 启动命令 |
|----------|----------|
| Python (uv + FastAPI/uvicorn) | `uv run uvicorn app:app --host 0.0.0.0 --port 8000` |
| Python (uv + 自定义命令) | `uv run <command>` |
| Python (pip + CLI 入口) | 先尝试 CLI 命令，不可用则用 `python -m <module>` |
| Python FastAPI | `python -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000` |
| Python Flask | `python app.py` |
| Python Django | `python manage.py runserver` |
| Python Pygame/GUI 桌面游戏 | `python main.py`（弹出本地窗口，非 Web 服务） |
| Node.js | `pnpm run dev` / `npm run dev` / `npm start` |
| Rust | `cargo run`（若用了非默认 features：`cargo run --no-default-features --features X,Y`） |
| Rust + UI (justfile) | `just win-total-dbg`（Windows）或 `just run-ui`（通用） |
| Go | `go run .` |
| Java Maven | `mvn spring-boot:run` |
| Docker | `docker compose up -d` |

### 多服务项目（重点）

许多现代项目需要同时运行**多个后端进程** + 前端，例如：

| 服务 | 示例 | 典型端口 |
|------|------|----------|
| 主后端（如 LangGraph） | `uv run langgraph dev --no-browser --port 2024` | 2024 |
| API 网关（如 FastAPI Gateway） | `uv run uvicorn src.gateway.app:app --port 8001` | 8001 |
| 前端（如 Next.js） | `pnpm run dev` | 3000 |
| 反向代理（如 nginx） | `nginx -c ... -g 'daemon off;'` | 2026 |

**启动策略**：
1. **阅读 Makefile / `docker-compose.yml`**：找出项目需要启动哪些服务以及各自的端口。
2. **每个服务用独立的后台命令启动**（`block_until_ms: 0`），并轮询终端文件确认启动成功。
3. **按依赖顺序启动**：后端优先，前端在后端就绪后启动。
4. **若 nginx 不可用**：跳过 nginx，配置前端 `.env` 直接指向后端服务端口（见阶段五第 3 点）。此时前端直接通过 `http://localhost:3000` 访问。

### Docker 方式启动

若项目推荐 Docker 方式且 Docker 可用：
```powershell
docker compose -f docker/docker-compose-dev.yaml up --build -d
```
- 若需设置环境变量（如 `DEER_FLOW_ROOT`），先设置再启动：
  ```powershell
  $env:DEER_FLOW_ROOT = (Get-Location).Path
  docker compose -f docker/docker-compose-dev.yaml up --build -d
  ```
- Docker 启动失败（守护进程未运行），**应自动回退到本地启动方式**。

### 验证运行

1. **后端验证**：查找健康检查端口/端点并访问：
   ```powershell
   Invoke-RestMethod -Uri "http://localhost:<port>/api/health" -Method Get
   ```
   或访问根路径确认返回正常。

2. **前端验证**：确认开发服务器启动日志中出现以下模式之一：
   - `Local: http://localhost:<port>`（Next.js / Vite）
   - `ready in <N>ms`
   - `GET / 200`（成功响应页面请求）

3. **Rust 项目验证**：
   - 先执行 `cargo run -- --help`，确认二进制正常输出帮助信息（exit code 0）。
   - 若项目有 `status` / `doctor` / `version` 子命令，执行并检查输出。
   - 完整启动时检查日志：出现 `Starting ...` / 启动信息即为正常；出现 `Configuration error` 表示需要先执行 `onboard` 配置。
   - **Cargo warning 不是错误**：编译输出中 `warning:` 是正常的，只要最终出现 `Finished` 即表示编译成功。

4. **Pygame / GUI 桌面应用验证**：
   - 这类项目启动后会弹出本地窗口（非 HTTP 服务），**无法用 `Invoke-RestMethod` 验证**。
   - 以 `block_until_ms: 5000`（或更短）启动 `python main.py`，命令会进入后台（因为 Pygame 事件循环不会立即退出）。
   - 读取终端输出文件，确认**无 `Traceback`、`Error`、`ModuleNotFoundError`** 等错误信息即为启动成功。
   - 若进程持续运行（PID 存在、无 exit_code），说明窗口已正常弹出。
   - 关闭游戏窗口即自动退出进程。

5. 若验证失败，分析错误日志并尝试修复；无法自动修复的记入 `user-todolist.md`。

6. **缺少依赖的逐步修复**：
   - Python：`ModuleNotFoundError` 说明依赖未完整安装。
   - Rust：`error: failed to run custom build command for ...` 通常是缺少系统库或编译工具（如 CMake、pkg-config）。尝试切换 features 绕过，或记入 `user-todolist.md` 提示用户安装对应工具。

---

## 阶段七：分支与远程管理

### 创建分支

**从当前 HEAD 创建并切换**（最常用）：
```powershell
git checkout -b <new-branch>
```
或使用 Git 2.23+ 的 `switch`：
```powershell
git switch -c <new-branch>
```

**从指定起点创建分支**（不切换）：
```powershell
# 从指定分支创建
git branch <new-branch> <base-branch>

# 从指定提交创建
git branch <new-branch> <commit-hash>

# 从标签创建
git branch <new-branch> <tag-name>
```

**从指定起点创建并切换**：
```powershell
git checkout -b <new-branch> <base-branch>
# 或
git switch -c <new-branch> <base-branch>
```

**基于远程分支创建本地分支**：
```powershell
# 先拉取最新远程分支列表
git fetch origin

# 从远程分支创建并跟踪
git checkout -b <local-branch> origin/<remote-branch>
# 或
git switch -c <local-branch> origin/<remote-branch>
```

**在远程创建分支**（推送新分支即创建）：
```powershell
git push -u origin <branch>
```

**分支命名建议**：`feature/xxx`、`fix/xxx`、`docs/xxx`、`release/xxx`，避免空格与特殊字符。

### 分支操作（查看、删除）

```powershell
# 查看所有分支（含远程）
git branch -a

# 查看当前分支
git branch

# 删除本地分支（已合并才允许 -d）
git branch -d <branch>

# 强制删除本地分支
git branch -D <branch>

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

## 阶段八：推送与拉取

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

## 阶段九：Pull Request

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

## 阶段十：生成文档

### 生成运行说明文档

在项目根目录生成**中文运行说明文档**（文件名参考项目已有命名惯例，如 `运行说明.md` 或 `Run-README.md`），包含以下章节：

```markdown
# <项目名称> 运行说明

## 一、环境要求
[列出 Python/Node/uv/pnpm/Docker/nginx 等版本要求]

## 二、配置
### 1. 生成配置文件
[列出所有需要从模板复制的文件，提供 Bash 和 PowerShell 两种命令]
### 2. 配置模型/API 密钥
[编辑哪些文件，填写哪些字段]

## 三、运行项目
### 方式一：Docker（推荐）
[Docker 命令]
### 方式二：本地开发
[安装依赖 + 启动各服务的命令，含 Windows PowerShell 特别说明]

## 四、访问地址
[端口号和 URL 表格]

## 五、验证运行
[具体的验证命令和预期输出]

## 六、常见问题
[端口冲突、依赖缺失、网络问题、Docker 未启动、nginx 不可用、Rust feature 编译失败等]

## 七、停止服务
[停止命令]
```

**关键规则**：
- 提供 **Bash** 和 **PowerShell** 两种命令（许多项目的 Makefile 是 Bash 专用）。
- 列出实际的端口号和 URL。
- 包含 `Invoke-RestMethod` 验证示例。
- 注明安装耗时预期（如"依赖较多，首次安装约 5–15 分钟"）。
- 说明 Windows 下 `make` 不可用时的替代方案。

### 生成 user-todolist.md（按需）

若有需要用户手动完成的事项，生成 `user-todolist.md`：

```markdown
# 待办事项（需要您手动完成）

## 必须完成
- [ ] 在 .env 中填写 API Key: `YOUR_API_KEY_HERE`
- [ ] 在 config.yaml 中配置至少一个模型
- [ ] 启动 Docker Desktop（若使用 Docker 方式运行）

## 建议完成
- [ ] 检查网络连接（uv sync / pip install 因 DNS 失败需重试）
- [ ] 安装 nginx（若需要统一反向代理入口）
- [ ] 安装 make（或使用 WSL/Git Bash）以使用 Makefile 中的便捷命令
- [ ] 配置 pip/uv 代理或镜像源（加速依赖下载）
- [ ] 安装 CMake（若 Rust 项目某些 crate 编译需要）
- [ ] 执行 `cargo run -- onboard` 完成首次交互式配置（Rust 项目）
```

---

## 完整工作流示例

### 示例一：搜索 → Fork → Clone → 运行 → 修改 → 推送 → PR

```powershell
# 1. 搜索项目
gh search repos "awesome-tool" --sort stars --limit 5

# 2. Fork 并 Clone
gh repo fork owner/awesome-tool --clone
Set-Location awesome-tool

# 3. 安装依赖（根据项目类型，参考阶段四）
pnpm install          # Node.js 项目
# uv sync             # Python uv 项目
# cargo build         # Rust 项目

# 4. 启动并验证（参考阶段六）
pnpm run dev

# 5. 创建功能分支
git checkout -b feature/my-change

# 6. ... 修改代码 ...

# 7. 提交并推送
git add -A
git commit -m "feat: add my feature"
git push -u origin feature/my-change

# 8. 创建 PR 到上游
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
- **网络问题**：出现 `fatal: unable to access` 或 `Could not resolve host` 时，按以下步骤排查：

  **1. 诊断网络连通性**：
  ```powershell
  # 测试 DNS 解析和网络连通
  ping -n 2 github.com

  # 查看 git 代理配置
  git config --global http.proxy
  git config --global https.proxy

  # 查看环境变量中的代理
  $env:HTTP_PROXY; $env:HTTPS_PROXY

  # 查看 Windows 系统代理
  netsh winhttp show proxy
  ```

  **2. 常见原因与解决**：

  | 现象 | 原因 | 解决 |
  |------|------|------|
  | ping 通但 git 失败 | 临时 DNS 波动 | 稍等片刻后重试 |
  | ping 不通 | 网络断开或被墙 | 检查网络连接、VPN |
  | 有代理但 git 未配置 | git 未走代理 | 配置 git 代理（见下方） |
  | git 配了代理但代理已关闭 | 残留代理配置 | 清除 git 代理（见下方） |

  **3. 配置 / 清除代理**：
  ```powershell
  # 设置代理
  git config --global http.proxy http://proxy:port
  git config --global https.proxy http://proxy:port

  # 清除代理（代理已关闭时必须清除，否则连接会失败）
  git config --global --unset http.proxy
  git config --global --unset https.proxy
  ```

  **4. 临时 DNS 故障**：若 `ping github.com` 正常但 git 报 `Could not resolve host`，多为偶发性 DNS 波动，直接重试即可。也可手动刷新 DNS 缓存：
  ```powershell
  ipconfig /flushdns
  ```
- **Fork 已存在**：若 Fork 目标仓库已经 Fork 过，`gh repo fork` 会提示已存在并直接使用已有 Fork。
- **端口冲突**：启动前用 `netstat -ano | findstr :<port>` 检查端口占用。若被占，选择下一个可用端口并修改配置。
- **虚拟环境**：uv 项目自动管理 `.venv`，无需手动操作；pip 项目若有 `.venv` 目录，先激活：`.\.venv\Scripts\Activate.ps1`
- **权限问题**：PowerShell 执行策略可能阻止脚本，提示用户运行：
  `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- **Windows 符号链接权限**：某些 Rust crate（如 `v8-goose`、`rusty_v8`）在构建时需要创建符号链接。若报 error 1314，需开启 Windows 开发者模式或以管理员身份运行终端（见 Rust 注意事项第 4 点）。**必须在构建前检测并处理**，否则长时间编译后在最后一步失败会浪费大量时间。
- **CRLF 换行符问题**：从 Windows 克隆的项目中 shell 脚本（`.sh`、`activate-hermit` 等）可能被 Git 自动转为 CRLF，导致在 WSL/Git Bash 中报 `$'\r': command not found`。修复方法：
  ```powershell
  $f = [IO.File]::ReadAllText("path/to/script") -replace "`r`n", "`n"
  [IO.File]::WriteAllText("path/to/script", $f)
  ```
  但这通常不影响 Windows 原生构建，仅在尝试 WSL 方式时需要处理。
- **依赖安装超时**：`uv sync`、`pip install -e .`、`cargo build` 可能耗时数分钟甚至十几分钟，必须以 `block_until_ms: 0` 后台执行并轮询。**绝不要**设置固定超时等待。
- **PowerShell 脚本编码**：生成的 `.ps1` 脚本中**避免使用中文或非 ASCII 字符**（Write-Host 的消息、注释等），否则在某些终端编码下会导致 `TerminatorExpectedAtEndOfString` 解析错误。所有 `.ps1` 脚本中的消息和注释应使用英文。中文说明放在 `.md` 文档中（UTF-8 编码，不影响解析）。
- **网络问题**：`getaddrinfo failed`、`Could not connect, are you offline?`、`warning: spurious network error` 表示网络不通或不稳定，不是项目本身的错误。cargo 会自动重试网络错误。
- **Docker 不可用时的回退**：Windows 上 Docker Desktop 可能未启动。若 Docker 方式失败，自动回退到本地开发方式：分别安装前后端依赖，配置前端直连后端，逐个启动各服务。
- **Windows 无 make 但有 just**：优先检查项目是否有 `justfile`，just 原生支持 Windows 且常有 `win-*` 专用目标。若只有 `Makefile`，阅读内容提取实际命令，转写为 PowerShell。
- **Hermit 不支持 Windows**：若项目使用 Hermit（`bin/hermit`），忽略它，直接手动安装项目所需的工具链。
- **多进程管理**：本地启动多个服务时，每个服务在独立后台终端中运行。停止时需逐个终止进程（用 `Stop-Process`）。
- **Rust 构建前预检清单**：在执行耗时的 `cargo build` 之前，先确认以下几项，避免长时间编译后在后期失败：
  1. `cargo --version` 可用（PATH 正确）
  2. Windows 开发者模式已开启或以管理员运行（若项目含 V8 等需要 symlink 的 crate）
  3. Visual C++ Build Tools 已安装（MSVC 链接器）
  4. 若项目有 justfile，阅读其中的构建目标确认完整流程（可能还需要 `npm install` 等步骤）
- **Git Clone SSL 错误**：`git clone` 报 `OpenSSL SSL_connect: SSL_ERROR_SYSCALL in connection to github.com:443` 时，通常是网络波动或代理配置问题。处理方法：
  1. 先检查代理配置是否正确（`git config --global http.proxy`）
  2. 重试一次（偶发性）
  3. 若从搜索结果中有多个候选仓库，直接尝试克隆下一个候选仓库而非反复重试
  4. 最后手段：`git config --global http.sslVerify false`（不推荐，用完后恢复 `git config --global http.sslVerify true`）
