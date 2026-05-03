---
name: python-desktop-automation
description: Python 桌面应用自动化 — PyAutoGUI 鼠标键盘控制、截图定位、图像识别驱动 UI 操作。适用于 Windows/macOS/Linux 跨平台桌面自动化，包含 AI Agent 视觉控制集成方案。
version: 1.1.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [desktop, automation, pyautogui, gui, python, keyboard, mouse, windows, rpa]
    related_skills: [systematic-debugging, test-driven-development]
---

# Python Desktop Automation

## Overview

Python 桌面自动化操作技能，通过 PyAutoGUI 等库实现鼠标控制、键盘输入、截图定位、图像识别驱动的 UI 操作。

**核心能力：**
- 鼠标移动、点击、拖拽、滚动
- 键盘输入和快捷键组合
- 截图 + 图像识别定位 UI 元素
- 消息框弹窗、确认框、输入框
- 跨平台支持（Windows/macOS/Linux）

**适用场景：**
- 桌面软件自动测试
- 批量重复性操作（文件处理、表单填写）
- 游戏脚本（图像识别驱动）
- RPA 桌面自动化
- AI Agent 视觉控制桌面

---

## Installation

### Windows（原生）

```bash
# PowerShell 或 CMD
pip install pyautogui opencv-python pillow
```

> **注意**：Windows 原生环境运行，不需要 X11。但如果使用 WSL 并尝试从内部控制 Windows 桌面，会失败（WSL 没有 Windows GUI 访问权限）。推荐直接在 Windows CMD/PowerShell 中运行脚本。

### macOS

```bash
pip install pyautogui opencv-python pillow
pip install pyobjc-core pyobjc  # 必须，防止崩溃
```

### Linux (X11)

```bash
sudo apt install scrot python3-tk python3-dev
pip install pyautogui opencv-python pillow
```

### Linux (WSL 无头环境)

WSL 纯命令行环境**无法控制桌面 GUI**。如需从 WSL 操作 Windows 桌面：
- 方案 A：在 Windows 侧运行 Python 脚本
- 方案 B：配置 VcXsrv/X410 WSLg 图形转发（复杂，不推荐）

---

## 安全机制

### FAILSAFE

将鼠标移到**屏幕四角之一**（左上/右上/左下/右下）会立即触发异常，停止所有自动化操作。

```python
import pyautogui
pyautogui.FAILSAFE = True  # 默认开启
```

### PAUSE

每次操作后自动暂停，防止操作过快导致失控。**生产环境务必设置**。

```python
pyautogui.PAUSE = 0.5  # 每次操作后暂停0.5秒
```

### 完整安全配置

```python
import pyautogui

# 必须在任何操作前设置
pyautogui.FAILSAFE = True   # 紧急停止
pyautogui.PAUSE = 0.5       # 操作间隔

# 建议同时设置屏幕尺寸提醒
width, height = pyautogui.size()
print(f"屏幕尺寸: {width}x{height}")
```

---

## Core API

### 1. 鼠标操作

```python
import pyautogui

# ========== 基础信息 ==========
width, height = pyautogui.size()           # 获取屏幕尺寸
x, y = pyautogui.position()                  # 获取当前鼠标坐标
pyautogui.onScreen(x, y)                     # 检查坐标是否在屏幕范围内 -> True/False

# ========== 移动鼠标 ==========
pyautogui.moveTo(x, y, duration=0.5)         # 绝对移动，0.5秒平滑移动到 (x, y)
pyautogui.move(xOffset, yOffset)            # 从当前位置相对偏移

# ========== 点击 ==========
pyautogui.click(x, y)                       # 单击坐标
pyautogui.click(x, y, clicks=2)             # 双击
pyautogui.click(x, y, clicks=2, interval=0.1)  # 双击，间隔0.1秒
pyautogui.rightClick(x, y)                  # 右键
pyautogui.middleClick(x, y)                 # 中键

# ========== 拖拽 ==========
pyautogui.dragTo(x, y, duration=0.5)       # 拖拽到目标（按住拖）
pyautogui.drag(xOffset, yOffset, duration=0.5)  # 相对拖拽

# ========== 滚动 ==========
pyautogui.scroll(clicks=3)                  # 向上滚动3格（正数=上，负数=下）
pyautogui.scroll(-3)                        # 向下滚动3格
pyautogui.hscroll(clicks=3)                 # 水平滚动（需要 mouse 模块）
pyautogui.vscroll(clicks=3)                 # 垂直滚动

# ========== 按住/释放 ==========
pyautogui.mouseDown(x, y)                   # 按住鼠标
pyautogui.mouseUp(x, y)                     # 释放鼠标
```

