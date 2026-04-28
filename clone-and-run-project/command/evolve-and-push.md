# 命令：进化技能 → CreateBranch → Push

根据当前项目的实践经验，进化 `project-lifecycle` 技能（SKILL.md），并通过分支管理推送到远程。

## 触发条件

用户在使用技能过程中积累了新的经验、踩坑记录、最佳实践，要求更新技能文件时触发。典型场景：

- "把这次的经验总结到技能里"
- "更新 SKILL.md 加上这个注意事项"
- "进化这个技能，加上 xxx 的支持"

## 执行流程

```
收集当前项目经验
  │
  ├─ 步骤 1：分析当前项目信息
  ├─ 步骤 2：创建分支
  ├─ 步骤 3：进化技能文件
  ├─ 步骤 4：提交并推送
  └─ 步骤 5：输出变更摘要
```

### 步骤 1：分析当前项目信息

收集本次实践中产生的经验数据：

```powershell
# 确认技能仓库位置
Set-Location "C:\Users\14663\.cursor\skills"

# 查看当前分支
git branch

# 查看技能文件当前状态
git status
```

**信息收集清单**：
- 本次项目的**类型**（Python/Node/Rust/Go/混合）
- 遇到的**新问题**及解决方案（错误信息、排查步骤、修复方法）
- 发现的**新模式**（新的项目结构、新的工具链、新的配置方式）
- 现有技能文件中**缺失或不准确**的内容
- 值得记录的**最佳实践**

### 步骤 2：创建分支

在技能仓库中创建专用分支：

```powershell
Set-Location "C:\Users\14663\.cursor\skills"

# 确保在最新状态
git pull origin main 2>$null

# 创建进化分支，命名格式：evolve/<简短描述>
git checkout -b evolve/<topic>
```

**分支命名规范**：
| 场景 | 分支名示例 |
|------|-----------|
| 新增项目类型支持 | `evolve/add-flutter-support` |
| 新增注意事项 | `evolve/add-proxy-troubleshooting` |
| 修正已有内容 | `evolve/fix-rust-build-steps` |
| 合并或重组技能 | `evolve/merge-skills` |
| 新增命令 | `evolve/add-command` |

### 步骤 3：进化技能文件

根据收集的经验，更新 SKILL.md 中对应的章节：

**定位更新位置**：

| 经验类型 | 更新到 SKILL.md 的位置 |
|----------|----------------------|
| 新的项目类型检测规则 | 阶段四：安装依赖 — 检测表格 |
| 新的启动命令 | 阶段六：启动与验证 — 启动命令表格 |
| 新的工具链注意事项 | 阶段四：对应语言的注意事项小节 |
| 网络/代理/DNS 问题 | 注意事项 — 网络问题 |
| Windows 兼容性问题 | 注意事项 — 对应条目 |
| 新的验证方法 | 阶段六：验证运行 |
| 新的 Git 操作技巧 | 阶段七/八/九 |
| 新的命令流程 | command/ 目录下新增文件 |

**更新原则**：
1. **追加而非覆盖** — 新增内容附加到对应章节末尾，不删除已有经验
2. **保持结构一致** — 新增的注意事项遵循现有格式（编号列表、代码块、表格）
3. **包含具体错误信息** — 记录实际遇到的报错文本，方便未来快速匹配
4. **提供解决方案** — 每个问题必须附带解决方法，不记录未解决的问题
5. **标注适用范围** — 说明该经验适用于哪类项目或场景

**示例 — 向注意事项中添加新条目**：
```markdown
- **新发现的问题**：描述问题现象和错误信息。**解决方法**：具体步骤。
  ```powershell
  # 修复命令
  ```
```

### 步骤 4：提交并推送

```powershell
Set-Location "C:\Users\14663\.cursor\skills"

# 查看变更
git diff

# 暂存所有变更
git add -A

# 提交，消息格式：evolve(<scope>): <description>
git commit -m "evolve(<scope>): <简要描述>"

# 推送到远程
git push -u origin HEAD
```

**Commit 消息规范**：
| 格式 | 示例 |
|------|------|
| 新增能力 | `evolve(skill): add Flutter project support` |
| 新增注意事项 | `evolve(skill): add DNS troubleshooting guide` |
| 修正内容 | `evolve(skill): fix Rust build prerequisite steps` |
| 合并技能 | `evolve(skill): merge git-operations into project-lifecycle` |
| 新增命令 | `evolve(command): add discover-and-run command` |

### 步骤 5：输出变更摘要

推送完成后，向用户输出：

1. **变更摘要** — 本次更新了哪些章节、新增了什么内容
2. **分支信息** — 当前分支名、远程跟踪状态
3. **后续建议** — 是否需要合并到 main、是否需要创建 PR

```
✓ 技能进化完成
  分支：evolve/add-dns-troubleshooting
  变更：注意事项 — 新增网络问题排查步骤（4 项）
  远程：已推送到 origin
  下一步：合并到 main 或创建 PR
```

## 注意事项

- **不要在 main 分支直接修改** — 始终创建 evolve/ 分支，便于追踪每次进化的内容
- **提交前 review 变更** — 用 `git diff` 确认改动符合预期，避免误删已有内容
- **保持 SKILL.md 可读性** — 文件已很长（900+ 行），新增内容要精炼，避免冗余
- **命令文件独立性** — 每个 command/ 下的文件应自包含，引用 SKILL.md 的阶段编号但不依赖具体行号
