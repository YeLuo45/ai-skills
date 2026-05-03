---
name: app-development-guide
description: 各平台应用开发指南 — Web、微信小程序、Android、iOS、Windows、Mac 及跨平台方案
triggers:
  - 了解XX开发
  - XX开发需要什么
  - 学习XX开发
  - app开发准备
  - 小程序开发
  - 移动开发
  - 桌面应用开发
---

# 各平台应用开发完整指南

本技能涵盖：Web、微信小程序、Android、iOS、Windows、Mac 六大平台的开发技术栈和准备事项。

---

## 1. Web开发

### 技术栈
| 层级 | 技术 |
|------|------|
| 前端 | HTML5 / CSS3 / JavaScript (ES6+) |
| 框架 | React / Vue.js / Angular / Svelte |
| 后端 | Node.js / Python (Django/Flask) / Java (Spring) / Go / PHP |
| 数据库 | MySQL / PostgreSQL / MongoDB / Redis |
| 开发工具 | VS Code / WebStorm / Vite / webpack |

### 已安装开发工具（WSL环境）
```bash
export PATH=~/.npm-global/bin:$PATH
```
| 类别 | 工具 | 版本 | 用途 |
|------|------|------|------|
| 运行时 | Node.js | 18.19.1 | JS运行环境 |
| 包管理 | npm | 9.2.0 | 包管理 |
| 包管理 | yarn | 1.22.22 | 包管理（备选） |
| 包管理 | pnpm | 10.33.0 | 高效包管理 |
| 构建 | vite | 4.5.0 | 前端构建/热重载 |
| 构建 | typescript | 6.0.2 | 类型检查/编译 |
| 开发服务 | http-server | 14.1.1 | 静态服务器 |
| 开发服务 | json-server | 1.0.0-beta.15 | Mock API |
| 开发服务 | serve | 14.2.6 | 静态服务 |
| 开发服务 | nodemon | 3.1.14 | 热重载 |
| 进程管理 | pm2 | 6.0.14 | Node进程管理 |
| 代码质量 | eslint | 10.2.0 | 代码检查 |
| 代码质量 | prettier | 3.8.3 | 代码格式化 |
| 工具库 | cross-env | - | 跨平台环境变量 |
| 工具库 | rimraf | - | 删除目录 |
| 工具库 | axios | - | HTTP客户端 |
| 工具库 | http-proxy-middleware | - | 代理中间件 |
| 工具库 | ts-node | 10.9.2 | TypeScript执行 |
| Python | python3 | 3.12.3 | 后端/脚本 |
| Git | git | 2.43.0 | 版本控制 |

### 提前准备
- [ ] 域名注册（可选，开发阶段可用 localhost）
- [ ] 服务器或云服务账号（AWS / 阿里云 / 腾讯云）
- [ ] HTTPS 证书（生产环境必需）
- [ ] Git 版本控制
- [ ] API 设计和 RESTful 规范
- [ ] 前端构建工具（Vite / webpack / esbuild）

### 推荐学习路径
1. HTML + CSS + JavaScript 基础
2. 响应式设计（Flexbox / Grid）
3. 至少一个前端框架（推荐 React 或 Vue）
4. Node.js 基础 + Express/Koa
5. 数据库 + ORM
6. 部署和 CI/CD

---

## 2. 微信小程序

### 技术栈
| 分类 | 技术 |
|------|------|
| 框架 | 原生 WXML + WXSS + JS / uni-app / Taro / mpvue |
| 开发工具 | 微信开发者工具 |
| API | 微信小程序 API |

### 提前准备
- [ ] 微信公众平台账号（https://mp.weixin.qq.com/）
- [ ] 申请小程序 AppID（非个人开发者需企业认证）
- [ ] 下载安装微信开发者工具
- [ ] 服务器域名（需 HTTPS，生产环境必需）
- [ ] 了解微信小程序开发文档限制

### 开发注意
- 不支持直接操作 DOM
- 需适配不同机型的屏幕尺寸
- 用户授权需明确告知用途
- 审核较严格，有内容限制

---

## 3. Android开发

### 技术栈
| 分类 | 技术 |
|------|------|
| 语言 | Kotlin（推荐）/ Java |
| IDE | Android Studio |
| UI | Jetpack Compose / XML布局 |
| 架构 | MVVM / MVI / Clean Architecture |
| DI | Hilt / Koin |
| 网络 | Retrofit / OkHttp |
| 数据库 | Room |

