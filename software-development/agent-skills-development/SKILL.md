---
name: agent-skills-development
description: MattPocock Agent Skills 开发类技能集合 — tdd/triage-issue/improve-codebase-architecture/migrate-to-shoehorn/scaffold-exercises。用于TDD开发、问题调查、架构改进、类型迁移、练习搭建。
category: software-development
---

# Agent Skills - Development

源自 mattpocock/skills，包含5个开发类技能。

## tdd

测试驱动开发，遵循红-绿-重构循环。

### 触发场景
- 用户想要用 TDD 构建功能或修复 bug
- 用户提到"red-green-refactor"
- 用户要求集成测试或测试先行开发

### 核心原则
- 测试通过公共接口验证行为，不验证实现细节
- 好的测试是集成风格的：通过公共 API 真实执行代码路径
- 坏的测试耦合到实现：mock 内部协作器、测试私有方法

### 反模式：水平切片
不要先写所有测试，再写所有实现。这是水平切片，会产生糟糕的测试。

正确方式：垂直切片（tracer bullets）
```
错误（水平）:
  RED:   test1, test2, test3, test4, test5
  GREEN: impl1, impl2, impl3, impl4, impl5

正确（垂直）:
  RED→GREEN: test1→impl1
  RED→GREEN: test2→impl2
  RED→GREEN: test3→impl3
```

### 工作流程
1. 确认需要的接口变更
2. 确认要测试的行为（优先级排序）
3. 循环：RED（写一个测试）→ GREEN（写最小实现）→ 重构

---

## triage-issue

调查 bug，定位根因，创建带 TDD 修复计划的 GitHub Issue。

### 触发场景
- 用户报告 bug
- 想要提交 Issue
- 想要调查并计划修复

### 操作步骤
1. 获取问题描述（只问一个问题："你看到了什么问题？"）
2. 探索代码库诊断
   - bug 出现在哪里（入口点、UI、API 响应）
   - 涉及什么代码路径
   - 失败的根因（不只是症状）
   - 相关代码（类似模式、测试、相邻模块）
3. 确定修复方案
4. 设计 TDD 修复计划（有序的 RED-GREEN 循环列表）

---

## improve-codebase-architecture

在 `CONTEXT.md` 领域语言和 `docs/adr/` 决策记录指导下寻找架构改进机会。

### 触发场景
- 用户想要改进架构
- 寻找重构机会
- 合并紧耦合模块
- 提高代码可测试性和 AI 可导航性

### 术语表
- **Module** — 有接口和实现的一切（函数、类、包、切片）
- **Interface** — 调用者必须知道的一切：类型、不变量、错误模式、顺序、配置
- **Implementation** — 模块内部代码
- **Depth** — 接口杠杆：大量行为隐藏在少量接口后
- **Seam** — 接口所在位置；可以在不修改原地的情况下改变行为
- **Adapter** — 在 Seam 处满足接口的具体事物
- **Leverage** — 调用者从 Depth 获得的东西
- **Locality** — 维护者从 Depth 获得的东西

### 关键原则
- **Deletion test**: 删除模块，复杂度消失 = pass-through；复杂度分散到 N 个调用者 = 物有所值
- **Interface is the test surface**
- **One adapter = hypothetical seam. Two adapters = real seam**

### 工作流程
1. 读取 `CONTEXT.md` 和 `docs/adr/`
2. 探索代码库，寻找摩擦点：
   - 理解一个概念需要在多个小模块间跳转？
   - 模块是浅层的？（接口和实现同样复杂）
   - 提取的纯函数只是为了可测试性，但真正 bug 在调用方式？
   - 紧耦合模块跨 Seam 泄漏？
   - 哪些部分未测试或难以通过当前接口测试？
3. 应用 deletion test
4. 提出深化机会

---

## migrate-to-shoehorn

将测试文件从 `as` 类型断言迁移到 @total-typescript/shoehorn。

### 触发场景
- 用户提到 shoehorn
- 想要替换测试中的 `as`
- 需要部分测试数据

### 为什么用 shoehorn？
- `as` 迫使手动指定目标类型
- `as unknown as Type` 用于故意错误的数据时很丑陋
- shoehorn 允许传递部分数据同时保持 TypeScript 类型安全

### 安装
```bash
npm i @total-typescript/shoehorn
```

### 迁移模式

#### 大对象只有少数属性需要
```ts
// Before
it("gets user by id", () => {
  getUser({
    body: { id: "123" },
    headers: {},  // 必须伪造所有20个属性
    cookies: {},
    // ...
  });
});

// After - 用 shoehorn
it("gets user by id", () => {
  getUser(shoehorn(req, Partial<Request>));
});
```

---

## scaffold-exercises

创建包含章节、问题、解决方案和解释器的练习目录结构。

### 触发场景
- 用户想要搭建练习
- 创建练习存根
- 设置新课程章节

### 目录命名
- **Section**: `exercises/XX-section-name/`（如 `01-retrieval-skill-building`）
- **Exercise**: `XX.YY-exercise-name/`（如 `01.03-retrieval-with-bm25`）
- 用 dash-case（小写、连字符）

### 练习变体
每个练习至少需要一种：
- `problem/` - 学生工作区，有 TODOs
- `solution/` - 参考实现
- `explainer/` - 概念材料，无 TODOs

### 必需文件
每个子文件夹需要 `readme.md`，不能为空。

### 工作流程
1. 解析计划 - 提取章节名、练习名、变体类型
2. 创建目录 - `mkdir -p` 每个路径
3. 创建存根 readme
4. 运行 lint 验证
5. 修复错误直到 lint 通过
