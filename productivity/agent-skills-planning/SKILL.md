---
name: agent-skills-planning
description: MattPocock Agent Skills 规划与设计类技能集合 — to-prd/to-issues/grill-me/design-an-interface/request-refactor-plan。用于PRD生成、Issue拆分、设计追问、接口多方案设计、重构计划创建。
category: productivity
---

# Agent Skills - Planning & Design

源自 mattpocock/skills，包含5个规划与设计类技能。

## to-prd

将当前对话上下文转化为 PRD 并提交为 GitHub Issue。不需要访谈，直接综合已有信息。

### 触发场景
- 用户希望从当前对话上下文直接生成 PRD 并提交 GitHub Issue

### 操作步骤
1. 如果尚未探索代码库，先探索以了解当前状态
2. 草拟需要构建或修改的主要模块，寻找可独立测试的深层模块机会
3. 用 PRD 模板编写并提交为 GitHub Issue

### PRD 模板
```
## Problem Statement
用户面临的问题（从用户视角）

## Solution
解决方案（从用户视角）

## User Stories
编号的用户故事列表，格式：
1. As an <actor>, I want <feature>, so that <benefit>

## Implementation Decisions
实现决策列表，包括：
- 将要构建/修改的模块
- 将要修改的模块接口
- 技术澄清
- 架构决策
- Schema 变更
```

---

## to-issues

将计划、规范或 PRD 拆分为可独立领取的 GitHub Issue（使用 tracer-bullet 垂直切片）。

### 触发场景
- 用户想要将计划转换为 Issue
- 创建实施工单
- 将工作拆分为 Issue

### 操作步骤
1. 从对话上下文获取信息，或用 `gh issue view <number>` 获取 GitHub Issue
2. 可选：探索代码库了解当前状态
3. 草拟垂直切片（tracer bullet）
4. 向用户展示切片清单并确认
5. 创建 GitHub Issue

### 垂直切片规则
- 每个切片通过所有集成层端到端（不是水平切片）
- 完成的切片可独立演示或验证
- 优先选择 AFK（无需人工交互）而非 HITL（需要人工交互）
- HITL = Human In The Loop

---

## grill-me

对计划或设计进行连环追问，直到所有决策分支都被穷尽。

### 触发场景
- 用户说"grill me"或要求"追问"
- 想要压力测试计划或设计

### 操作步骤
1. 一次问一个问题
2. 每个问题提供推荐答案
3. 如果问题可以通过探索代码库回答，直接探索
4. 直到所有决策分支都被解决

---

## design-an-interface

基于"Design It Twice"原则，生成多个截然不同的接口设计方案。

### 触发场景
- 用户想要设计 API
- 探索接口选项
- 比较模块形态
- 用户说"design it twice"

### 操作步骤
1. 收集需求
   - 这个模块解决什么问题？
   - 调用者是谁？（其他模块、外部用户、测试）
   - 关键操作是什么？
   - 有何约束？
   - 什么应该隐藏/暴露？
2. 使用并行子 Agent 生成3+个截然不同的设计方案
3. 每个设计展示：
   - 接口签名
   - 使用示例
   - 内部隐藏什么
   - 权衡取舍

---

## request-refactor-plan

通过用户访谈创建详细的重构计划，然后提交为 GitHub Issue。

### 触发场景
- 用户想要计划重构
- 创建重构 RFC
- 将重构拆分为安全增量步骤

### 操作步骤
1. 询问用户详细的问题描述和可能的解决方案想法
2. 探索代码库验证并了解当前状态
3. 询问是否考虑过其他方案
4. 详细追问实施细节
5. 确认精确的范围
6. 检查测试覆盖率，不足时询问测试计划
7. 拆分为微小提交的计划
8. 用重构计划模板创建 GitHub Issue

### 重构计划模板
```
## Problem Statement
开发者面临的问题（从开发者视角）

## Solution
解决方案（从开发者视角）

## Commits
详细的实现计划，拆分为最小的提交。每次提交后代码库应处于可工作状态。

## Decision Document
实现决策列表（不含具体文件路径或代码片段）
```
