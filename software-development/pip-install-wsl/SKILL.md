---
name: pip-install-wsl
description: pip 安装在 WSL Ubuntu 24.04 + Python 3.12 环境的问题解决 — 包括 --break-system-packages、大包下载加速、复杂依赖冲突处理
triggers:
  - pip install 权限拒绝
  - externally-managed-environment
  - pip 下载超时
  - axolotl pip 版本冲突
  - lxml 下载超时
---

# pip 安装在 WSL Python 3.12 的问题解决

## 适用环境

- WSL (Ubuntu 24.04)
- Python 3.12+
- pip 安装被系统包管理器限制

## 常见问题与解决

### 1. pip 命令找不到

```bash
# Ubuntu 24.04 默认没装 pip
sudo apt-get install -y python3-pip
```

### 2. externally-managed-environment (Ubuntu 24.04 PEP 668)

```error
error: externally-managed-environment
```

解决：加 `--break-system-packages` flag

```bash
pip3 install --break-system-packages <package>
```

### 3. 下载超时（大包）

大包（>10MB）从 PyPI 下载经常超时，特别是：
- torch (888MB)
- wandb (27MB)
- bitsandbytes (59MB)
- xformers (110MB)
- lxml (5MB)

解决：使用清华镜像

```bash
pip3 install --break-system-packages -i https://pypi.tuna.tsinghua.edu.cn/simple <package>
```

### 4. 复杂依赖的版本冲突（axolotl 类 ML 工具）

axolotl 依赖的 xformers、torch、transformers 版本互相约束，pip resolver 会无限回溯版本直到超时。

解决：**分开多次安装，让 pip 缓存已下载的 wheel**

```bash
# 第一步：装 axolotl 本身（它会用缓存的 torch 等）
pip3 install --break-system-packages -i https://pypi.tuna.tsinghua.edu.cn/simple axolotl

# 如果 torch 等仍然超时，单独处理
pip3 install --break-system-packages -i https://pypi.tuna.tsinghua.edu.cn/simple torch
```

### 5. npm 全局目录残留导致 ENOTEMPTY

taro 等 npm 包重装时报：

```
npm ERR! ENOTEMPTY: directory not empty
```

解决：删除残留目录

```bash
# 检查残留目录
ls ~/.npm-global/lib/node_modules/@tarojs/

# 彻底删除后重装
rm -rf ~/.npm-global/lib/node_modules/@tarojs
npm i -g gh-pages @tarojs/cli
```

## 大包下载速度参考（清华镜像）

| 包 | 大小 | 速度 |
|----|------|------|
| torch | 888MB | ~1.4 MB/s |
| wandb | 27MB | ~18 MB/s |
| bitsandbytes | 59MB | ~15 MB/s |
| xformers | 110MB | ~10 MB/s |
| lxml | 5.2MB | ~18 MB/s |

## Python 版本兼容性提醒

| 包 | Python 版本要求 | 当前环境 |
|----|----------------|----------|
| vllm | <3.12 | Python 3.12.3 — **不兼容** |
| manim | 需要 Cython<3.1,>=3.0.2 | PyPI 无 Python 3.12 兼容版本 — **暂无法安装** |
| axolotl | 正常 | OK |

> vllm 和 manim 在 Python 3.12 上有问题，如需使用建议用 conda 创建独立环境。

## 快速验证命令

```bash
# 检查 pip 是否可用
python3 -m pip --version

# 检查已安装的包
pip3 show <package>

# 检查 Python 版本
python3 --version
```

## 镜像配置持久化

如需永久使用清华镜像，创建 `~/.pip/pip.conf`：

```ini
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
```
