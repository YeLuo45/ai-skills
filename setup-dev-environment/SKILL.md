---
name: setup-dev-environment
description: Detect, install, and configure development environments for Rust, Python, Go, Node.js, Java, and other languages on Windows. Covers essential tooling like uv, pnpm, just, nginx, make, and CMake, plus Windows Developer Mode for symlink support and Hermit workarounds. Use when the user asks to set up, install, or configure a programming language environment, SDK, runtime, or toolchain, or when dependency installation fails due to missing tools.
---

# Setup Development Environment

在 Windows PowerShell 下检测、安装和配置各语言开发环境及常用工具链。

## Workflow

1. 确定需要安装的语言/运行时/工具。
2. 检测当前系统是否已安装及版本。
3. 未安装则引导安装；已安装但版本过低则提示升级。
4. 配置环境变量、验证安装。
5. 将需要用户手动完成的步骤输出到 `user-todolist.md`。

## 检测命令速查

先用以下命令检测是否已安装：

```powershell
python --version         # Python
python -m pip --version  # pip（比直接调 pip 更可靠）
uv --version             # uv（Python 项目管理器）
node --version           # Node.js
npm --version            # npm
pnpm --version           # pnpm
go version               # Go
rustc --version          # Rust
cargo --version          # Cargo
just --version           # just（命令运行器）
java -version            # Java
javac -version           # JDK
mvn --version            # Maven
gradle --version         # Gradle
docker --version         # Docker
docker compose version   # Docker Compose V2
nginx -v                 # nginx
make --version           # make (GNU Make)
cmake --version          # CMake
git --version            # Git
```

## 各语言安装指南

---

### Python

**推荐版本**：3.12+（许多现代项目 `requires-python = ">=3.12"`）

**检测**：
```powershell
python --version; python -m pip --version
```

**安装**：`winget install Python.Python.3.12`（或官网 / Scoop）。验证：`python --version; python -m pip --version`

**虚拟环境**：`python -m venv .venv; .\.venv\Scripts\Activate.ps1`

**关键注意事项**：

1. **始终使用 `python -m pip`**，避免 pip 与 python 版本不一致。

2. **用户目录安装**：出现 `Defaulting to user installation` 时，CLI 入口可能不在 PATH。推荐用 `python -m <module>` 替代 CLI 命令。

3. **`python` 打开应用商店**：在"管理应用执行别名"中关闭 `python.exe` 别名。

4. **pip 镜像**：`python -m pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple`

5. **C 扩展编译**：需 Visual Studio Build Tools（见"常见跨语言问题"）。

6. **安装耗时**：大型项目 5–15 分钟，不要中断。

---

### uv（Python 项目管理器）

**说明**：uv 是现代 Python 项目管理工具（类似 Cargo），可替代 pip + venv + virtualenv。越来越多的项目使用 `uv.lock` + `uv sync` 管理依赖。

**推荐版本**：0.4+

**检测**：
```powershell
uv --version; where.exe uv
```

**安装**：`python -m pip install uv`（或 `winget install astral-sh.uv` / `irm https://astral.sh/uv/install.ps1 | iex`）。验证：`uv --version`

**关键注意事项**：

1. **uv 自动管理 Python 版本**：`uv sync` 会自动下载满足 `requires-python` 的 Python。用 `uv sync --python python` 强制使用系统 Python。
2. **uv 自动创建 venv**：`uv sync` 自动创建 `.venv`，无需手动操作。
3. **用 `uv run` 执行命令**：无需激活 venv，如 `uv run uvicorn app:app --port 8000`。
4. **网络问题**：配置镜像 `$env:UV_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple"`。

---

### Node.js

**推荐版本**：22+ LTS（许多现代项目如 Next.js 16+ 要求 Node 22+）

**检测**：
```powershell
node --version; npm --version
```

**安装**：`winget install OpenJS.NodeJS.LTS`（或官网 / nvm-windows / fnm）。验证：`node --version; npm --version`

**版本升级**：`winget upgrade OpenJS.NodeJS.LTS` 或 `nvm install 22; nvm use 22`。

---

### pnpm

**说明**：`package.json` 中 `"packageManager": "pnpm@x.x.x"` 时必须使用 pnpm。检测：`pnpm --version`