### 2. 键盘操作

```python
import pyautogui

# ========== 文本输入 ==========
pyautogui.write('Hello World', interval=0.1)  # 输入文本，每个字符间隔0.1秒
pyautogui.write('password', interval=0.1)

# ========== 单键按下 ==========
pyautogui.press('enter')                     # 回车
pyautogui.press('esc')
pyautogui.press('tab')
pyautogui.press('backspace')
pyautogui.press('delete')
pyautogui.press('space')

# ========== 方向键 ==========
pyautogui.press('up')
pyautogui.press('down')
pyautogui.press('left')
pyautogui.press('right')

# ========== 编辑键 ==========
pyautogui.press('home')
pyautogui.press('end')
pyautogui.press('pageup')
pyautogui.press('pagedown')
pyautogui.press('insert')
pyautogui.press('printscreen')

# ========== 功能键 ==========
pyautogui.press('f1') ~ pyautogui.press('f12')

# ========== 按住/释放（用于组合键） ==========
pyautogui.keyDown('shift')
pyautogui.write('hello')                    # 输入 HELLO（大写）
pyautogui.keyUp('shift')

# ========== 快捷键组合 ==========
pyautogui.hotkey('ctrl', 'c')               # 复制
pyautogui.hotkey('ctrl', 'v')               # 粘贴
pyautogui.hotkey('ctrl', 'x')               # 剪切
pyautogui.hotkey('ctrl', 'z')               # 撤销
pyautogui.hotkey('ctrl', 'y')               # 重做
pyautogui.hotkey('ctrl', 'a')               # 全选
pyautogui.hotkey('ctrl', 's')               # 保存
pyautogui.hotkey('ctrl', 'f')               # 搜索
pyautogui.hotkey('alt', 'tab')              # 切换窗口
pyautogui.hotkey('alt', 'f4')               # 关闭窗口
pyautogui.hotkey('win', 'd')                # 显示桌面
pyautogui.hotkey('win', 'r')                # 运行对话框
pyautogui.hotkey('ctrl', 'shift', 'esc')   # 三键组合
```

### 3. 图像识别定位

**核心能力**：截取 UI 截图 → 用图像识别在屏幕上定位 → 操作

```python
import pyautogui

# ========== 基础查找 ==========
location = pyautogui.locateOnScreen('button.png')
# 返回: (left, top, width, height) 或 None

if location:
    center = pyautogui.center(location)      # 返回 (x, y) 中心点
    pyautogui.click(center)

# ========== 直接找中心点（最常用） ==========
try:
    x, y = pyautogui.locateCenterOnScreen('target.png')
    pyautogui.click(x, y)
except TypeError:
    print("未找到图像")

# ========== 查找所有匹配位置 ==========
locations = list(pyautogui.locateAllOnScreen('icon.png'))
print(f"找到 {len(locations)} 个匹配")

# ========== 性能/精度选项 ==========
pyautogui.locateOnScreen('btn.png', grayscale=True)    # 灰度匹配，更快
pyautogui.locateOnScreen('btn.png', confidence=0.8)     # 降低置信度，更宽松
pyautogui.locateOnScreen('btn.png', region=(0,0,800,600))  # 只在区域中查找

# ========== OpenCV vs Pillow ==========
# OpenCV 安装后: 速度快，精度高，支持confidence参数
# 只有 Pillow: 速度慢，精度低，不支持 confidence
try:
    import cv2
    print("图像识别模式: OpenCV (高精度)")
except ImportError:
    print("图像识别模式: Pillow (低精度，建议安装 opencv-python)")
```