### 已安装开发工具（WSL环境）
```bash
export ANDROID_HOME=/mnt/c/Users/YeZhimin/AppData/Local/Android/Sdk
export PATH="$HOME/.local/bin:$HOME/.local/gradle/gradle-8.10/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
```
| 类别 | 工具 | 版本 | 路径 |
|------|------|------|------|
| JDK | OpenJDK | 17.0.18 | /usr/lib/jvm/java-17-openjdk-amd64 |
| 构建 | Gradle | 8.10 | ~/.local/gradle/gradle-8.10/bin/gradle |
| SDK管理 | sdkmanager | 12.0 | $ANDROID_HOME/cmdline-tools/latest/bin/ |
| 平台 | Android SDK | - | /mnt/c/Users/YeZhimin/AppData/Local/Android/Sdk |
| 平台 | android-36.1 | - | $ANDROID_HOME/platforms/android-36.1 |
| 构建工具 | Build-Tools | 36.1.0, 37.0.0 | $ANDROID_HOME/build-tools/ |
| 调试 | adb | 1.0.41 | $ANDROID_HOME/platform-tools/ |

### 提前准备
- [ ] Android Studio（官方IDE，Windows端安装）
- [ ] 真机测试（推荐）或 AVD 模拟器
- [ ] Google Play 开发者账号（发布用，$25 一次性）
- [ ] 了解 Material Design 设计规范

### 推荐学习路径
1. Kotlin 基础语法
2. Android Studio 使用
3. Activity / Fragment 生命周期
4. Jetpack Compose 或 XML UI
5. ViewModel + LiveData/StateFlow
6. 网络请求 + 列表展示
7. Room 本地数据库
8. 发布上架

### WSL 独立构建 Android APK（无需 Android Studio）

**已知坑与解决方案：**

1. **Gradle Wrapper 下载超时**
   - `gradlew` 会尝试从 `services.gradle.org` 下载 Gradle，在中国网络会超时
   - 解决：直接用本地安装的 Gradle：`gradle assembleDebug --no-daemon`

2. **Kotlin 插件版本冲突**
   - 错误：`plugin is already on the classpath with a different version`
   - 解决：root `build.gradle` 和 app `build.gradle` 中的 Kotlin 版本必须完全一致

3. **SDK Platform 版本**
   - 先检查 `$ANDROID_HOME/platforms/` 有哪些版本可用
   - `compileSdk` 和 `targetSdk` 必须使用已安装的版本

4. **Gradle 进程冲突**
   - 多个项目同时构建会导致资源争用
   - 解决：先 `ps aux | grep gradle` 检查并 kill 旧进程

**最小化项目结构（纯命令行）：**
```
project/
├── app/
│   ├── src/main/
│   │   ├── java/com/hello/android/MainActivity.kt
│   │   └── AndroidManifest.xml
│   └── build.gradle
├── build.gradle          # root: apply plugin versions
├── settings.gradle
└── gradle.properties
```

**构建命令：**
```bash
export ANDROID_HOME=/mnt/c/Users/YeZhimin/AppData/Local/Android/Sdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH="$HOME/.local/gradle/gradle-8.10/bin:$PATH"
gradle assembleDebug --no-daemon
```

---

## 4. iOS开发

### 技术栈
| 分类 | 技术 |
|------|------|
| 语言 | Swift（推荐）/ Objective-C |
| IDE | Xcode |
| UI | SwiftUI / UIKit |
| 架构 | MVVM / Coordinator |
| 网络 | URLSession / Alamofire |
| 约束 | SnapKit |

### 提前准备
- [ ] macOS 系统（必需，开发只能在 Mac 上进行）
- [ ] Xcode（App Store 免费下载）
- [ ] iOS SDK（Xcode 自动包含）
- [ ] Apple Developer 账号（$99/年，用于真机测试和发布）
- [ ] 测试设备 iPhone / iPad
- [ ] 了解 Human Interface Guidelines

### 重要限制
- 只能在 macOS 上开发
- 真机测试需要付费开发者账号
- App Store 审核较严格
- 部分 API 需要付费账号才能调用

