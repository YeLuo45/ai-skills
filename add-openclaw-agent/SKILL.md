# Add OpenClaw Agent Skill

This skill guides the AI assistant on how to add a new OpenClaw agent to the user's local configuration, complete with a dedicated workspace, specific roles (SOUL/IDENTITY), and messaging channel bindings (like Feishu).

## Prerequisites

- Understand that OpenClaw's main configuration file is usually at `~/.openclaw/openclaw.json`.
- Know that each agent requires its own dedicated workspace folder (e.g., `~/.openclaw/workspaces/<agentId>`).

## Step-by-Step Execution Guide

### 1. Update `openclaw.json`
Modify the `openclaw.json` file using the `Write` or `StrReplace` tool.
- **Add to `agents.list`**: Insert the new agent object with its `id`, `name`, and absolute `workspace` path.
- **Add a Channel**: If the agent uses a new messaging channel (e.g., a new Feishu bot), add a new entry under `channels` (e.g., `openclaw-feishu-<agentId>`). Provide its `enabled`, `appId`, and `appSecret`.
- **Add Bindings**: Add a new routing rule under `bindings` to connect the agent to its specific channel and `accountId: "default"`.
- **Enable Plugin**: Ensure the corresponding plugin is enabled under `plugins.entries`.

*(Note on Feishu plugin: If the user requires multiple Feishu bots, the official `openclaw-feishu` plugin currently supports a single account per plugin instance. A reliable workaround is to duplicate the `~/.openclaw/extensions/openclaw-feishu` folder into a new one (like `openclaw-feishu-<agentId>`), use `StrReplace` or a script to replace all occurrences of `openclaw-feishu` to `openclaw-feishu-<agentId>` in the duplicated folder's files, run `npm install` inside it, and enable both plugins.)*

### 2. Set Up the Agent's Workspace
- Use `Shell` (`mkdir`) to create the agent's workspace folder.
- Use `Write` to create essential files:
  - **`IDENTITY.md`**: Defines who the agent is (e.g., "You are an experienced Product Manager...").
  - **`SOUL.md`**: Defines the strict operational rules and workflows for the agent (e.g., "Your job is to accept ideas, confirm details, and output a PRD.").
  - **`AGENTS.md`**: The address book for multi-agent communication. List the IDs and descriptions of other agents this new agent is allowed to talk to.

### 3. Update Existing Agents
If the new agent is meant to collaborate with an existing agent (like `main`), you **MUST**:
- Update the existing agent's `AGENTS.md` to include the new agent's ID and description.
- Update the existing agent's `SOUL.md` so it knows *when* and *why* to hand off tasks to the new agent.

### 4. Restart OpenClaw Gateway
Use the `Shell` tool to restart the Gateway so the new configuration and plugins take effect.
```powershell
# (Requires Administrator PowerShell if installed as a service)
cd /d <OpenClaw Source Directory>
pnpm openclaw gateway restart
```
If not installed as a service, just kill the existing node process and start it again via `pnpm openclaw gateway start` or interactively.