### 4. 截图

```python
import pyautogui

# ========== 全屏截图 ==========
screenshot = pyautogui.screenshot()
screenshot.save('full_screen.png')

# ========== 区域截图 (left, top, width, height) ==========
screenshot = pyautogui.screenshot(region=(100, 100, 300, 400))
screenshot.save('region.png')

# ========== 获取截图但不保存 ==========
img = pyautogui.screenshot(region=(0, 0, 1920, 1080))
# img 是 Pillow Image 对象，可以直接处理

# ========== 快速保存到用户目录 ==========
import os
desktop = os.path.join(os.path.expanduser("~"), "Desktop")
screenshot.save(os.path.join(desktop, "screenshot.png"))
```

### 5. 消息框

```python
import pyautogui

# ========== 警告框（只有确定） ==========
pyautogui.alert('操作完成！', title='提示')

# ========== 确认框（返回 'OK' 或 'Cancel'） ==========
result = pyautogui.confirm('确认继续吗？', title='确认', buttons=['OK', 'Cancel'])
if result == 'OK':
    print("用户点击了确定")

# ========== 输入框（返回输入内容或 None） ==========
name = pyautogui.prompt('请输入名称：', title='输入', default='默认名称')
if name:
    print(f"用户输入了: {name}")

# ========== 密码框（返回密码内容） ==========
password = pyautogui.password('请输入密码：', title='密码', mask='*')
if password:
    print(f"密码长度: {len(password)}")
```

### 6. 窗口信息

```python
import pyautogui

# ========== 获取屏幕尺寸 ==========
w, h = pyautogui.size()
print(f"屏幕: {w}x{h}")

# ========== 获取鼠标位置 ==========
x, y = pyautogui.position()
print(f"鼠标: ({x}, {y})")

# ========== 检查坐标是否有效 ==========
pyautogui.onScreen(100, 100)  # True
pyautogui.onScreen(9999, 9999)  # False
```

---

## 常用模式

### 模式1：固定坐标操作（快速）

适用于 UI 位置固定的场景，如游戏、固定窗口软件。

```python
import pyautogui
import time

# 安全配置
pyautogui.FAILSAFE = True
pyautogui.PAUSE = 0.5

# 等待用户切换到目标窗口
print("请在 3 秒内切换到目标窗口...")
time.sleep(3)

# 固定坐标点击
pyautogui.click(500, 300)
pyautogui.write('Hello', interval=0.1)
pyautogui.press('enter')
```

### 模式2：图像识别定位（鲁棒）

适用于 UI 位置可能变化、多显示器、不同 DPI 的场景。**推荐优先使用此模式**。

```python
import pyautogui
import time

pyautogui.FAILSAFE = True
pyautogui.PAUSE = 0.5

time.sleep(2)

# 通过图像识别定位并点击
try:
    x, y = pyautogui.locateCenterOnScreen('save_button.png')
    pyautogui.click(x, y)
    print(f"点击了保存按钮 ({x}, {y})")
except TypeError:
    print("未找到保存按钮")

# 灰度模式（更快，不依赖颜色）
try:
    x, y = pyautogui.locateCenterOnScreen('menu_icon.png', grayscale=True)
    pyautogui.click(x, y)
except TypeError:
    print("未找到菜单图标")
```

### 模式3：图像识别 + 坐标偏移

适用于图像中心不是点击目标的情况。

```python
location = pyautogui.locateOnScreen('checkbox.png')
if location:
    center = pyautogui.center(location)
    # 复选框中心往右偏移20像素（勾选区域）
    pyautogui.click(center[0] + 20, center[1])
```

### 模式4：循环等待图像出现

适用于等待异步加载、进度条完成、弹窗出现等场景。