---

## 5. Windows应用

### 技术栈
| 方案 | 技术 |
|------|------|
| 原生 | C# / .NET (WPF / WinUI 3 / MAUI) |
| Web方案 | Electron (Chromium + Node.js) |
| 轻量级 | Tauri (Rust + Web) |
| 游戏 | C++ / Unity / Unreal |

### 已安装开发工具（WSL环境）
```bash
export PATH=~/.npm-global/bin:$PATH
```
| 工具 | 版本 | 用途 |
|------|------|------|
| electron | 28.0.0 | 桌面应用框架 |
| electron-builder | 26.8.1 | 打包成exe |
| electron-log | 5.4.3 | 日志 |
| electron-store | 11.0.2 | 本地存储 |
| @electron/rebuild | 4.0.3 | native模块重建 |
| nw | 0.110.1 | NW.js桌面框架 |
| nwjs-builder | 1.14.0 | NW应用构建 |

### Windows本机工具
| 工具 | 用途 |
|------|------|
| Cursor | AI代码编辑器（基于VS Code） |
| Docker Desktop | 容器管理（WSL2后端） |

### Electron + Cursor + Docker 开发流程
```
1. Windows启动Cursor和Docker Desktop
2. WSL中创建项目: npm create electron-app
3. WSL中开发调试: npm run dev
4. Windows中打包: electron-builder
5. Docker可用于构建容器化后端服务
```

### 提前准备
- [ ] Windows 10/11（打包必需）
- [ ] Visual Studio 2022（.NET 开发）
- [ ] .NET SDK
- [ ] 如用 Electron：Node.js + Cursor
- [ ] 如用 Tauri：Rust 工具链
- [ ] 代码签名证书（发布用）

### 方案对比
| 方案 | 优势 | 劣势 |
|------|------|------|
| WPF | 成熟、生态好 | 仅 Windows |
| WinUI 3 | 现代 UI | 相对较新 |
| MAUI | 跨平台（Win/Mac/iOS/Android） | 生态待完善 |
| Electron | Web 技术、生态丰富 | 包体积大 |
| Tauri | 轻量、安全 | 社区较小 |

### Docker Desktop集成
- WSL2已启用Docker集成
- 在WSL中可直接使用`docker`命令
- 开发容器化应用时，WSL中构建，Windows中运行

---

## 6. Mac应用

### 技术栈
| 分类 | 技术 |
|------|------|
| 语言 | Swift / Objective-C |
| IDE | Xcode |
| UI | SwiftUI / AppKit |
| 架构 | MVVM |

### 提前准备
- [ ] macOS 系统
- [ ] Xcode
- [ ] Apple Developer 账号（$99/年）
- [ ] Mac 真机（用于测试）
- [ ] 了解 Apple 开发者协议

### 开发注意
- 必须使用 macOS
- App Store 发布需开发者账号
- 部分 macOS 特有 API 需熟悉（MenuBar、TouchBar 等）
- 注意 Apple Silicon (M1/M2/M3) 和 Intel 的兼容

---

## 7. 跨平台方案汇总

### 主流跨平台框架

| 框架 | 语言 | 平台覆盖 | 包体积 | 性能 |
|------|------|----------|--------|------|
| Flutter | Dart | iOS/Android/Web/Desktop | 中 | 高 |
| React Native | JavaScript | iOS/Android | 小 | 中 |
| uni-app | JavaScript | 微信小程序/H5/iOS/Android | 小 | 中 |
| Electron | JavaScript | Win/Mac/Linux | 大 | 中 |
| Tauri | Rust+Web | Win/Mac/Linux | 小 | 高 |
| MAUI | C# | Win/Mac/iOS/Android | 中 | 中 |

### 选择建议
- **快速上线小程序** → uni-app
- **高性能跨平台** → Flutter
- **Web 团队转型** → React Native / Electron
- **轻量桌面应用** → Tauri
- **企业级跨平台** → MAUI（微软生态）

### Flutter 在 WSL 中的安装（重要：中国网络特殊处理）

Flutter 官方 storage.googleapis.com 和 pub.dev 在中国均无法访问。安装时必须配置国内镜像：