| 方式 | 命令 |
|------|------|
| npm（推荐） | `npm install -g pnpm` |
| corepack | `corepack enable`（Node 16.13+ 内置，自动管理版本） |
| winget | `winget install pnpm.pnpm` |

**注意**：版本匹配大版本即可。`pnpm` 不可用时检查 `npm config get prefix` 输出的目录是否在 PATH 中。

---

### nginx

**说明**：部分项目使用 nginx 作为本地反向代理。检测：`nginx -v`

| 方式 | 命令 |
|------|------|
| Scoop（推荐） | `scoop install nginx` |
| Chocolatey | `choco install nginx` |
| 手动 | 从 https://nginx.org/en/download.html 下载 zip，解压到 `C:\nginx`，加入 PATH |

**替代方案**：大多数项目可跳过 nginx，在前端 `.env` 中直连后端（如 `NEXT_PUBLIC_BACKEND_BASE_URL=http://localhost:8001`）。

---

### make (GNU Make)

**说明**：许多项目使用 Makefile。Windows 默认无 make。检测：`make --version`

| 方式 | 命令 |
|------|------|
| Scoop（推荐） | `scoop install make` |
| Chocolatey | `choco install make` |
| WSL（替代） | 在 WSL 中直接运行 `make` |

**注意**：Makefile 常含 Unix 命令（`pkill`、`lsof` 等），即使装了 make 也可能无法直接运行。**策略 A**：在 WSL/Git Bash 中执行。**策略 B**：阅读 Makefile，将核心命令转写为 PowerShell。

---

### Rust

**推荐版本**：最新 stable（`Cargo.toml` 中的 `rust-version` 字段标明最低要求，如 `1.85`、`1.92`）

**检测**：
```powershell
rustc --version; cargo --version
```

**重要**：Cargo 可能已安装但不在当前 shell 的 PATH 中（尤其是新安装后未重启终端）。即使 `Get-Command cargo` 失败，也要检查安装目录：
```powershell
if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
    if (Test-Path "$env:USERPROFILE\.cargo\bin\cargo.exe") {
        $env:Path = "$env:USERPROFILE\.cargo\bin;" + $env:Path
        Write-Host "Cargo found, added to PATH"
    }
}
```

**安装方式**：

| 方式 | 命令 / 步骤 | 说明 |
|------|-------------|------|
| 静默安装（推荐，自动化场景） | 见下方脚本 | 无需用户交互，适合 Agent 自动执行 |
| winget | `winget install Rustlang.Rustup` | 需要用户确认 |
| 官网安装包 | https://rustup.rs/ 下载 `rustup-init.exe` | 交互式安装 |

**静默安装脚本**（Agent 执行首选）：
```powershell
$rustupUrl = "https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe"
$dest = "$env:TEMP\rustup-init.exe"
Invoke-WebRequest -Uri $rustupUrl -OutFile $dest -UseBasicParsing
Start-Process -FilePath $dest -ArgumentList "-y" -Wait -NoNewWindow
# 安装完成后刷新当前会话 PATH
$env:Path = "$env:USERPROFILE\.cargo\bin;" + $env:Path
rustc --version; cargo --version
```
- `-y` 参数接受所有默认选项，无交互提示。
- 安装耗时约 1–3 分钟（取决于网络速度，需下载 ~200MB 工具链）。
- 安装后 **当前终端** 需要手动添加 PATH（如上），或者重新打开终端。

**安装后验证**：
```powershell
rustc --version; cargo --version; rustup show
```

**前置依赖**：
- **必须**：Visual Studio Build Tools（C/C++ 工具链）。Rust 的 `x86_64-pc-windows-msvc` 目标需要 MSVC 链接器。
- 安装命令：
  ```powershell
  winget install Microsoft.VisualStudio.2022.BuildTools --override "--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --quiet --wait"
  ```
- 安装后需重启终端使环境变量生效。

**关键注意事项**：

1. **编译耗时极长**：Rust 项目首次 `cargo build` 需要下载并编译所有依赖 crate。大型项目（100+ 依赖）首次编译可能需 **5–30 分钟**。这是正常现象，不要中断。后续编译（增量编译）会快得多（几秒到几十秒）。

2. **`warning:` 不是错误**：编译过程中出现 `warning: unused import`、`warning: dead_code` 等警告是正常的，只要最终出现 `Finished` 即表示编译成功。`warning: spurious network error` 表示网络不稳定但 cargo 会自动重试。

