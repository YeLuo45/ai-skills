---
name: headless-game-testing
description: Headless browser testing for single-file HTML games with ES modules — exposes game state via debug API and validates through browser console.
trigger: Testing a single-file HTML game deployed to GitHub Pages where game state is inaccessible due to ES module scope isolation
---

# Headless Game Testing

## Problem

When a game is a single `index.html` using ES modules, all game variables (score, state, etc.) are in module scope and inaccessible from `window`. Standard approaches like `window.gameState` or `window.score` return `undefined`.

## Solution: Function Closure Debug Export

Add this before `</script>` at the end of the module:

```javascript
window.__getGameState = function() {
    try {
        return {
            currentScreen: typeof currentScreen !== 'undefined' ? currentScreen : null,
            score: typeof score !== 'undefined' ? score : null,
            gameRunning: typeof gameRunning !== 'undefined' ? gameRunning : null,
            gameMode: typeof gameMode !== 'undefined' ? gameMode : null,
            coins: typeof coins !== 'undefined' ? coins : null,
            stamina: typeof getStamina === 'function' ? getStamina() : null,
            gameData: typeof gameData !== 'undefined' ? JSON.parse(JSON.stringify(gameData)) : null
        };
    } catch(e) {
        return { error: e.message };
    }
};
```

**Why function not property?** ES module `let`/`const` are block-scoped. A getter on `window` looks up `score` in global scope where it doesn't exist. A function closure captures the module's lexical scope at definition time — it can see `score` from where it was defined.

## Push to GitHub

```bash
sha=$(curl -s "https://api.github.com/repos/{owner}/{repo}/contents/index.html?ref=master" \
  -H "Authorization: token {TOKEN}" | python3 -c "import sys,json; print(json.load(sys.stdin)['sha'])")
encoded=$(base64 -w0 index.html)
curl -X PUT "https://api.github.com/repos/{owner}/{repo}/contents/index.html" \
  -H "Authorization: token {TOKEN}" -H "Content-Type: application/json" \
  -d "{\"message\":\"chore: add __getGameState\",\"content\":\"$encoded\",\"sha\":\"$sha\"}"
```

Wait ~60s for Pages rebuild. Verify:
```bash
curl -s "https://{owner}.github.io/{repo}/" | grep '__getGameState'
```

## Browser Console Testing

```javascript
// Verify debug API exists
window.__getGameState ? 'OK' : 'NOT FOUND'

// Read full state
JSON.stringify(window.__getGameState())

// Read specific field
window.__getGameState().currentScreen
window.__getGameState().gameData.levels
```

## Canvas UI Navigation

Games using `<canvas>` for UI have no DOM click targets. Use synthetic events:

```javascript
var canvas = document.querySelector('canvas#ui-canvas');
var cx = canvas.width / 2;

// Hover (some games track hoveredBtn on mousemove)
var move = new MouseEvent('mousemove', {clientX: cx, clientY: BUTTON_Y, bubbles: true});
canvas.dispatchEvent(move);

// Click
var click = new MouseEvent('click', {clientX: cx, clientY: BUTTON_Y, bubbles: true});
canvas.dispatchEvent(click);

// Wait for state change
setTimeout(() => window.__getGameState().currentScreen, 200);
```

Common coordinates for 1280x720 canvas:
- Back button: (100, 70)
- Menu buttons: center X=640, startY=280, h=60 (centers: y=310, 370, 430)
- Mode select: center X=640, y=240/340

## Verify WebGL Rendering

```javascript
var gl = canvas.getContext('webgl2') || canvas.getContext('webgl');
gl ? 'WebGL OK' : 'No WebGL'

// Sample center pixel
var px = new Uint8Array(4);
gl.readPixels(canvas.width/2, canvas.height/2, 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, px);
// [0,0,0,0] = transparent (empty space), non-zero = rendered geometry
```

## Pitfalls

1. **ES module scope isolation**: `window.xxx = letVar` fails. Use function closure.
2. **GitHub Pages lag**: Rebuilds async. Always curl|grep verify before testing.
3. **Commit overwriting**: Another PR may touch index.html after your push and overwrite the debug code.
4. **Verify pushed content**: After PUT, always confirm with `curl $pagesUrl | grep '__getGameState'` — if grep fails, the push may have been rejected (SHA mismatch) or Pages is still stale. A 200 response ≠ content updated.
5. **Pages ≠ master**: GitHub Pages serves the `gh-pages` branch or Actions build artifact, not directly from master. If master content changed but Pages shows old content, check if another commit was pushed after yours that overwrote the file.
4. **CDN failure in headless**: Three.js loaded via CDN may fail in headless. Check `typeof THREE` separately.
5. **Empty snapshot**: `browser_snapshot` may say "Empty page" even when canvas renders. Use `browser_console` for state.
6. **Async state changes**: Canvas UI updates are async — always use `setTimeout(fn, 200)` before reading state.

## Quick Test Sequence

```javascript
// 1. Verify debug API
window.__getGameState ? 'OK' : 'NOT FOUND'

// 2. Check initial state
JSON.stringify(window.__getGameState())

// 3. Navigate: click menu
var c = document.querySelector('canvas#ui-canvas');
c.dispatchEvent(new MouseEvent('mousemove', {clientX: 640, clientY: 310, bubbles: true}));
c.dispatchEvent(new MouseEvent('click', {clientX: 640, clientY: 310, bubbles: true}));

// 4. Wait and check
setTimeout(() => console.log(window.__getGameState().currentScreen), 200);
```
