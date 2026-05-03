---
name: vite-build-cache-debug
description: Diagnose and resolve Vite build cache issues where source changes don't appear in production builds
---
# Vite Build Cache Debug

## Problem
Vite refuses to rebuild from source - `npm run build` produces the same output MD5 regardless of source changes. Even `--force` flag, deleting `dist/`, and reinstalling `node_modules` don't help.

## Diagnosis Steps
1. Compare source fix with built output: `grep "fix_string" src/file.js` vs `grep "fix_string" dist/assets/*.js`
2. If source has fix but build doesn't → Vite is reading from frozen cache
3. Check MD5 of build output: `md5sum dist/assets/*.js` before and after rebuild attempts
4. Try `npx vite build --force` - if MD5 unchanged, cache is persistent

## Why This Happens
Vite stores build cache in `node_modules/.vite/` (or sometimes elsewhere). If that directory is somehow protected/mirrored, standard clearing doesn't work.

## Solution: Direct Patch Production Build
When source won't recompile, patch the built JS directly:

1. **Identify exact strings to replace** in the minified `dist/assets/*.js`:
   - Read the built file: `grep "old_string" dist/assets/*.js`
   - Use unique surrounding context for reliability

2. **Use sed instead of patch tool for minified JS:**
   ```bash
   # sed is more reliable than patch tool for single-line minified JavaScript
   # patch tool can misalign comma operators and expressions
   sed -i 's/old_pattern/new_pattern/g' dist/assets/index-XXXXX.js
   node --check dist/assets/index-XXXXX.js  # verify syntax
   ```

3. **Verify fix count**: `grep -o "fix_pattern" dist/assets/*.js | wc -l`

4. **Commit and push**:
   ```bash
   git add dist/assets/index-XXXXX.js
   git commit -m "fix: patch built JS directly"
   git push origin gh-pages
   ```

## When to Use sed vs patch Tool

| Tool | Best for | Avoid for |
|------|----------|-----------|
| `sed` | Targeted string replacement in minified/uglified JS | Multi-line changes |
| `patch` | Source code with proper formatting | Minified single-line JS (causes syntax errors) |

## GitHub Pages CDN Gotcha
## GitHub Pages CDN Gotcha
After pushing fixed build, GitHub Pages CDN caches content for `max-age=600` (10 min).
- `curl -sI \"https://...index.html\" | grep -i \"x-cache\\|age\"` shows cache status
- Even `git show` shows correct content but CDN serves stale
- Trigger rebuild: `POST /repos/{owner}/{repo}/pages/builds`
- Or wait 10 minutes for natural expiry

## gh-pages Branch Structure Trap
Some repos have DUAL structures on gh-pages: root-level files (index.html, assets/) AND a dist/ subdirectory. GitHub Pages serves from ROOT index.html, NOT dist/index.html.

Diagnosis:
- `curl https://raw.githubusercontent.com/{owner}/{repo}/gh-pages/index.html` shows correct content
- But `curl https://{owner}.github.io/{repo}/index.html` serves stale
- `curl -sI` shows `x-cache: HIT` confirming CDN serves old content
- Root cause: Pages reads from root-level files, not dist/

Check BOTH locations when debugging deployment issues.

## Key Insight
When build tools fail, directly patching the production artifact is a valid last resort. The fix still needs to eventually be applied to source, but game/deploy doesn't have to wait for build system debugging.

## Context
Discovered during ash-echoes (P-20260422-002) development. Source Level.js was correct but Vite produced stale build for 2+ hours of debugging attempts.