3. **Rustup 工具链同步失败**：首次安装后或执行 `cargo` 时，rustup 会自动下载工具链组件。可能出现的错误及修复：
   - `could not rename downloaded file` / `could not rename component file`：文件被其他进程锁定（杀毒软件、OneDrive、其他终端等）。**关闭这些程序后重试**。
   - `detected conflict: 'bin\rust-gdb'`：工具链文件冲突。执行：
     ```powershell
     rustup toolchain uninstall stable; rustup default stable
     ```
   - 持续失败时，清空缓存后重装：
     ```powershell
     Remove-Item -Recurse -Force "$env:USERPROFILE\.rustup\downloads" -ErrorAction SilentlyContinue
     Remove-Item -Recurse -Force "$env:USERPROFILE\.rustup\tmp" -ErrorAction SilentlyContinue
     rustup default stable
     ```
   - 使用 `rustup repair` 可尝试自动修复受损安装。

4. **Windows 符号链接权限（error 1314）**：某些 crate（`v8-goose`、`rusty_v8`、`deno_core`、`librocksdb-sys` 等）在 build script 中创建符号链接（symlink），Windows 默认不允许普通用户创建。报错特征：
   ```
   symlink_dir failed: Os { code: 1314, ... "客户端没有所需的特权。" }
   Failed to create symlink
   ```
   **解决方法**：开启 Windows 开发者模式（见下方"Windows 开发者模式"章节），或以管理员身份运行终端。**必须在 `cargo build` 之前处理**，否则长时间编译后在后期阶段失败浪费大量时间。

5. **Feature flags 与编译失败**：Rust 项目的 `Cargo.toml` 中可能定义了多个 features，某些 feature 的依赖 crate 需要额外的系统工具才能编译：
   - `libsql-ffi`：需要 **CMake** 和 C 编译器来编译嵌入式 SQLite
   - `openssl-sys`：需要 **OpenSSL** 开发库（或使用 `vendored` feature）
   - `rdkafka-sys`：需要 **CMake** 和 C 编译器
   - `rocksdb-sys`：需要 **CMake**
   - `v8-goose` / `rusty_v8`：需要 **符号链接权限**（开发者模式或管理员）
   
   若 `cargo build` 因某个 crate 的 `build-script-build` 失败，策略：
   1. 阅读 `Cargo.toml` 的 `[features]` 段，找出该 crate 属于哪个 feature
   2. 用 `--no-default-features --features feat1,feat2` 排除问题 feature
   3. 或安装缺失的系统工具（CMake 等，见下方）

6. **CMake 安装**（部分 Rust crate 编译需要）：
   ```powershell
   winget install Kitware.CMake
   # 安装后重启终端
   cmake --version
   ```

7. **`cargo run` 传参**：项目自身的 CLI 参数放在 `--` 之后：
   ```powershell
   cargo run -- --help
   cargo run -- status
   cargo run --no-default-features --features X,Y -- --help
   ```

8. **Rust 版本不满足**：若 `Cargo.toml` 要求 `rust-version = "1.92"` 而系统安装的是较旧版本：
   ```powershell
   rustup update stable
   rustc --version   # 确认已更新
   ```

---

### just（命令运行器）

