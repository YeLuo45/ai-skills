---
name: android-dev-env
description: Android 开发环境配置 (WSL Ubuntu + Windows SDK)
---

# Android 开发环境

## 环境配置

| 组件 | 路径/版本 |
|------|-----------|
| Android SDK | `/mnt/c/Users/YeZhimin/AppData/Local/Android/Sdk` |
| Gradle | 8.10 (wrapper 方式，无需全局安装) |
| sdkmanager | `$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager` |
| Java | `/usr/lib/jvm/java-17-openjdk-amd64` (OpenJDK 17) |
| Build-Tools | 36.1.0, 37.0.0 |
| Platforms | android-36 |

## .bashrc / .profile 配置

推荐将环境变量放在 `~/.profile`（WSL login shell 会加载），而非 `.bashrc`：

```bash
# ~/.profile
export ANDROID_HOME=/mnt/c/Users/YeZhimin/AppData/Local/Android/Sdk
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export PATH="$HOME/.local/gradle/gradle-8.10/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
```

## 项目结构 (Kotlin + Gradle)

```
myapp/
├── app/
│   ├── src/main/
│   │   ├── java/com/example/app/MainActivity.kt   # Kotlin 代码
│   │   ├── AndroidManifest.xml
│   │   └── res/
│   └── build.gradle.kts
├── gradle/wrapper/gradle-wrapper.properties
├── build.gradle.kts    # root
├── settings.gradle.kts
└── gradlew             # 包装器脚本
```

### build.gradle.kts (app)

```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") version "1.9.22"
}

android {
    namespace = "com.example.app"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.app"
        minSdk = 24
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.22")
}
```

### settings.gradle.kts (root)

```kotlin
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "MyApp"
include(":app")
```

## 构建命令

```bash
./gradlew assembleDebug        # Debug APK
./gradlew assembleRelease      # Release APK (需签名)
./gradlew clean                # 清理构建缓存

# APK 输出位置
# app/build/outputs/apk/debug/app-debug.apk
# app/build/outputs/apk/release/app-release.apk
```

## Gradle Wrapper 初始化

```bash
cd ~/projects/myapp
gradle wrapper --gradle-version 8.10   # 生成 gradlew 和 wrapper
./gradlew --version                     # 验证
```

## 已知问题

### WSL .bashrc early return
WSL Ubuntu 中，login shell (`bash -l`) 时 `$-` 不含 `i`，导致 `.bashrc` 在 early return 后面的 export 全部跳过。**解决方案**：把持久化环境变量（ANDROID_HOME、JAVA_HOME、PATH）放到 `~/.profile`。

### 路径注意
- WSL 中 Windows 路径挂载在 `/mnt/c/...`
- Gradle 缓存默认在 `~/.gradle`

### 构建超时
Gradle 首次下载依赖较慢，建议耐心等待或配置镜像加速。