```python
import pyautogui
import time

def wait_for_image(image_path, timeout=30, confidence=0.8):
    """等待图像出现，超时返回 None"""
    start = time.time()
    while time.time() - start < timeout:
        try:
            x, y = pyautogui.locateCenterOnScreen(image_path, confidence=confidence)
            print(f"找到图像 ({x}, {y})")
            return (x, y)
        except TypeError:
            pass
        time.sleep(1)
    print(f"等待 {timeout} 秒后未找到图像")
    return None

# 使用
result = wait_for_image('loading_done.png', timeout=60)
if result:
    pyautogui.click(result)
```

### 模式5：拖拽操作

适用于文件拖拽、列表重排、绘图等场景。

```python
# 从 (100, 200) 拖拽到 (500, 300)
pyautogui.moveTo(100, 200)
pyautogui.mouseDown()           # 按住
pyautogui.moveTo(500, 300, duration=1)  # 拖动
pyautogui.mouseUp()             # 释放

# 简化写法
pyautogui.dragTo(500, 300, duration=1)
```

### 模式6：批量操作 + 进度显示

```python
import pyautogui
import time

pyautogui.FAILSAFE = True
pyautogui.PAUSE = 0.3

items = ['item1', 'item2', 'item3', 'item4', 'item5']

for i, item in enumerate(items):
    # 模拟操作
    print(f"[{i+1}/{len(items)}] 处理 {item}...")
    
    # 假设每项都需要点击对应按钮
    btn = pyautogui.locateCenterOnScreen(f'btn_{item}.png')
    if btn:
        pyautogui.click(btn)
    else:
        print(f"  警告: 未找到 {item} 的按钮")
    
    time.sleep(0.5)

print("批量操作完成")
```

---

## Windows 进阶操作

### 窗口管理

```python
import pywinauto  # 独立库，需要单独安装: pip install pywinauto

# 连接到已有窗口
app = pywinauto.Application().connect(title="Notepad")
win = app.window(title="Notepad")

# 窗口操作
win.set_focus()                    # 聚焦窗口
win.maximize()                     # 最大化
win.minimize()                     # 最小化
win.restore()                      # 恢复
win.close()                        # 关闭

# 获取窗口位置和尺寸
rect = win.rect()
print(f"窗口位置: {rect}")

# 发送按键到窗口
win.type_keys("Hello World")
win.type_keys("%FX")               # Alt+F4 (通过 pywinauto)
```

### 全局快捷键

```python
# 使用 keyboard 库（需要: pip install keyboard）
import keyboard

# 注册全局热键
keyboard.add_hotkey('ctrl+shift+a', lambda: print("热键触发"))
keyboard.add_hotkey('win+d', lambda: print("显示桌面"))

# 等待热键（会阻塞）
keyboard.wait('ctrl+q')  # 按 Ctrl+Q 退出

# 注意：keyboard 在某些情况下需要管理员权限
```

### 全局鼠标监听

```python
# 使用 mouse 库（需要: pip install mouse）
import mouse
import time

# 监听鼠标事件
def on_click(x, y, button, pressed):
    if pressed:
        print(f"鼠标按下: ({x}, {y}), 按钮: {button}")

mouse.on_click(on_click)

# 监听滚动
def on_scroll(x, y, dx, dy):
    print(f"滚动: dx={dx}, dy={dy}")

mouse.on_scroll(on_scroll)

# 阻塞主线程，直到调用 unhook
# mouse.unhook_all()

# 模拟鼠标（独立于 pyautogui）
mouse.move(100, 200, duration=0.5)
mouse.click(100, 200)
```

---

## AI Agent 集成方案

### 方案 A：视觉模型 + PyAutoGUI

截取屏幕 → 发送给视觉模型 → 解析坐标 → 执行操作：