**说明**：[just](https://github.com/casey/just) 是类似 `make` 的命令运行器，但语法更简洁且**原生支持 Windows**（通过 `set windows-shell`）。越来越多的跨平台项目使用 `justfile` 替代或配合 `Makefile`。

**检测**：
```powershell
just --version
```

**安装方式**：

| 方式 | 命令 |
|------|------|
| winget（推荐） | `winget install -e --id Casey.Just` |
| Scoop | `scoop install just` |
| Chocolatey | `choco install just` |
| cargo | `cargo install just` |
| 手动 | 从 https://github.com/casey/just/releases 下载 `just-*-x86_64-pc-windows-msvc.zip`，解压 `just.exe` 到 PATH 中的目录 |

**安装后验证**（可能需要新开终端刷新 PATH）：
```powershell
just --version
just --list     # 在项目目录中列出所有可用目标
```

**关键注意事项**：

1. **winget 安装后 PATH 不立即生效**：winget 安装 just 后，当前终端可能找不到 `just`。需要新开一个 PowerShell，或手动刷新 PATH：
   ```powershell
   $env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
   ```

2. **Windows 专用目标**：许多项目在 justfile 中定义了 `win-` 前缀目标（如 `win-total-dbg`、`win-bld-rls`），这些目标已适配 Windows PowerShell，无需额外处理。用 `just --list` 查看所有可用目标。

3. **just 与 Hermit 的关系**：使用 Hermit 的项目通常也提供了 justfile。在 Windows 上忽略 Hermit（不支持 Windows），直接使用 `just` + 系统安装的工具链。

---

### Windows 开发者模式

**说明**：Windows 开发者模式允许普通用户创建符号链接（symlink），这是部分 Rust crate（如 `v8-goose`、`rusty_v8`）和某些 Node.js 工具在构建时需要的权限。不开启会报 error 1314。

**检测是否已开启**：
```powershell
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
$val = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
if ($val -eq 1) { Write-Host "Developer Mode: ON" -ForegroundColor Green }
else { Write-Host "Developer Mode: OFF" -ForegroundColor Yellow }
```

**开启方式**：
1. 按 `Win + I` → **设置**
2. **隐私和安全** → **针对开发人员**（Windows 11）；或 **更新和安全** → **针对开发人员**（Windows 10）
3. 打开 **开发人员模式** 开关
4. 确认弹出的对话框
5. **重新打开终端**使设置生效

**何时需要开启**：
- Rust 项目编译报 `symlink_dir failed: Os { code: 1314 }`
- 涉及 `v8-goose`、`rusty_v8`、`deno_core`、`librocksdb-sys` 等 crate
- 使用 `npm link` 或其他需要 symlink 的 Node.js 操作

**替代方案**：以管理员身份运行终端也能创建符号链接，但不如开发者模式方便（需每次都用管理员终端）。

---

### Hermit（仅 Linux/macOS）

**说明**：[Hermit](https://cashapp.github.io/hermit/) 是一个开发依赖管理器，用于在项目中锁定工具链版本。**Hermit 不支持 Windows**。

**识别**：项目中存在 `bin/hermit`、`bin/activate-hermit` 文件。

**Windows 上的处理**：
1. **不要尝试运行** `bin/activate-hermit` 或 `bin/hermit`，它们是 bash 脚本 + 平台特定二进制。
2. **查看 Hermit 配置**：阅读 `bin/hermit.hcl` 或项目的 `bin/` 目录，了解项目需要哪些工具及版本。
3. **手动安装对应工具**：根据项目的 `CONTRIBUTING.md` 或 `README.md` 中列出的工具链要求，用 winget/scoop/官网 安装。常见的 Hermit 管理的工具：Rust、Node.js、just、protoc 等。
4. **优先使用 justfile**：使用 Hermit 的项目几乎都提供了 `justfile`，且常有 Windows 专用目标。

---

### Go

**推荐版本**：1.21+。检测：`go version`。安装：`winget install GoLang.Go`。代理：`go env -w GOPROXY=https://goproxy.cn,direct`

---

### Java

**推荐版本**：JDK 17+ (LTS)。检测：`java -version`。安装：`winget install EclipseAdoptium.Temurin.17.JDK`。Maven：`winget install Apache.Maven`，Gradle：`winget install Gradle.Gradle`。

---

### Docker

检测：`docker --version; docker compose version`。安装：`winget install Docker.DockerDesktop`

安装后需重启系统并启动 Docker Desktop。WSL2 是必须的后端：`wsl --install`

**关键注意事项**：
- `open //./pipe/dockerDesktopLinuxEngine: The system cannot find the file specified` 表示 Docker Desktop 守护进程未运行，需先启动。
- 现代项目使用 `docker compose`（V2，无连字符），Docker Desktop 内置。

---

### Git

检测：`git --version`。安装：`winget install Git.Git`

---

## 批量检测脚本

一次性检测所有常用工具是否已安装：

```powershell
$tools = @(
    @{Name="Git";           Cmd="git --version"},
    @{Name="Python";        Cmd="python --version"},
    @{Name="pip";           Cmd="python -m pip --version"},
    @{Name="uv";            Cmd="uv --version"},
    @{Name="Node.js";       Cmd="node --version"},
    @{Name="npm";           Cmd="npm --version"},
    @{Name="pnpm";          Cmd="pnpm --version"},
    @{Name="Go";            Cmd="go version"},
    @{Name="Rust";          Cmd="rustc --version"},
    @{Name="Cargo";         Cmd="cargo --version"},
    @{Name="just";          Cmd="just --version"},
    @{Name="Java";          Cmd="java -version 2>&1 | Select-Object -First 1"},
    @{Name="Maven";         Cmd="mvn --version 2>&1 | Select-Object -First 1"},
    @{Name="Docker";        Cmd="docker --version"},
    @{Name="Docker Compose";Cmd="docker compose version"},
    @{Name="nginx";         Cmd="nginx -v 2>&1"},
    @{Name="make";          Cmd="make --version 2>&1 | Select-Object -First 1"},
    @{Name="CMake";         Cmd="cmake --version 2>&1 | Select-Object -First 1"}
)
foreach ($t in $tools) {
    try {
        $ver = Invoke-Expression $t.Cmd 2>&1 | Select-Object -First 1
        if ($LASTEXITCODE -ne 0 -and $null -eq $ver) { throw "not found" }
        Write-Host "[OK] $($t.Name): $ver" -ForegroundColor Green
    } catch {
        Write-Host "[--] $($t.Name): not installed" -ForegroundColor Yellow
    }
}

# 检测 Windows 开发者模式
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock"
$devMode = (Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue).AllowDevelopmentWithoutDevLicense
if ($devMode -eq 1) { Write-Host "[OK] Windows Developer Mode: ON" -ForegroundColor Green }
else { Write-Host "[--] Windows Developer Mode: OFF (needed for Rust symlink crates)" -ForegroundColor Yellow }
```

## 常见跨语言问题

### 网络问题排查

任何包管理器（pip/uv/npm/cargo）都可能因网络问题失败。排查：
```powershell
Test-NetConnection pypi.org -Port 443      # 测试连通性
Resolve-DnsName pypi.org                    # 检查 DNS
$env:HTTP_PROXY = "http://proxy:port"       # 设置代理（当前会话）
$env:HTTPS_PROXY = "http://proxy:port"
# 永久设置
[Environment]::SetEnvironmentVariable("HTTPS_PROXY", "http://proxy:port", "User")
```

### Visual C++ Build Tools

Python（crcmod、pycrypto 等）和 Rust 都可能需要 C/C++ 编译器：

```powershell
winget install Microsoft.VisualStudio.2022.BuildTools --override "--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --quiet --wait"
```

### CMake

部分 Rust crate（如 `libsql-ffi`、`rocksdb-sys`、`rdkafka-sys`）和一些 Python C 扩展的构建需要 CMake：

**检测**：
```powershell
cmake --version
```

**安装**：
```powershell
winget install Kitware.CMake
```

安装后重启终端，确认 `cmake --version` 可用。典型的编译错误提示为 `failed to run custom build command`、`program not found`、`cmake not found`。

### PATH 生效问题

Windows 下修改环境变量后，**当前终端不会自动刷新**。需要：
- 关闭并重新打开终端，或
- 手动刷新（仅限当前会话）：
  ```powershell
  $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
  ```

**常见安装路径**（刷新后仍找不到时手动添加）：

| 工具 | 默认安装路径 |
|------|-------------|
| Cargo/Rust | `$env:USERPROFILE\.cargo\bin` |
| Python (winget) | `C:\Users\<user>\AppData\Local\Programs\Python\Python3XX\` |
| Node.js (winget) | `C:\Program Files\nodejs\` |
| just (winget) | `C:\Users\<user>\AppData\Local\Microsoft\WinGet\Links\` |
| CMake (winget) | `C:\Program Files\CMake\bin\` |
| Go | `C:\Program Files\Go\bin\` |

**Agent 自动化最佳实践**：安装工具后，在同一 shell 会话中立即将已知路径加入 `$env:Path`，无需等用户重启终端：
```powershell
# 示例：安装 Rust 后立即可用
$env:Path = "$env:USERPROFILE\.cargo\bin;" + $env:Path
```

## 输出规范

- 所有命令使用 **PowerShell 语法**，多命令用分号 `;`，**不使用 `&&`**（PowerShell 5.x 不支持）。
- 需要用户手动完成的步骤（如重启、登录、获取密钥）写入 `user-todolist.md`。
- 安装完成后，给出简洁的验证命令总结。
