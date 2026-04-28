---
name: install-from-url
description: Install any tool or software by reading its official documentation URL. Fetches the install page, detects OS/arch, extracts install commands, executes them, and verifies the installation. Use when the user provides a URL to a tool's install/setup page and asks to install it, or when the user says "install X from <url>".
---

# Install From URL

根据用户提供的工具/软件官方文档链接，自动读取安装说明并执行安装。

## Workflow

### Phase 1: 获取安装说明

1. 用户提供一个工具或软件的官方文档/安装页面 URL。
2. 使用 WebFetch 工具抓取页面内容，提取安装相关信息：
   - 安装命令（shell 命令、包管理器命令等）
   - 系统要求（OS、架构、依赖）
   - 多平台安装方式（macOS、Linux、Windows）
   - 版本信息

3. 若页面无法抓取或内容不足，使用 WebSearch 搜索 `<tool-name> install <os-name> <year>` 补充信息。

### Phase 2: 检测环境

1. 检测当前操作系统和架构：

   ```bash
   # macOS/Linux
   uname -s   # Darwin / Linux
   uname -m   # arm64 / x86_64

   # Windows PowerShell
   [System.Runtime.InteropServices.RuntimeInformation]::OSDescription
   [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture
   ```

2. 检测是否已安装目标工具（通过 `which`/`where.exe` 或 `--version`）。
3. 若已安装，报告当前版本，询问用户是否需要升级。

### Phase 3: 选择安装方式

根据 OS 选择合适的安装方式（优先级从高到低）：

| OS      | 优先安装方式                                                                  |
| ------- | ----------------------------------------------------------------------------- |
| macOS    macOS   | Homebrew ( Homebrew (`brew install`) > 官方安装脚本 () > 官方安装脚本 (`curl \| bash`) > 手动下载          ) > 手动下载          |
| Linux   | 官方安装脚本 > 包管理器 (`apt`/`dnf`/`pacman`) > 手动下载                     |
| Windows | winget > Scoop/Chocolatey > 官方安装脚本 (PowerShell `irm \| iex`) > 手动下载 |

**选择原则**：

- 优先使用文档推荐的方式
- 脚本安装（`curl | bash` / `irm | iex`）通常最简便
- 包管理器安装便于后续升级
- 手动下载作为最后手段

### Phase 4: 执行安装

1. **安装前检查**：
   - 确认网络连通（`curl -sI <url>` 或 `Test-NetConnection`）
   - 确认包管理器可用（如需要 Homebrew 则先检查 `brew`）

2. **执行安装命令**：
   - 对于快速安装（< 30s），正常执行
   - 对于耗时安装（编译型工具），设置 `block_until_ms: 0` 后台执行并轮询

3. **PATH 处理**：
   安装后工具可能不在 PATH 中，按 OS 处理：

   ```bash
   # macOS/Linux - 检查常见路径
   export PATH="$HOME/.local/bin:$HOME/.cargo/bin:/usr/local/bin:$PATH"

   # Windows PowerShell - 刷新 PATH
   $env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
   ```

### Phase 5: 验证安装（关键步骤）

安装完成后**必须**执行完整验证，确保工具可在新终端中正常使用：

#### 5.1 当前 Shell 验证

1. 执行 `<tool> --version` 或文档中提到的验证命令。
2. 若找不到命令，按顺序排查：
   - 检查安装输出中提示的路径，手动加入当前 `$PATH` / `$env:Path`
   - 搜索常见安装路径：
     ```bash
     # macOS/Linux
     ls ~/.local/bin/<tool> /usr/local/bin/<tool> ~/.cargo/bin/<tool> 2>/dev/null
     ```
     ```powershell
     # Windows
     Get-Command <tool> -ErrorAction SilentlyContinue
     where.exe <tool>
     ```
   - 加入 PATH 后重新验证

#### 5.2 PATH 持久化验证

确保工具在**新终端**中也可用，而非仅当前会话生效：

1. **检测当前 shell 的配置文件**：

   ```bash
   # macOS — 终端打开 login shell，读 .bash_profile 或 .zprofile
   echo $SHELL
   # /bin/bash  → ~/.bash_profile（不是 ~/.bashrc）
   # /bin/zsh   → ~/.zshrc
   ```