```bash
# 1. 安装依赖
sudo apt-get install -y unzip git openjdk-17-jdk

# 2. 用 git 克隆 Linux 版（不要用 Windows 版 tarball，会有 CRLF 问题）
cd ~
git clone https://github.com/flutter/flutter.git -b stable --depth 1

# 3. 配置国内镜像（必须）
#    FLUTTER_STORAGE_BASE_URL: Flutter 引擎 artifact 下载
#    PUB_HOSTED_URL: Dart 包下载
export PUB_HOSTED_URL="https://mirrors.tuna.tsinghua.edu.cn/dart-pub"
export FLUTTER_STORAGE_BASE_URL="https://mirrors.cloud.tencent.com/flutter"
export PATH="$HOME/flutter/bin:$PATH"

# 4. 验证
flutter --version
```

**已知坑：**
- 若 flutter 卡在 "Waiting for another flutter command to release the startup lock..." 且长时间不动，原因不是真正的锁文件竞争，而是 `pub upgrade` 访问 pub.dev 超时。配置好 PUB_HOSTED_URL 后重试。
- 不要混用 Windows 版 Flutter（/mnt/h/flutter）和 Linux 版。Windows 版在 WSL 中会有 CRLF 和 .exe 二进制不兼容问题。
- Android 构建需要 JAVA_HOME：`export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"`

**iOS 打包限制：** 即使在 WSL 中安装了 Flutter，最终打包 .ipa 仍需 macOS。iOS 构建无法在 Linux/WSL 中完成。

---

## 通用开发准备清单

### 开发环境（WSL）
- [x] Git 版本控制 (2.43.0)
- [x] SSH Key 配置
- [x] 包管理器（npm / yarn / pnpm）
- [x] Node.js 运行环境 (18.19.1)
- [x] Python 运行环境 (3.12.3)
- [x] Docker（WSL2 + Docker Desktop）
- [x] Flutter (3.41.6) — 配置国内镜像
- [x] Java OpenJDK 17 (17.0.18)
- [x] Gradle 8.10 — WSL独立开发用
- [x] sdkmanager (12.0) + cmdline-tools
- [x] Android SDK (android-36.1, Build-Tools 36.1.0/37.0.0)
- [x] IDE：Cursor (Windows) / VS Code

### Windows本机环境
- [x] Cursor（AI代码编辑器）
- [x] Docker Desktop（已启用WSL集成）
- [x] Android Studio（与WSL共用SDK）

### React Native 项目验收清单（main 专用）

验收 RN 项目时，逐项检查：

1. **App.tsx 必须检查**：`npx react-native init` 生成的 App.tsx 是默认模板。Dev 必须替换为实际的应用组件。如果 App.tsx 仍包含 `NewAppScreen` 或模板注释，说明 dev 未完成交付。
2. **构建命令**：`cd android && ./gradlew assembleDebug`
3. **Gradle 下载**：WSL 环境中 Gradle 下载可能极慢（~50KB/s），耐心等待或后台运行
4. **功能核对**：对照 PRD 逐项检查实现
5. **TypeScript 检查**：`npx tsc --noEmit`（注意 WSL 中 npx 可能损坏，用 `/usr/bin/npm` 代替）

### 知识储备
- [ ] 数据结构和算法基础
- [ ] 设计模式
- [ ] API 设计规范
- [ ] 安全基础（HTTPS、CORS、认证）
- [ ] 性能优化基础

### 设计能力
- [ ] UI/UX 设计基础
- [ ] 原型设计工具（Figma / Sketch）
- [ ] 响应式设计
- [ ] 了解目标平台的设计规范

### 运营发布
- [ ] 应用市场账号申请
- [ ] 应用截图和描述准备
- [ ] 隐私政策页面
- [ ] 版本管理和更新机制

### 环境变量配置
```bash
# 在 ~/.bashrc 中添加
export PATH=~/.npm-global/bin:$PATH
export PUB_HOSTED_URL="https://mirrors.tuna.tsinghua.edu.cn/dart-pub"
export FLUTTER_STORAGE_BASE_URL="https://mirrors.cloud.tencent.com/flutter"
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"

# Android 开发（WSL + Windows SDK 共用）
export ANDROID_HOME=/mnt/c/Users/YeZhimin/AppData/Local/Android/Sdk
export PATH="$HOME/.local/bin:$HOME/.local/gradle/gradle-8.10/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
```
