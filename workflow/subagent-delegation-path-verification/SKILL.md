---
name: subagent-delegation-path-verification
description: 委托 subagent 前必须验证项目路径和技术栈，防止 subagent 在错误目录工作
---

# Subagent Delegation Path Verification

## Problem
When delegating to subagents for web UI work, subagents may search for projects in the wrong directory, resulting in wasted iterations. Subagents use file search which finds files by content/pattern, not verifying the actual intended project root.

## Symptoms
- Subagent completes task in a different directory than intended
- Subagent reports "Note: path X doesn't exist" or creates work in unexpected locations
- Files modified are not in the expected project tree

## Root Cause
Subagent searches for files like `package.json`, `src/`, `vite.config.*` across the entire filesystem and picks the first match, without verifying it's the right project context.

## Prevention Checklist (mandatory before delegation)
Before creating subagent tasks, always verify:
1. Confirm the exact absolute path of the project root
2. Confirm the technology stack (React vs vanilla JS vs Vue, etc.)
3. Confirm where the web entry point actually is (is it a single HTML file or a framework?)
4. Confirm the backend API path and its actual endpoints
5. Provide the subagent with the exact path, not a pattern to search for

## If Subagent Goes Wrong Path
- Do NOT wait for max_iterations to finish - abort and re-delegate with corrected path info
- Provide explicit `cd /exact/path &&` in the task goal
- If the subagent creates files in the wrong location, note which files need to be manually moved/copied

## Post-Delegation Verification (MANDATORY)
After subagent completes, ALWAYS verify the files are in the correct location:
```bash
# Check file line count or existence at expected path
wc -l /expected/path/index.html

# If subagent wrote to workspace-dev instead, copy to correct location
cp -r ~/.hermes/proposals/workspace-dev/proposals/<project>/ /correct/project/path/
```

**Common wrong path pattern**: subagent writes to `~/.hermes/proposals/workspace-dev/proposals/<project>/` instead of the actual project path like `/mnt/c/Users/<username>/Desktop/<project>/`

**Recovery steps when this happens**:
1. Identify where subagent wrote files (check workspace-dev/proposals/)
2. Copy files to correct project location
3. Create new branch from master, replace files, commit and push
4. If merge conflict occurred, be careful: "ours" in git merge refers to current branch HEAD, which may be OLD code - always verify with `git show :2:filename` (stage 2 = ours/HEAD, stage 3 = theirs) before resolving
5. In merge conflict: stage :1 = common base, :2 = ours (current HEAD), :3 = theirs (being merged). Use `git show :2:filename` to verify which version contains your feature code

## Example of Bad vs Good Delegation

**Bad**: "Modify the collaboration web UI at collaboration/web/index.html"
- Subagent searches for "index.html" and finds the wrong one

**Good**:
- Project root: `/home/hermes/.hermes/proposals/workspace-dev/proposals/hermes-agent-collab/`
- Web UI: `collaboration/web/index.html` (pure vanilla JS, NOT React)
- API backend: `collaboration/collab_api.py` (FastAPI, prefix /api/collab)
- Instructions: "First run `cd /home/hermes/.hermes/proposals/workspace-dev/proposals/hermes-agent-collab && ls collaboration/web/` to confirm the file exists"

## Technology Stack Confirmation Commands
```bash
# Check if it's a framework project or plain HTML
ls /path/to/project/package.json  # React/Vite
ls /path/to/project/*.html         # Single file or plain HTML
ls /path/to/project/src/           # Framework with src/

# Check backend API structure  
grep -n "@router\." /path/to/collab_api.py | head -20

# Check if web assets exist as compiled output or source
file /path/to/project/collaboration/web/index.html
```