```python
import pyautogui
import os
import json

def get_screen_info():
    """获取屏幕基本信息"""
    return {
        'screen_size': pyautogui.size(),
        'mouse_position': pyautogui.position(),
    }

def save_screenshot(label="screen"):
    """保存截图供视觉模型分析"""
    path = f'/tmp/{label}.png'
    pyautogui.screenshot(path)
    return path

def click_at_vision_coordinates(x, y):
    """安全点击（先验证坐标范围）"""
    if pyautogui.onScreen(x, y):
        pyautogui.click(x, y)
        return True
    else:
        print(f"坐标 ({x}, {y}) 超出屏幕范围")
        return False

# === 工作流 ===
# 1. 保存截图
screenshot_path = save_screenshot("current")

# 2. 发送给视觉模型（如 Claude/GPT-4V）
# prompt = """分析这张截图，找出 "提交" 按钮的中心坐标。
#             只返回一个 JSON: {"x": 数字, "y": 数字}，不要其他内容。"""

# 3. 假设模型返回了坐标
# vision_result = {"x": 650, "y": 450}

# 4. 执行点击
# click_at_vision_coordinates(vision_result["x"], vision_result["y"])
```

### 方案 B：图像模板库 + 自动化工作流

预先截取所有需要的 UI 元素图像，建立模板库：

```python
import pyautogui
import os

class UITemplateLibrary:
    """UI 元素模板库"""
    
    def __init__(self, template_dir="templates"):
        self.template_dir = template_dir
        os.makedirs(template_dir, exist_ok=True)
    
    def capture(self, name, region=None):
        """截取 UI 元素保存为模板"""
        if region:
            img = pyautogui.screenshot(region=region)
        else:
            img = pyautogui.screenshot()
        path = os.path.join(self.template_dir, f"{name}.png")
        img.save(path)
        print(f"已保存模板: {path}")
        return path
    
    def find(self, name, confidence=0.8):
        """查找模板位置"""
        path = os.path.join(self.template_dir, f"{name}.png")
        if not os.path.exists(path):
            raise FileNotFoundError(f"模板不存在: {path}")
        try:
            return pyautogui.locateCenterOnScreen(path, confidence=confidence)
        except TypeError:
            return None
    
    def click(self, name, confidence=0.8):
        """查找并点击"""
        pos = self.find(name, confidence)
        if pos:
            pyautogui.click(pos)
            return True
        return False

# 使用
ui = UITemplateLibrary("app_templates")

# 首次运行时捕获模板
# ui.capture("save_button", region=(100, 200, 150, 50))

# 自动化流程
if ui.click("save_button"):
    print("点击了保存按钮")
```

---

## 扩展库生态

| 库 | 安装 | 用途 | 平台 |
|----|------|------|------|
| `pyautogui` | `pip install pyautogui` | 鼠标键盘 GUI 自动化 | 跨平台 |
| `opencv-python` | `pip install opencv-python` | 图像识别增强 | 跨平台 |
| `keyboard` | `pip install keyboard` | 全局键盘监听/模拟 | 跨平台 |
| `mouse` | `pip install mouse` | 全局鼠标监听/模拟 | 跨平台 |
| `pywinauto` | `pip install pywinauto` | Windows 窗口控件树 | Windows |
| `uiautomation` | `pip install uiautomation` | Windows UIAutomation | Windows |
| `pyautogui` + `win32api` | 系统自带 | Windows API 调用 | Windows |
| `pynput` | `pip install pynput` | 监听和控制鼠标键盘 | 跨平台 |
| `autogen` | `pip install pyautogen` | AI Agent 多代理编排 | 跨平台 |

**推荐组合：**
- 通用快速自动化：`pyautogui` + `opencv-python`
- Windows 深度控制：`pyautogui` + `pywinauto`
- AI Agent 视觉控制：`pyautogui` + 视觉模型 (Claude/GPT-4V)
- 游戏脚本：`pyautogui` + 图像识别 + `keyboard`

---

## 常见问题

### Q: 图像识别找不到图

**原因1：图像格式/质量不对**
```python
# 使用 PNG，背景透明效果最好
# 截图时尽量只截取目标元素，不要包含太多背景
```

