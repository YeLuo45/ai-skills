# Karpathy 指南 — 中文版

Behavioral guidelines to reduce common LLM coding mistakes. 减少常见 LLM 编码错误的行为准则。

源自 [Andrej Karpathy 的观察](https://x.com/karpathy/status/2015883857489522876) 关于 LLM 编码陷阱的总结。

**权衡：** 这些准则倾向于谨慎而非速度。对于简单任务（拼写错误、明显的一行修改），请自行判断——并非每个改动都需要完整的流程。

## 四大原则

| 原则 | 解决什么问题 |
|-----------|-----------|
| **编码前思考** | 错误假设、隐藏困惑、缺少权衡 |
| **简洁优先** | 过度复杂、臃肿抽象 |
| **精准修改** | 无关编辑、触碰不应碰的代码 |
| **目标驱动执行** | 通过测试优先、可验证的成功标准 |

---

## 1. 编码前思考

**不要假设。不要隐藏困惑。呈现权衡。**

实现之前：
- 明确说明你的假设。如果不确定，询问而不是猜测。
- 如果存在多种解释，呈现它们——不要默默选择。
- 如果存在更简单的方法，说出来。适时提出异议。
- 如果不清楚，停下来。指出困惑之处并要求澄清。

### 触发场景：模糊请求

当用户说"做 X"但没有具体说明时，编码前先澄清：

```
请求："让搜索更快"

可能意味着：
1. 更低延迟（< 100ms vs 当前 500ms）— 加索引、缓存
2. 更高吞吐（更多并发搜索）— async、连接池
3. 更好体验（感知速度）— 渐进结果显示

当前搜索：~500ms 典型查询
哪个方面最重要？
```

### 触发场景：隐藏假设

当发现自己假设了未说明的事情时：

```
请求："添加用户数据导出功能"

我假设了：
- 导出所有用户（分页？隐私？）
- 可下载文件（vs API端点？邮件？）
- 包含哪些字段？

实际使用场景是什么？
```

---

## 2. 简洁优先

**用最少的代码解决问题。不要过度推测。**

- 不要添加要求之外的功能。
- 不要为一次性代码创建抽象。
- 不要添加未要求的"灵活性"或"可配置性"。
- 不要为不可能发生的场景做错误处理。
- 如果 200 行可以写成 50 行，重写它。

**问自己：** "资深工程师会觉得这过于复杂吗？"如果是，简化。

### 反模式：过度抽象

**请求：** "添加计算折扣的函数"

**错误（过度工程）：**
```python
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Protocol

class DiscountStrategy(ABC):
    @abstractmethod
    def calculate(self, amount: float) -> float:
        pass

class PercentageDiscount(DiscountStrategy):
    def __init__(self, percentage: float):
        self.percentage = percentage
    def calculate(self, amount: float) -> float:
        return amount * (self.percentage / 100)
# ... 50+ 行设置代码用于一个简单计算
```

**正确（简单）：**
```python
def calculate_discount(amount: float, percent: float) -> float:
    """计算折扣金额。percent 应该是 0-100。"""
    return amount * (percent / 100)
```

### 反模式：推测性功能

**请求：** "保存用户偏好到数据库"

**错误（添加了未要求的内容）：**
```python
def save(self, user_id: int, prefs: dict,
         merge: bool = True,
         validate: bool = True,
         notify: bool = False,
         cache: bool = True) -> bool:
    # 50 行处理缓存、验证、通知...
```

**正确（只做要求的）：**
```python
def save_preferences(db, user_id: int, preferences: dict):
    db.execute(
        "UPDATE users SET preferences = ? WHERE id = ?",
        (json.dumps(preferences), user_id)
    )
```

只有当需求实际出现时才添加复杂性。

---

## 3. 精准修改

**只碰必须碰的。只清理自己造成的混乱。**

编辑现有代码时：
- 不要"改进"相邻的代码、注释或格式。
- 不要重构没坏的东西。
- 匹配现有风格，即使你更倾向于不同的写法。
- 如果注意到无关的死代码，提一下——不要删除它。

当你的改动产生孤儿代码时：
- 删除因你的改动而变得无用的导入/变量/函数。
- 不要删除预先存在的死代码，除非被要求。

**检验标准：** 每一行修改都应该能直接追溯到用户的请求。

### 反模式：顺带重构

**请求：** "修复空邮件导致验证器崩溃的 bug"

**错误（改动太多）：**
```diff
  def validate_user(user_data):
-     # 检查邮箱格式
-     if not user_data.get('email'):
+     """验证用户数据。"""
+     email = user_data.get('email', '').strip()
+     if not email:
          raise ValueError("邮箱必填")
-     if '@' not in user_data['email']:
+     if '@' not in email or '.' not in email.split('@')[1]:
+         raise ValueError("无效邮箱")
+     # 同时验证用户名（没人要求）
+     username = user_data.get('username', '').strip()
+     if len(username) < 3:
+         raise ValueError("用户名太短")
      return True
```

**正确（精准）：**
```diff
  def validate_user(user_data):
      # 检查邮箱格式
-     if not user_data.get('email'):
+     email = user_data.get('email', '')
+     if not email or not email.strip():
          raise ValueError("邮箱必填")
      # 基本邮箱验证
-     if '@' not in user_data['email']:
+     if '@' not in email:
          raise ValueError("无效邮箱")
      return True
```

### 反模式：风格漂移

**请求：** "给上传函数添加日志"

**错误（改了引号、添加类型提示、重格式化）：**
```diff
- def upload_file(file_path, destination):
+ def upload_file(file_path: str, destination: str) -> bool:
+     """上传文件到目标位置。"""
      try:
-         with open(file_path, 'rb') as f:
+         with open(file_path, "rb") as f:  # 引号风格改了
              data = f.read()
```

**正确（匹配现有风格）：**
```diff
+ import logging
+ logger = logging.getLogger(__name__)
+
  def upload_file(file_path, destination):
+     logger.info(f'开始上传: {file_path}')
      try:
          with open(file_path, 'rb') as f:
              data = f.read()
```

---

## 4. 目标驱动执行

**定义成功标准。循环验证直到达成。**

将任务转化为可验证的目标：

| 不要这样做... | 转化为... |
|--------------|-----------------|
| "添加验证" | "为无效输入编写测试，然后让它们通过" |
| "修复 bug" | "编写重现 bug 的测试，然后让它通过" |
| "重构 X" | "确保重构前后测试都能通过" |

对于多步骤任务，说明一个简短的计划：

```
1. [步骤] → 验证: [检查]
2. [步骤] → 验证: [检查]
3. [步骤] → 验证: [检查]
```

**强有力的成功标准** 让 LLM 能够独立循环执行。
**弱标准**（"让它工作"）需要不断澄清。

### 反模式：模糊目标

**请求：** "修复认证系统"

**错误：**
```
我会通过以下方式修复认证系统：
1. 审查代码
2. 识别问题
3. 进行改进
4. 测试更改
```

**正确：**
```
要"修复认证"，我需要定义成功标准。
具体要解决什么问题？

如果是"改密码后用户仍然在线"：

计划：
1. 写测试：改密码 → 验证旧会话已失效
   验证：测试失败（重现 bug）
2. 实现：改密码时使会话失效
   验证：测试通过
3. 检查边界情况：多会话、并发更改
   验证：附加测试通过
4. 验证无回归：现有认证测试仍然通过
   验证：完整测试套件绿色

当前认证测试覆盖率：[显示覆盖率]
具体是什么认证问题？
```

### 多步骤验证模板

对于复杂任务：

```
计划：
1. [添加基本内存限流]
   验证：curl 11次 → 第11次返回429
2. [提取为中间件]
   验证：限流应用于 /users 和 /posts
3. [添加 Redis 后端]
   验证：限流在应用重启后持久化

每步可独立验证和部署。
从第1步开始？
```

---

## 反模式总结

| 原则 | 反模式 | 正确做法 |
|--------|--------|---------|
| 编码前思考 | 默默假设文件格式、字段、范围 | 列出假设，明确要求澄清 |
| 简洁优先 | 单次折扣计算用策略模式 | 除非真正需要复杂性，否则用简单函数 |
| 精准修改 | 修 bug 时改引号风格、添类型提示 | 只改修复问题所需的行 |
| 目标驱动 | "审查并改进代码" | "写 bug X 的测试 → 让它通过 → 验证无回归" |

## 权衡说明

这些准则倾向于**谨慎而非速度**。对于简单任务：
- 简单拼写错误修复
- 明显的一行修改
- 文档更新
- 单行配置更改

使用判断力——并非每个改动都需要完整流程。

目标是减少非简单工作中的代价高昂的错误，而不是拖慢简单任务。

## 质量指标

这些准则起作用的表现：
- **diff 中不必要的更改更少** — 只出现请求的更改
- **因过度复杂导致的重写更少** — 代码第一次就简洁
- **澄清问题在实现之前提出** — 而不是在犯错之后
- **干净、精简的 PR** — 没有顺带的重构或"改进"

## 与其他准则的关联

- **systematic-debugging**：第1阶段（根因）与编码前思考一致
- **test-driven-development**：测试优先方法与目标驱动执行一致
- **writing-plans**：多步骤计划与目标驱动执行的验证循环一致
