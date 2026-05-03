---
name: godot-web-gl-compatibility
description: Godot 4 WebGL GL_INVALID_ENUM troubleshooting and Godot 3.x migration guide
tags: [godot, webgl, html5, godot-4, godot-3, github-actions]
---

# Godot Web GL_INVALID_ENUM 故障排除与版本迁移

## 症状
- Godot 4.x HTML5 web 导出后浏览器报 `GL_INVALID_ENUM: Invalid cap`
- 游戏无法启动，停在 loading 或黑屏
- `SharedArrayBuffer` 可能显示为可用（COOP/COEP 生效），但 WebGL context 创建失败
- `still waiting on run dependencies: wasm-instantiate` 反复出现

## 已知原因
Godot 4.2.x / 4.3 / 4.4.1 的 web 导出在某些浏览器环境下请求了不支持的 WebGL extension/capability，具体与 `renderer/rendering_method="forward_plus"` 相关。

## 解决路径（按优先级）

### 路径 A：渲染器降级（推荐方案，适用于 Godot 4 项目）
在 Godot Editor 中：
```
Editor → Project Settings → Rendering → Renderer
将 "Forward Plus" 改为 "Compatibility"
重新导出 Web 版本
```
如果无法操作 Editor，可手动修改 `project.godot`（需同时加 .web 变体）：
```
[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.web="gl_compatibility"
```

**重要**：场景文件 (.tscn) 如使用 Godot 4 格式（`format=3`），在 Godot Editor 中重新保存会覆盖 `project.godot` 中的渲染器设置。如遇此情况，需同时确保 `project.godot` 中的渲染器设置正确且被 version control 追踪，CI 构建不会因本地覆盖而失效。

**实测有效**：Compatibility 渲染器可以消除 `GL_INVALID_ENUM` 错误。

### 路径 B：迁移到 Godot 3.6 LTS（仅当路径 A 无效时尝试）
Godot 3.x 的 web 导出经过 5 年打磨，稳定性远好于 4.x。

**警告**：此路径成本极高——如果项目场景文件已使用 Godot 4 格式（`format=3`，含 `layout_mode`、`anchors_preset`、`uid://` 引用），在 Godot 3 Editor 中打开会报 "资源和格式不匹配" 错误。必须从头重建场景，无法通过手动修改 .tscn 文本降级。

**步骤（如场景文件仍是 Godot 3 格式）：**
1. 修改 workflow 下载 Godot 3.6.2 stable
2. 修改 `project.godot`：`config_version=5` → `config_version=2`，删除 Godot 4 features
3. 修改 `export_presets.cfg` 为 Godot 3.x 格式
4. 迁移所有 GDScript（见下方对照表）
5. 推送触发 CI 重新导出

**Godot 3.6.2 二进制命名（重要）：**
- Linux 普通版（含 display）：`Godot_v3.6.2-stable_x11.64.zip`（注意不是 `linux.x86_64`！）
- Linux headless（CI 用）：`Godot_v3.6.2-stable_linux_headless.64.zip`
- Windows：`Godot_v3.6.2-stable_win64.exe.zip`
- macOS：`Godot_v3.6.2-stable_osx.universal.zip`
- Export templates：`Godot_v3.6.2-stable_export_templates.tpz`

**CI 关键点：**
- GitHub Actions Ubuntu runner 没有 X11 display，必须用 `linux_headless.64`
- Windows/macOS desktop 构建可以用普通版
- Web 导出步骤需在 Linux headless 环境运行，需 Godot 4 Export Templates 也要对应版本

## Godot 4 → 3 GDScript 完整对照表

| Godot 4 | Godot 3 |
|---------|---------|
| `@onready var x` | `onready var x` |
| `@export var x` | `export var x` |
| `var x: Type` | `var x` |
| `func x(arg: Type) -> Type` | `func x(arg)` |
| `Array[bool/int/String]` | `Array()` |
| `Color.WHITE` | `Color.white` |
| `.emit(arg)` | `emit_signal("name", arg)` |
| `create_tween()` | `Tween.new()` |
| `tween.interpolate_property()` | 相同 |
| `.tween_property()` | `.interpolate_property()` |
| `.connect(method)` | `connect("signal", self, "method")` |
| `.bind(i)` in connect | 不支持！用 `btn.set_meta("idx", i)` + `connect(..., [i])` |
| `get_tree().change_scene_to_file("x")` | `get_tree().change_scene("res://x.tscn")` |
| `Label.HORIZONTAL_ALIGNMENT_CENTER` | `Label.ALIGN_CENTER` |
| `Label.VERTICAL_ALIGNMENT_BOTTOM` | `Label.VALIGN_BOTTOM` |
| `Control.PRESET_FULL_RECT` | `Control.PRESET_WIDE` |
| `await signal` | `yield(signal, "completed")` |
| `signal name:` | `signal name`（无冒号） |
| `DirAccess.remove_absolute(path)` | 相同（Godot 3.6） |
| `Vector2.UP` | `Vector2(0, -1)` |
| `remove_at(idx)` | `remove(idx)` |

### Tween 模式（Godot 3）
```gdscript
# Godot 4:
var tween = create_tween()
tween.tween_property(sprite, "position", Vector2(100, 0), 0.5)

# Godot 3:
var tween = Tween.new()
add_child(tween)
tween.interpolate_property(sprite, "position", sprite.position, Vector2(100, 0), 0.5)
tween.start()
```

### connect + bind workaround（Godot 3）
```gdscript
# Godot 4 (not supported in Godot 3):
btn.connect("pressed", self, "_on_btn_pressed", [i])

# Godot 3 workaround:
btn.set_meta("slot_index", i)
btn.connect("pressed", self, "_on_btn_pressed")

func _on_btn_pressed():
    var idx = get_node(".").get_meta("slot_index")
```

### emit_signal 模式（Godot 3）
```gdscript
# Godot 4:
item_collected.emit(item)

# Godot 3:
emit_signal("item_collected", item)
```

## 相关项目
- YeLuo45/room-escape-puzzle：使用 Godot 4.4.1 + Compatibility 渲染器 + `.github/workflows/build.yml` 指定 `renderer/rendering_method="gl_compatibility"` 修复 GL_INVALID_ENUM。部署平台：Netlify（支持 COOP/COEP headers）