**原因2：屏幕 DPI / 显示缩放不一致**
```python
# 不同 DPI 下同一 UI 元素截图不同
# 在目标机器上重新截取模板
# 使用灰度模式降低 DPI 敏感度
pyautogui.locateOnScreen('btn.png', grayscale=True)
```

**原因3：置信度太高**
```python
# 降低置信度（默认 0.9）
pyautogui.locateOnScreen('btn.png', confidence=0.7)
```

**原因4：窗口被遮挡或最小化**
```python
# 使用 pywinauto 将窗口置顶
from pywinauto import Application
app = Application().connect(title="窗口标题")
app.window(title="窗口标题").set_focus()
```

### Q: 坐标超出屏幕范围

```python
# 总是先检查
if pyautogui.onScreen(x, y):
    pyautogui.click(x, y)
else:
    print(f"坐标 ({x}, {y}) 超出屏幕 {pyautogui.size()}")
```

### Q: 操作太快失控

```python
# 必须在操作前设置
pyautogui.PAUSE = 0.5   # 每次操作后暂停 0.5 秒
pyautogui.FAILSAFE = True  # 移到角落紧急停止

# 调试时增加暂停
pyautogui.PAUSE = 1.0
```

### Q: macOS 上立即崩溃

```bash
# 必须安装 pyobjc
pip install pyobjc-core pyobjc
```

### Q: Linux 上截图返回全黑

```bash
# 需要安装 scrot
sudo apt install scrot
```

### Q: WSL 环境中无法操作 Windows 桌面

**这是正常的，WSL 没有 GUI 访问权限。**

解决方案：
1. 在 Windows CMD/PowerShell 中运行脚本（推荐）
2. 配置 X11 转发（复杂，不推荐）
3. 从 WSL 调用 Windows Python：`cmd.exe /c python script.py`

### Q: 多显示器支持

```python
# PyAutoGUI 默认只检测主显示器
# 多显示器时坐标可能不对

# 解决方案：使用 pywinauto 获取所有显示器信息
from pywinauto import desktop
screens = desktop(backend="uia").wrapper_object()
print(screens.rect())
```

---

## 最佳实践

1. **安全第一**
   - 始终设置 `PAUSE` 和 `FAILSAFE`
   - 操作前验证坐标是否在屏幕范围内

2. **优先使用图像识别**
   - 不要硬编码坐标，除非 UI 绝对固定
   - 在目标机器上截取模板图像
   - 使用相对偏移而非绝对坐标

3. **健壮的等待逻辑**
   ```python
   # 不要假设 UI 立即就绪
   def wait_for_image(img, timeout=30, interval=1):
       start = time.time()
       while time.time() - start < timeout:
           if pyautogui.locateOnScreen(img):
               return True
           time.sleep(interval)
       return False
   ```

4. **截图技巧**
   - 只截取目标元素，小图比大图匹配更快
   - PNG 透明背景效果最好
   - 避免截取包含动态内容的区域（进度条、时间等）

5. **调试时降低速度**
   ```python
   pyautogui.PAUSE = 2.0  # 慢速，便于观察
   # 完成后改回正常速度
   pyautogui.PAUSE = 0.3
   ```

6. **异常处理**
   ```python
   try:
       x, y = pyautogui.locateCenterOnScreen('target.png')
       pyautogui.click(x, y)
   except TypeError:
       # 图像未找到的处理
       pass
   ```

---

## 快速验证脚本

**Windows 版**（保存到桌面，用 CMD 运行）：

