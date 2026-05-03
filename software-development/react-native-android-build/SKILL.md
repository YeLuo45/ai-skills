---
name: react-native-android-build
description: React Native Android 构建问题排查 — Gradle、NDK、Kotlin 版本冲突、minSdk 适配、New Architecture 关闭等
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [react-native, android, gradle, build, troubleshooting]
    related_skills: [systematic-debugging, app-development-guide]
---

# React Native Android 构建问题排查

## 概述

RN Android 构建涉及多版本依赖协调：React Native 版本、Gradle 版本、AGP 版本、Kotlin 版本、NDK 版本、minSdk 版本。任意不匹配都会导致构建失败。

**核心原则：先查版本兼容性，再定位具体冲突，最后小步验证。**

---

## 环境前置检查

**构建前必须确认以下环境版本：**

| 检查项 | 命令 | 最低要求 |
|--------|------|----------|
| Node.js | `node --version` | **>= 20**（RN 0.76+ 要求，0.73/0.74 可用 18） |
| npm | `npm --version` | >= 9 |
| Java | `java -version` | 17+ (推荐 Temurin/Adoptium) |
| Gradle | `./gradlew --version` | 8.x |
| Android SDK | echo $ANDROID_HOME | 已配置 |

**已知不兼容组合：**
- Node 18.19.1 + npm 9.2.0 + React Native 0.76.9 → Gradle 构建超时（600s+），进程挂起
- 原因：RN 0.76.9 明确要求 Node >= 20，Node 18 会导致某些 native 模块编译挂起

---

## 常见冲突模式

### 1. hermestooling / hermes-instrumentation minSdk 冲突

**症状：** `com.facebook.react.settings:hermestooling:... minSdk 26` 但项目 `minSdk 24`

**原因：** RN 0.85+ 引入了 hermestooling prefab，其 minSdk 要求为 26，高于部分老项目的 minSdk 24/22

**解法：**
- 方案A：降级 React Native（如 0.76.9）
- 方案B：提高项目 minSdk 至 26
- 方案C：检查是否可通过移除 hermestooling 依赖（不推荐，会影响调试功能）

### 2. Gradle 与 AGP 版本不兼容

**症状：** `Gradle 9.x + AGP 8.x` 组合构建失败

**原因：** AGP 8.x 不支持 Gradle 9.x；AGP 9.x 才支持 Gradle 9.x

**RN 版本与 Gradle/AGP 兼容矩阵（已知）：**
| React Native | Gradle | AGP | Kotlin |
|---|---|---|---|
| 0.85 | 9.3.1 | 9.x | 2.x |
| 0.76.9 | 8.11.1 | 8.x | 2.x |

**解法：** 降级 Gradle 至 8.11.1 或降级 RN 版本

### 3. Kotlin 版本冲突（RN gradle plugin 内置问题）

**症状：**
```
org.gradle.api.plugins.InvalidPluginException: Plugin [id: 'org.jetbrains.kotlin.android', version: '2.1.20'] was not found
# 或
org.gradle.api.plugins.InvalidPluginVersionException: Plugin version 2.1.20 is invalid
```

**原因：** React Native 的 `com.android.application` gradle plugin 内部捆绑了 Kotlin 1.9.x 编译器，Gradle 8.x 也捆绑 Kotlin 1.9.0。直接指定 `kotlinVersion = "2.1.20"` 或在 `settings.gradle` 添加 `kotlin("jvm")` 2.x 版本会失败。

**解法（组合使用）：**

```groovy
// android/build.gradle
buildscript {
    ext {
        kotlinVersion = "1.9.24"  // 使用 RN gradle plugin 兼容的版本
    }
}

subprojects {
    afterEvaluate { project ->
        project.configurations.all {
            resolutionStrategy {
                // 强制解决 kotlin-stdlib 版本冲突（来自第三方库如 react-native-safe-area-context）
                force 'org.jetbrains.kotlin:kotlin-stdlib:1.9.24'
                force 'org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.9.24'
                force 'org.jetbrains.kotlin:kotlin-stdlib-jdk8:1.9.24'
            }
        }
    }
}
```

