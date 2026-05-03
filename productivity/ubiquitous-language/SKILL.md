---
name: ubiquitous-language
description: 从当前对话中提取 DDD 风格的通用语言词汇表，标记歧义并提出规范术语。源自 mattpocock/skills/ubiquitous-language。
category: productivity
---

# Ubiquitous Language

从当前对话中提取并形式化领域术语，形成一致的词汇表。

## 操作步骤

1. **扫描对话** - 寻找领域相关的名词、动词和概念
2. **识别问题**：
   - 同一词用于不同概念（歧义）
   - 不同词用于同一概念（同义词）
   - 模糊或重载的术语
3. **提出规范词汇表** - 给出明确术语选择
4. **写入 `UBIQUITOUS_LANGUAGE.md`** - 使用以下格式
5. **在对话中输出摘要**

## 输出格式

写入 `UBIQUITOUS_LANGUAGE.md`：

```md
# Ubiquitous Language

## <领域1>

| 术语 | 定义 | 应避免的别名 |
| --- | --- | --- |
| **Term** | Canonical definition | Alias1, Alias2 |

## <领域2>

| 术语 | 定义 | 应避免的别名 |
| --- | --- | --- |
| **Term** | Canonical definition | Alias1, Alias2 |

## 关系

- 一个 **X** 属于一个 **Y**
- 一个 **X** 产生一个或多个 **Y**

## 示例对话

> **Dev:** "当一个 **X** 发生时，**Y** 是否应该立即创建？"
```

## 触发场景
- 用户想要定义领域术语
- 构建词汇表
- 硬化术语
- 创建通用语言
- 用户提到"domain model"或"DDD"

## 关键原则
- 一个概念只有一个规范名称
- 明确列出应避免的别名
- 记录概念之间的关系
- 用示例对话展示术语使用