```python
#!/usr/bin/env python3
"""PyAutoGUI 桌面自动化快速验证 — Windows 版"""
import sys
import os

print("=== PyAutoGUI 桌面自动化验证 ===\n")

# 1. 依赖检查
print("[1] 依赖检查")
deps = {}
for name, import_name in [("PyAutoGUI", "pyautogui"), ("OpenCV", "cv2"), ("Pillow", "PIL")]:
    try:
        mod = __import__(import_name)
        ver = getattr(mod, "__version__", "unknown")
        deps[name] = ver
        print(f"  {name}: OK ({ver})")
    except ImportError:
        deps[name] = None
        print(f"  {name}: MISSING")

# 2. 屏幕信息
print("\n[2] 屏幕信息")
import pyautogui
w, h = pyautogui.size()
print(f"  屏幕尺寸: {w} x {h}")
print(f"  FAILSAFE: {pyautogui.FAILSAFE}")
print(f"  PAUSE: {pyautogui.PAUSE}")

# 3. 鼠标位置
print("\n[3] 鼠标位置")
x, y = pyautogui.position()
print(f"  当前位置: ({x}, {y})")
print(f"  在屏幕范围内: {pyautogui.onScreen(x, y)}")

# 4. 截图测试
print("\n[4] 截图测试")
desktop = os.path.join(os.path.expanduser("~"), "Desktop")
out_path = os.path.join(desktop, "desktop_automation_test.png")
screenshot = pyautogui.screenshot()
screenshot.save(out_path)
print(f"  截图已保存: {out_path}")
print(f"  截图尺寸: {screenshot.size}")

# 5. API 可用性检查
print("\n[5] API 可用性检查")
apis = ["moveTo", "click", "write", "press", "hotkey", "scroll",
        "locateOnScreen", "locateCenterOnScreen", "alert", "confirm", "prompt"]
for api in apis:
    avail = hasattr(pyautogui, api)
    print(f"  pyautogui.{api}: {'OK' if avail else 'MISSING'}")

# 6. OpenCV 图像识别增强
print("\n[6] OpenCV 图像识别")
try:
    import cv2
    print(f"  OpenCV 可用，版本: {cv2.__version__}")
    print("  locateOnScreen 将使用 OpenCV 加速（高精度）")
except ImportError:
    print("  WARNING: OpenCV 未安装，图像识别使用 Pillow（精度较低）")

# 7. 总结
print("\n=== 验证结果 ===")
all_ok = all(v is not None for v in deps.values())
if all_ok:
    print("所有依赖已就绪，PyAutoGUI 可用")
    print("\n将鼠标移到屏幕角落可触发 FAILSAFE 紧急停止")
else:
    missing = [k for k, v in deps.items() if v is None]
    print(f"缺少依赖: {', '.join(missing)}")
    print("\n安装命令:")
    print("  pip install pyautogui opencv-python pillow")
    sys.exit(1)
```

**运行方式**：
```cmd
cd %USERPROFILE%\Desktop
python desktop_automation_check.py
```

---

## 应用场景速查

| 场景 | 核心代码 |
|------|---------|
| 自动填写表单 | `pyautogui.click(x, y)` → `pyautogui.write(text)` |
| 点击图像按钮 | `pyautogui.click(*pyautogui.locateCenterOnScreen('btn.png'))` |
| 等待加载完成 | `wait_for_image('loaded.png', timeout=60)` |
| 文件拖拽 | `pyautogui.dragTo(target_x, target_y, duration=1)` |
| 批量处理 | `for item in items: click_item(item); do_work()` |
| 快捷键操作 | `pyautogui.hotkey('ctrl', 's')` |
| 定时任务 | `while True: do_task(); time.sleep(60)` |

---

## 相关工具对比

| 工具 | 语言 | UI 控件树 | 图像识别 | 跨平台 |
|------|------|-----------|---------|--------|
| **PyAutoGUI** | Python | ❌ | ✅ | ✅ |
| pywinauto | Python | ✅ | ❌ | Windows |
| UIAutomation | Python | ✅ | ❌ | Windows |
| WinAppDriver | 多语言 | ✅ | ✅ | Windows |
| Playwright | 多语言 | ✅ | ✅ | ✅ |
| AutoHotkey | 脚本 | ❌ | ✅ | Windows |
| SikuliX | Java | ✅ | ✅ | ✅ |
| `keyboard` 库 | Python | ❌ | ❌ | ✅ |
| `pynput` 库 | Python | ✅ | ❌ | ✅ |