同时在 `android/gradle.properties` 添加：
```
kotlin.jvm.target.validation.mode=warning
```

**重要：** 不要在 `buildscript.ext` 之外单独指定 `kotlinVersion = "2.1.20"`，这会与 RN gradle plugin 冲突。强制版本统一用 `resolutionStrategy.force`。

```groovy
// android/settings.gradle
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
    }
    // ⚠️ 注意：Gradle 8.11 不支持在 dependencyResolutionManagement 里放 resolutionStrategy
    // 会报错 "Resolution strategy must be set before repositories are defined"
    // 正确做法：移到根 build.gradle 的 subprojects 块
}
```

**Gradle 8.11 正确做法** — 在 `android/build.gradle` 根项目添加：

```groovy
subprojects {
    afterEvaluate { project ->
        project.configurations.all {
            resolutionStrategy {
                force 'org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.20'
                force 'org.jetbrains.kotlin:kotlin-stdlib:2.1.20'
            }
        }
    }
}
```

同时在 `android/build.gradle` 明确指定 `kotlinVersion = "2.1.20"`

### 4. react-native-reanimated / react-native-worklets 冲突

**症状：**
- `react-native-reanimated 3.x` 与 RN New Architecture (Fabric/TurboModules) 不兼容
- `react-native-worklets` minSdk 30，与项目 minSdk 24 冲突
- reanimated v4 同样有 minSdk 30 要求

**解法：**
- 方案A：关闭 New Architecture（`newArchEnabled=false` in `gradle.properties`）
- 方案B：移除 reanimated 和 worklets，使用其他动画方案
- 方案C：升级 RN 版本以获得兼容的 reanimated 版本

### 5. NDK 安装不完整或损坏

NDK 损坏有多种程度，需逐级排查：

**排查步骤：**

```bash
# 1. 检查 NDK 目录是否存在
ls -la /mnt/c/Users/YeZhimin/AppData/Local/Android/Sdk/ndk/

# 2. 对每个版本检查关键文件/目录
ls -la /mnt/c/Users/YeZhimin/AppData/Local/Android/Sdk/ndk/27.1.12297006/
# 3. 检查 toolchains 目录（编译 native 代码必须）
ls -la /mnt/c/Users/YeZhimin/AppData/Local/Android/Sdk/ndk/27.1.12297006/toolchains/
# 4. 检查 platforms 目录（NDK API 级别必须）
ls -la /mnt/c/Users/YeZhimin/AppData/Local/Android/Sdk/ndk/27.1.12297006/platforms/
```

**损坏程度分级：**

| 程度 | 症状 | 可用性 |
|------|------|--------|
| 1 | NDK 目录完全不存在 | 不可用 |
| 2 | 目录存在但完全为空（无任何文件） | 不可用 |
| 3 | 只有 `source.properties`，无 toolchains/platforms | 不可用 |
| 4 | 有 source.properties + 部分 toolchains，但文件残缺 | 编译可能失败 |
| 5 | source.properties + toolchains + platforms 完整 | 可用 |

**已知损坏情况（Windows SDK，WSL 访问）：**
- `26.1.10909125` — 程度2：目录完全为空
- `27.1.12297006` — 程度3：仅有 `source.properties`（7字节），无 toolchains/platforms

**重要：仅检查 source.properties 存在是不够的！** 即使有 source.properties，如果 toolchains 目录不存在，native 模块编译仍会失败。Gradle 可能通过配置阶段但在实际编译时卡住或报错。

**解法：**

1. **用 sdkmanager 重新安装 NDK（推荐）：**
```bash
/mnt/c/Users/YeZhimin/AppData/Local/Android/Sdk/cmdline-tools/latest/bin/sdkmanager "ndk;27.1.12297006"
```

2. **如果无法重新安装 — 绕过 native 模块编译：**
   - 移除所有包含 native 代码的依赖（如 `react-native-vector-icons`）
   - 用 `npm uninstall <package>` 而非 `rm -rf node_modules`
   - 运行 `npx expo prebuild --platform android --clean` 重新生成 android 目录（清除旧的 autolinking 缓存）
   - 构建时 gradle 会跳过 native 编译任务

