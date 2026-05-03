---
name: godot-wsl-html5-fallback
description: WSL 网络受限时，Godot 4 HTML5 导出的 Fallback 方案 — 用纯 JS+Canvas 实现可运行游戏，同时保留 Godot 项目骨架
triggers:
  - WSL 网络受限，Godot release 下载超时
  - 需要交付 HTML5 游戏但无法用 Godot 导出
  - 原计划 Godot 4 + GDScript 开发
---

# Godot 4 WSL HTML5 导出受限的 Fallback 方案

## 核心策略
先用纯 JavaScript + HTML5 Canvas 实现一个**完整可运行的 MVP**，同时保留 Godot 4 项目骨架（project.godot + scenes/ + scripts/）。这样：
1. 当下就有可玩的 HTML5 版本交付
2. 网络恢复后可以在有 Godot 4 的环境下导入 project.godot 继续开发

## 实施步骤

### 1. Godot 项目骨架（必须创建）
```
project.godot          # Godot 4 项目配置
scenes/               # 场景目录
  ├── levels/
  ├── player/
  ├── enemies/
  ├── bosses/
  ├── weapons/
  └── ui/
scripts/              # GDScript 脚本
  ├── player/
  ├── enemies/
  ├── weapons/
  ├── level/
  └── manager/
assets/               # 资源目录
```

### 2. HTML5 纯 JS 实现
在 `index.html` 中实现完整游戏逻辑，包含：
- Canvas 渲染循环
- 玩家控制器（移动/翻滚/格挡/弹反/跳跃/蹬墙）
- 武器系统（枪械+近战+技能）
- 敌人 AI + Boss
- 程序化像素美术（用 ColorRect 或 Canvas drawPixel）
- Web Audio API 程序化音效
- HUD / 菜单 / 暂停 / 游戏结束

### 3. GitHub 推送（必须执行）
Dev agent 有时不推送 GitHub，需要手动：
```bash
cd proposals/workspace-dev/proposals/<project>/
git init
git checkout -b main
git add README.md index.html project.godot scenes/ scripts/ assets/
git commit -m "Initial commit"
gh repo create <repo-name> --public --description "中文描述" --source=. --push
```

### 4. 验证
- 浏览器直接打开 `index.html`（file:// 协议）
- 检查 Canvas 是否正常渲染（1280x720）
- 控制台无 Error

## 关键经验
- GitHub 小文件 push 成功（几十KB的代码文件），但下载 Godot release（几百MB）会超时
- 两者网络行为不同：GitHub 通过 git/push 走 HTTPS Git 协议，Godot 下载走 HTTP/FTP 大文件下载
- 先 push GitHub 再尝试下载 Godot，或者直接用 JS fallback

## 状态更新模板
- 提案索引中 Engine 字段改为：`Godot 4 + GDScript / HTML5 Canvas + JS`
- Notes 注明：`WSL网络受限，HTML5版用纯JS实现`