2. **检查 PATH 是否已写入正确的配置文件**：

   ```bash
   # macOS bash 用户
   grep -q '<install-path>' ~/.bash_profile 2>/dev/null && echo "OK" || echo "MISSING"
   # macOS zsh 用户
   grep -q '<install-path>' ~/.zshrc 2>/dev/null && echo "OK" || echo "MISSING"
   ```

   ```powershell
   # Windows — 检查用户级 PATH
   [Environment]::GetEnvironmentVariable("Path","User") -split ";" | Select-String "<install-path>"
   ```

3. **若 PATH 缺失，写入正确的配置文件**：

   | Shell      | 配置文件          | 注意                                          |
   | ---------- | ----------------- | --------------------------------------------- |
   | macOS bash | `~/.bash_profile` | **不要写 `~/.bashrc`**，macOS Terminal 不读它 |
   | macOS zsh  | `~/.zshrc`        | macOS 默认 shell                              |
   | Linux bash | `~/.bashrc`       | Linux 终端通常读 `.bashrc`                    |
   | Windows    | 系统环境变量      | 通过注册表或 `setx` 持久化                    |

4. **模拟新终端验证**（最终确认）：
   ```bash
   # macOS/Linux — 启动新 shell 子进程验证
   bash -lc '<tool> --version'   # bash login shell
   zsh -lc '<tool> --version'    # zsh login shell
   ```
   ```powershell
   # Windows — 新进程验证
   powershell -NoProfile -Command "<tool> --version"
   ```

#### 5.3 功能验证

除了 `--version`，还应执行一个基本功能命令确认工具可正常工作：

- CLI 工具：`<tool> --help` 或 `<tool> ls` 等基础子命令
- 运行时/编译器：编译或执行一个 hello-world 级示例
- 服务类工具：检查服务是否能正常启动

#### 5.4 验证失败处理

若验证始终失败：

1. 检查安装日志是否有报错 检查安装日志是否有报错 检查安装日志是否有报错 检查安装日志是否有报错 检查安装日志是否有报错 检查安装日志是否有报错 检查安装日志是否有报错 检查安装日志是否有报错
2. 检查是否缺少前置依赖（如 Xcode CLT、Visual C++ Build Tools） 检查是否缺少前置依赖（如 Xcode CLT、Visual C++ Build Tools）
3. 检查磁盘空间、权限问题 检查磁盘空间、权限问题 检查磁盘空间、权限问题 检查磁盘空间、权限问题
4. 将失败原因和排查建议输出给用户 将失败原因和排查建议输出给用户 将失败原因和排查建议输出给用户 将失败原因和排查建议输出给用户

### Phase 6: 输出总结

安装完成后输出：安装完成后输出：

```
安装结果：
- 工具：<tool-name>
- 版本：<version>
- 安装方式：<method>
- 安装路径：<path>
- PATH 持久化：已写入 <config-file> ✓
- 新终端验证：通过 ✓
- 参考文档：<url>

验证命令：<verify-command>
```

若需要用户手动操作（如重启终端、配置环境变量），明确列出：若需要用户手动操作（如重启终端、配置环境变量），明确列出：

```
⚠ 需要手动操作：
1. 关闭当前终端并重新打开（使 PATH 生效）
2. ...
```

## 注意事项

