---
name: debug-click-handler-silent-failure
description: Debug silent click handler failures where async/await chains break quietly without console errors. For when users click but nothing happens.
---
# Debug: Click Handler Silent Failure

## Trigger
用户点击页面按钮没有任何反应，Console 没有明显报错。

## Core Principle
async/await 链式失败是**静默的**：`await` 后面断了不会直接抛出错误，整条调用链就停在那里。

## Step-by-Step Debug Flow

### 1. 定位 click handler
用 browser_snapshot 找到按钮的 ref，然后用 browser_console 执行：
```javascript
// 找到 handler 源码位置
var btn = document.getElementById('start-btn');
btn?.onclick?.toString().match(/function\s+(\w+)/)?.[1]
```

### 2. 手动调用 handler，trace 执行流
```javascript
// 直接调用 click handler，看能否走到下一个函数
startGame.toString()  // 先看函数存在不
startGame()           // 调用，看是否报错或卡住
```

### 3. 检查 async 链是否断了
```javascript
// 在关键 await 处加 try-catch，看谁 reject 了
async function check() {
  try {
    await initGame()
    console.log('initGame succeeded')
  } catch(e) {
    console.error('initGame failed:', e)
  }
}
check()
```

### 4. 验证网络资源可用性
**不能只看代码里有 URL**，要实际 curl：
```bash
curl -I --max-time 5 "https://threejs.org/examples/models/gltf/RobotExpressive/RobotExpressive.glb"
```
常见坑：threejs.org 等 CDN 在某些网络环境下访问不到。

### 5. 常见 null 元素报错（有 try-catch 兜底）
```javascript
// 这种报错可能被吞掉，要主动找
window.onerror 或
window.addEventListener('error', e => console.error('UNCAUGHT:', e))
```

## Common Patterns

| 场景 | 症状 | 根因 |
|------|------|------|
| `addEventListener` on null | Console 有报错，但按钮点击仍有效 | 元素不存在（有 try-catch 兜底） |
| async chain broken | 点击无任何反应，Console 干净 | await 后的 Promise reject |
| 外部模型加载失败 | 3D 场景不出现 | CDN 访问不到或 CORS |
| 资源 404 | 按钮样式崩了 | favicon.ico 等资源加载失败 |

## Verification Checklist
- [ ] 按钮存在且可点击（`btn.click()` 能触发 handler）
- [ ] handler 函数存在
- [ ] handler 内部每个 await 都能 resolve
- [ ] 外部资源（CDN 模型、图片）实际可访问
- [ ] DOM 元素在注册 listener 时已存在

## Case Study
whack-a-mole-3d 游戏点击"开始游戏"无反应。
- Console 报错：`Cannot read properties of null (reading 'addEventListener')` — 但这个报错被 try-catch 吞了
- 实际根因：`startGame()` → `initGame()` → `loadGLTFModel()` 加载 threejs.org 模型失败，Promise reject，链式调用中断
- 修复：用 curl 发现 threejs.org 模型不可达，本地缓存后重试
