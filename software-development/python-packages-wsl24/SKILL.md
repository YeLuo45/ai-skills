---
name: python-packages-wsl24
description: Install Python packages on WSL Ubuntu 24.04 with Python 3.12 — externally-managed-environment workarounds, mirror selection, and known package-specific issues.
category: software-development
tags: [python, wsl, ubuntu-24.04, pip, installation]
version: 1.0.0
---

# Python Packages on WSL Ubuntu 24.04

WSL Ubuntu 24.04 + Python 3.12 下安装 Python 包的经验总结。

## 核心问题

Ubuntu 24.04 使用 PEP 668 `externally-managed-environment`，直接 `pip install` 会报错：
```
error: externally-managed-environment
```

## 标准安装流程

```bash
# 1. 先装 pip（如果没有）
sudo apt-get install -y python3-pip

# 2. 使用清华镜像（pypi.org 直连常超时）
python3 -m pip install --break-system-packages \
  -i https://pypi.tuna.tsinghua.edu.cn/simple <package>
```

**两个 flag 必须同时使用**：
- `--break-system-packages` — 绕过 PEP 668
- `-i <mirror>` — 清华源速度比官方快且稳定

## 已知问题包

### manim（数学动画）
**问题**：Cython 版本冲突，manim 要求 `Cython<3.1,>=3.0.2`，但最新 Cython 3.1 不可用。

**解法**：
```bash
pip install --break-system-packages -i https://pypi.tuna.tsinghua.edu.cn/simple 'cython<3.1'
pip install --break-system-packages -i https://pypi.tuna.tsinghua.edu.cn/simple --no-deps manim
pip install --break-system-packages -i https://pypi.tuna.tsinghua.edu.cn/simple cloup svgelements watchdog skia-pathops srt
# pycairo 需要系统库 libcairo2-dev，无 root 无法安装
```

**限制**：pycairo 无预编译 wheel，需 `sudo apt-get install libcairo2-dev`，没有 root 时渲染功能不可用。

### vllm（LLM 推理服务）
**问题**：vllm 0.19.0 仅有 Python 3.8 的构建包，Python 3.12 完全不支持。

**状态**：无法在当前环境安装。需要：
- 使用 conda/mamba 创建 Python 3.8 环境
- 或使用其他推理服务（如 llama.cpp）

### 其他无 wheel 包
pycairo 等无预编译 wheel 的包，依赖系统库，无 root 无法安装。

## 安装后验证

```bash
pip show <package>  # 检查是否安装成功
python3 -c "import <package>; print('ok')"  # 验证导入
```

## pip 镜像优先级

1. 清华 tuna — `https://pypi.tuna.tsinghua.edu.cn/simple`（最快）
2. 阿里云 — `https://mirrors.aliyun.com/pypi/simple`
3. 腾讯云 — `https://mirrors.cloud.tencent.com/pypi/simple`
4. 官方 — `https://pypi.org/simple`（最慢，常超时）

## npm 包（补充）

npm 全局包在 WSL 的问题参考 `npm-global-install-wsl` skill。