- **PATH 陷阱（macOS 重点）**：macOS Terminal.app 打开的是 ：macOS Terminal.app 打开的是 ：macOS Terminal.app 打开的是 ：macOS Terminal.app 打开的是 ：macOS Terminal.app 打开的是 ：macOS Terminal.app 打开的是 ：macOS Terminal.app 打开的是 ：macOS Terminal.app 打开的是 **login shell**，bash 读 ，bash 读 ，bash 读 ，bash 读 ，bash 读 ，bash 读 ，bash 读 ，bash 读 `~/.bash_profile`，zsh 读 ，zsh 读 ，zsh 读 ，zsh 读 ，zsh 读 ，zsh 读 ，zsh 读 ，zsh 读 `~/.zshrc`。。。。。。。。**绝不要**只写 只写 只写 只写 只写 只写 只写 只写 `~/.bashrc`，否则新终端找不到命令，否则新终端找不到命令，否则新终端找不到命令，否则新终端找不到命令，否则新终端找不到命令，否则新终端找不到命令，否则新终端找不到命令，否则新终端找不到命令
- **安全提醒**：执行 ：执行 `curl | bash` 类命令前，先用 WebFetch 确认 URL 指向官方域名 类命令前，先用 WebFetch 确认 URL 指向官方域名
- **代理/镜像**：若下载失败，提示用户检查网络或配置代理：若下载失败，提示用户检查网络或配置代理
- **权限**：需要 ：需要 `sudo` 的安装要提前告知用户 的安装要提前告知用户
- **多工具依赖**：若目标工具依赖其他工具（如 Cursor CLI 依赖 Node.js），先安装依赖：若目标工具依赖其他工具（如 Cursor CLI 依赖 Node.js），先安装依赖
- **跨平台命令**：macOS/Linux 用 bash 语法，Windows 用 PowerShell 语法，不混用：macOS/Linux 用 bash 语法，Windows 用 PowerShell 语法，不混用

## 常见工具安装模式速查

| 安装模式        | 命令模板                      | 示例                         |
| --------------- | ----------------------------- | ---------------------------- |
| curl 脚本        curl 脚本        curl 脚本        curl 脚本        curl 脚本        curl 脚本        curl 脚本        curl 脚本       | `curl <url> -fsS \| bash`     | Cursor CLI, Rustup, Homebrew  Cursor CLI, Rustup, Homebrew  Cursor CLI, Rustup, Homebrew  Cursor CLI, Rustup, Homebrew  Cursor CLI, Rustup, Homebrew  Cursor CLI, Rustup, Homebrew  Cursor CLI, Rustup, Homebrew  Cursor CLI, Rustup, Homebrew |
| PowerShell 脚本  PowerShell 脚本  PowerShell 脚本  PowerShell 脚本  PowerShell 脚本  PowerShell 脚本  PowerShell 脚本  PowerShell 脚本 | `irm '<url>' \| iex`          | Cursor CLI (Windows), uv      Cursor CLI (Windows), uv      Cursor CLI (Windows), uv      Cursor CLI (Windows), uv      Cursor CLI (Windows), uv      Cursor CLI (Windows), uv      Cursor CLI (Windows), uv      Cursor CLI (Windows), uv     |
| Homebrew         Homebrew         Homebrew         Homebrew         Homebrew         Homebrew         Homebrew         Homebrew        | `brew install <pkg>`          | 大部分 CLI 工具               大部分 CLI 工具               大部分 CLI 工具               大部分 CLI 工具               大部分 CLI 工具               大部分 CLI 工具               大部分 CLI 工具               大部分 CLI 工具              |
| npm 全局         npm 全局         npm 全局         npm 全局         npm 全局         npm 全局         npm 全局         npm 全局        | `npm install -g <pkg>`        | pnpm, yarn                    pnpm, yarn                    pnpm, yarn                    pnpm, yarn                    pnpm, yarn                    pnpm, yarn                    pnpm, yarn                    pnpm, yarn                   |
| pip              pip              pip              pip              pip              pip              pip              pip             | `python -m pip install <pkg>` | Python 工具                   Python 工具                   Python 工具                   Python 工具                   Python 工具                   Python 工具                   Python 工具                   Python 工具                  |
| cargo            cargo            cargo            cargo            cargo            cargo            cargo            cargo           | `cargo install <pkg>`         | Rust 工具                     Rust 工具                     Rust 工具                     Rust 工具                     Rust 工具                     Rust 工具                     Rust 工具                     Rust 工具                    |
| winget           winget           winget           winget           winget           winget           winget           winget          | `winget install <id>`         | Windows 工具                  Windows 工具                  Windows 工具                  Windows 工具                  Windows 工具                  Windows 工具                  Windows 工具                  Windows 工具                 |
| 手动二进制       手动二进制      | 下载压缩包 → 解压 → 加 PATH    下载压缩包 → 解压 → 加 PATH   | Go, just                      Go, just                     |