3. **临时指定 NDK 版本（在 `android/build.gradle`）：**
```groovy
ndkVersion = "27.1.12297006"  // 或任何在 SDK 中存在的版本
```
同时配置 `android/local.properties`：
```properties
sdk.dir=/mnt/c/Users/YeZhimin/AppData/Local/Android/Sdk
```

**注意：** `local.properties` 必须存在且指向正确的 SDK 路径。Expo prebuild 不会自动创建此文件。

### 5b. WSL Maven Central / Google 下载极慢

**症状：** Gradle 构建时依赖下载极慢（~10KB/s），`Remote host terminated the handshake`，`Could not HEAD 'https://repo.maven.apache.org/...'` 等网络错误

**原因：** WSL 到 Maven Central 和 Google 的网络连接质量差

**解法：** 在 `android/build.gradle` 和 `android/settings.gradle` 中配置阿里云镜像（按优先级排序）：

```groovy
// android/build.gradle - buildscript 和 allprojects 两个 repositories 块都要加
buildscript {
    repositories {
        maven { url 'https://maven.aliyun.com/repository/google' }
        maven { url 'https://maven.aliyun.com/repository/central' }
        maven { url 'https://maven.aliyun.com/repository/public' }
        google()
        mavenCentral()
    }
}

allprojects {
    repositories {
        maven { url 'https://maven.aliyun.com/repository/google' }
        maven { url 'https://maven.aliyun.com/repository/central' }
        maven { url 'https://maven.aliyun.com/repository/public' }
        google()
        mavenCentral()
        maven { url 'https://www.jitpack.io' }
    }
}
```

```groovy
// android/settings.gradle - pluginManagement 和 dependencyResolutionManagement 两个块
pluginManagement {
    repositories {
        maven { url 'https://maven.aliyun.com/repository/central' }
        maven { url 'https://maven.aliyun.com/repository/public' }
        maven { url 'https://maven.aliyun.com/repository/gradle-plugin' }
        maven { url 'https://repo.maven.apache.org/maven2' }
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositories {
        maven { url 'https://maven.aliyun.com/repository/central' }
        maven { url 'https://maven.aliyun.com/repository/public' }
        maven { url 'https://maven.aliyun.com/repository/google' }
        google()
        mavenCentral()
        maven { url 'https://www.jitpack.io' }
    }
}
```

**注意：** 配置完后建议停掉旧 Gradle daemon 避免缓存问题：
```bash
cd android && ./gradlew --stop
```

### 6. New Architecture 编译复杂性

**症状：** 构建时间极长，或 CMake/Prefab 相关任务失败

**解法：** 在 `gradle.properties` 中禁用：
```
newArchEnabled=false
```

---

## 构建命令参考

```bash
# 完整清理构建
cd android
./gradlew clean

# 构建 Debug APK（禁用 lint 加速）
./gradlew assembleDebug --no-daemon --console=plain -x lint

# 查看详细日志
./gradlew assembleDebug --no-daemon --console=plain --stacktrace
```

**推荐启动方式（后台运行）：**
```bash
cd /path/to/CalculatorApp/android
nohup ./gradlew assembleDebug --no-daemon --console=plain -x lint > /tmp/gradle-build.log 2>&1 &
echo $!
```

---

## 已知兼容版本组合

### 组合 A（推荐）
- React Native: 0.76.9
- Gradle: 8.11.1
- AGP: 8.x
- Kotlin: 2.1.20
- minSdk: 24
- newArchEnabled: false
- 无 reanimated/worklets

### 组合 B（最新生态）
- React Native: 0.85.x
- Gradle: 9.3.1
- AGP: 9.x
- Kotlin: 2.x
- minSdk: 26+
- newArchEnabled: true
- 需要兼容版本的 reanimated

---

### 构建超时 / APK 未生成

**症状：** `./gradlew assembleDebug` 运行超过 600s 但未完成，log 最后显示进程挂起或 `6 parallel processes` 仍活跃，outputs/apk/debug/ 下无 APK

