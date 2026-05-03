---
name: game-studio
description: Claude Code Game Studios — 48个协调子Agent的游戏工作室架构，用于独立游戏开发项目管理、技术决策和跨领域协调
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [Game Development, Multi-Agent, Godot, Unity, Unreal, Indie Game]
    related_skills: [autonomous-ai-agents]
---

# Claude Code Game Studios Skill

独立游戏开发多Agent协调架构。48个专业子Agent，每个负责特定领域。

## 何时使用

当boss提出游戏开发相关需求时加载此技能：
- 新游戏项目立项（需要设计、程序、美术等多角色协调）
- 游戏机制设计（GDD编写、规则定义）
- 引擎选型（Godot / Unity / Unreal）
- 技术架构设计（多人游戏、网络同步、复制系统）
- 性能优化（GPU/CPU分析、内存管理）
- 音频/音效设计
- UI/UX设计
- 运维/发布流程

## 技术栈

- Engine: Godot 4 / Unity / Unreal Engine 5（待选）
- Language: GDScript / C# / C++ / Blueprint（随引擎）
- Version Control: Git trunk-based development
- Build System: 待引擎选定后配置

## 48个专业Agent

| Agent | 职责 |
|-------|------|
| technical-director | 技术方向、架构决策 |
| creative-director | 游戏创意、方向把控 |
| producer | 项目管理、进度协调 |
| lead-programmer | 程序团队领导、技术复核 |
| gameplay-programmer | 游戏玩法逻辑 |
| network-programmer | 网络编程、多人游戏 |
| engine-programmer | 引擎底层、性能 |
| tools-programmer | 开发工具、编辑器扩展 |
| ui-programmer | UI实现 |
| ai-programmer | AI行为、导航 |
| godot-specialist | Godot引擎专家 |
| godot-gdscript-specialist | GDScript专家 |
| godot-gdextension-specialist | GDExtension/C++专家 |
| godot-csharp-specialist | Godot C#专家 |
| godot-shader-specialist | Godot着色器专家 |
| unity-specialist | Unity引擎专家 |
| unity-dots-specialist | Unity DOTS架构 |
| unity-ui-specialist | Unity UI系统 |
| unity-addressables-specialist | Unity Addressables资源系统 |
| unity-shader-specialist | Unity着色器专家 |
| unreal-specialist | Unreal引擎专家 |
| ue-blueprint-specialist | UE Blueprint可视化编程 |
| ue-gas-specialist | UE Gameplay Ability System |
| ue-replication-specialist | UE网络复制 |
| ue-umg-specialist | UE UMG UI系统 |
| technical-artist | 技术美术、资产管线 |
| art-director | 美术方向、艺术指导 |
| sound-designer | 音效设计 |
| audio-director | 音频总监 |
| game-designer | 游戏设计师 |
| systems-designer | 系统设计师 |
| level-designer | 关卡设计师 |
| world-builder | 世界构建 |
| narrative-director | 叙事总监 |
| writer | 编剧 |
| economy-designer | 经济系统设计 |
| ux-designer | UX体验设计 |
| accessibility-specialist | 无障碍设计 |
| localization-lead | 本地化负责人 |
| qa-lead | QA团队领导 |
| qa-tester | 测试工程师 |
| performance-analyst | 性能分析 |
| security-engineer | 安全工程师 |
| devops-engineer | 运维工程师 |
| release-manager | 发布经理 |
| analytics-engineer | 数据分析 |
| community-manager | 社区经理 |
| prototyper | 原型开发 |
| live-ops-designer | 运营内容设计 |

## 目录结构说明

项目包含以下顶级目录：
- 主配置文件（CLAUDE.md）
- .claude — Agent定义、技能、钩子、规则
- src — 游戏源码（core, gameplay, ai, networking, ui, tools）
- assets — 游戏资源（美术、音频、特效、着色器、数据）
- design — 游戏设计文档（gdd, narrative, levels, balance）
- docs — 技术文档，含engine-reference子目录锁定引擎API版本
- tests — 测试套件（单元、集成、性能、试玩）
- tools — 构建和管线工具（CI、构建、资源管线）
- prototypes — 临时原型（与src隔离）
- production — 制作管理（sprints, milestones, releases）

## 协作协议

用户驱动协作，而非自主执行。每个任务遵循：
Question -> Options -> Decision -> Draft -> Approval

- Agent使用Write/Edit工具前必须问"May I write this to [filepath]?"
- Agent必须展示草稿或摘要后再请求批准
- 多文件变更需要明确批准整个变更集
- 未经用户指示不得commit

## 模型分级

| Tier | Model | 用途 |
|------|-------|------|
| Haiku | claude-haiku | 只读状态检查、格式化、简单查询 |
| Sonnet | claude-sonnet | 实现、设计编写、单系统分析（默认） |
| Opus | claude-opus | 多文档综合、高风险阶段门裁决、跨系统整体审查 |

## 关键文档

- coordination-rules.md — Agent协调规则
- directory-structure.md — 目录结构说明
- technical-preferences.md — 技术偏好
- coding-standards.md — 编码标准
- context-management.md — 上下文管理
- COLLABORATIVE-DESIGN-PRINCIPLE.md — 协作设计原则
- design/gdd/systems-index.md — GDD系统索引

## WSL网络受限环境注意事项

**Godot Web导出的关键限制（已知坑点）**

- Godot编辑器二进制 ≠ 可导出Web。Web导出必须同时有export templates（约200MB，需访问GitHub releases下载）
- WSL网络受限场景：编辑器可绕过安装（Windows下载到C:\temp\，WSL访问/mnt/c/temp/），但export templates完全无法下载，导致HTML5导出失败
- 经验证：即使网络能访问HTTPS，GitHub releases大文件下载仍可能失败（SSL error 35）

**替代方案：纯HTML5 Canvas + Vanilla JS**

- 无安装依赖，无构建步骤，浏览器直接运行
- 适合原型验证和简单2D游戏（卡牌、平台跳跃、休闲类）
- 约200-300行JS可实现核心游戏循环
- 缺点：无可视化编辑器，复杂项目效率低于Godot/Unity

## 引擎版本参考

文档中的引擎API快照版本锁定。在使用任何引擎API前先查阅对应版本文件。

## 仓库地址

https://github.com/YeLuo45/Claude-Code-Game-Studios.git

本地克隆路径：~/.hermes/skills/game-studio/references/Claude-Code-Game-Studios/

## 使用流程

1. 加载技能：skill_view(name='game-studio')
2. 确认引擎选择（Godot / Unity / Unreal）
3. **如果是 Godot + HTML5/Web 目标，立刻加载 `skill_view(name='godot-wsl-html5-fallback')` 检查WSL网络状态**
4. 参考对应引擎specialist agent
5. 按协作协议推进：Question -> Options -> Decision -> Draft -> Approval