**排查顺序：**
1. `node --version` → 如果是 18.x 而项目是 RN 0.76+，Node 版本是根源
2. `npm --version` → npm 9.2.0 在 Node 18 下可能有 npm install 阶段的兼容性问题
3. Gradle daemon 状态：`./gradlew --stop` 后重试
4. Kotlin 版本冲突：检查是否同时存在 kotlin-stdlib 1.9.x 和 2.x

**解决：** Node 版本不兼容问题必须先解决，否则 Gradle 编译 native 代码时会挂起

---

## 排查流程

1. **立刻检查 Node 版本** — `node --version`，这是最容易忽略但最常见的构建挂起原因
2. 读错误信息 — 找具体冲突的包名和版本要求
3. 检查 package.json — RN 版本和所有依赖版本
4. 检查 android/build.gradle — compileSdk, targetSdk, minSdk, kotlinVersion, ndkVersion, buildToolsVersion
5. 检查 gradle.properties — newArchEnabled 设置
6. 检查 gradle-wrapper.properties — Gradle 版本
7. 检查 settings.gradle — 是否有 resolutionStrategy
8. 检查 NDK — 目录存在且有 source.properties
9. 小步验证 — 每次只改一个变量，然后重试

---

## 关键文件位置

```
android/
├── build.gradle              # 项目级 gradle 配置
├── settings.gradle           # 依赖解析策略
├── gradle.properties         # New Architecture 开关
├── gradle/wrapper/
│   └── gradle-wrapper.properties  # Gradle 版本
├── app/
│   └── build.gradle          # App 级 gradle 配置
└── local.properties          # SDK/NDK 路径（需手动创建或 prebuild 生成）
```

## calculator-app 项目路径（示例）

**正确路径：**
```
/home/hermes/.hermes/proposals/workspace-dev/proposals/calculator-app/
```

**常见错误路径（注意 .hermes 层级）：**
```
/home/hermes/workspace-dev/proposals/calculator-app/  # 缺少 .hermes
```

---

## NDK 安装位置（我的环境）

```
/mnt/c/Users/YeZhimin/AppData/Local/Android/Sdk/ndk/
```

常用版本：27.1.12297006, 26.1.10909125

---

## Expo 项目 prebuild 需要的图标文件

**问题：** `npx expo prebuild --platform android` 报错 `ENOENT: no such file or directory, open './assets/adaptive-icon.png'`

**原因：** Expo prebuild 需要以下资产文件存在：
- `assets/adaptive-icon.png` — Android 自适应图标前景
- `assets/icon.png` — 应用图标
- `assets/splash.png` — 启动画面
- `assets/favicon.png` — Web favicon

**解法：** prebuild 前创建这些文件（最小 PNG 即可）：
```bash
mkdir -p assets
# 创建 1x1 绿色像素 PNG（base64）
echo -n 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==' | base64 -d > assets/icon.png
cp assets/icon.png assets/adaptive-icon.png
cp assets/icon.png assets/splash.png
cp assets/icon.png assets/favicon.png
```

---

## WSL Gradle 下载极慢问题

**症状：** Gradle wrapper 首次下载时速度极慢（~1MB/分钟），`gradle-8.10.2-all.zip` (~400MB) 需要数小时

**原因：** WSL 到 Windows 文件系统网络路径的 I/O 性能问题

**解法：**
1. 优先使用 `gradle-*-bin.zip` 而非 `gradle-*-all.zip`（bin ~150MB vs all ~400MB）
2. 增大 `networkTimeout`：
```properties
# android/gradle/wrapper/gradle-wrapper.properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.10.2-bin.zip
networkTimeout=60000
```

**验证缓存是否完整：**
```bash
ls -la ~/.gradle/wrapper/dists/gradle-8.10.2-bin/<hash>/
# 完整文件应该是 .zip 而不是 .zip.part
# .part 文件表示下载未完成
```

**推荐后台运行构建：**
```bash
cd android
./gradlew assembleDebug --no-daemon 2>&1 &
# 用 watch 监控进度
watch -n 30 'ls -la ~/.gradle/wrapper/dists/gradle-8.10.2-bin/<hash>/'
```
