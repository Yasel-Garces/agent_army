---
description: Report what the agent army is doing (or just did) — current session activity, last session summary, recent file edits, open PRs. Run in a separate terminal to monitor a long-running session without interrupting it.
allowed-tools: Read, Bash(tail:*), Bash(head:*), Bash(cat:*), Bash(wc:*), Bash(stat:*), Bash(date:*), Bash(ls:*), Bash(awk:*), Bash(jq:*), Bash(gh pr list:*), Bash(git log:*), Bash(git status:*)
---

# /status

Quick read of what's happening (or just happened) in this project. Designed to be safe to run in a second terminal while a long-running session is in progress — read-only.

## Your steps

### 1. Current session

If `.claude/logs/session-state.json` exists, a session is active. Show:

```
## Active session

Started: <start_ts>  (running <duration> so far)
Tool calls: <count>
Last 5 tool calls:
  <ts>  <tool>  <summary>
  ...

Heartbeat: <ts of most recent tool call>
  → if older than 5 min: STALE (session may be stuck or waiting on a long Bash command)
  → if within 30s: ACTIVE
```

Read from:
- `.claude/logs/session-state.json` (start epoch, tool count, last epoch)
- `.claude/logs/activity.log` (last 5 lines)

### 2. Last completed session

Show the most recent line from `.claude/logs/sessions.log`:

```
## Last session
Ended: <ts>  Duration: <dur>  Tools: <count>  Files touched: <n>
Tail: <last 3 tool calls>
```

### 3. Recent file edits

```
git status -s
```

Show what files have uncommitted changes — gives you a quick "did the agent actually produce code?" signal.

### 4. Recent commits

```
git log --oneline -5
```

### 5. Open PRs (if `gh` available)

```
gh pr list --limit 5 --json number,title,state,headRefName 2>/dev/null
```

### 6. Recent MCP activity (if log exists)

`.claude/logs/mcp-audit.log` — tail the last 5 lines. Shows what external systems the agent has touched recently.

## Output structure

Be tight. The user runs this to glance, not to read a report. Use these section headers, skip any section that has no data:

```
## Active session       (or "No active session" if state file missing)
## Last session         (skip if sessions.log empty)
## Uncommitted changes  (skip if clean)
## Recent commits
## Open PRs             (skip if none)
## Recent MCP calls     (skip if no log)
```

## When to use

- **Long task running, want to check progress without interrupting** → run `/status` in a fresh Claude Code session in another terminal.
- **Session ended weirdly, want to know what it did** → `/status` shows last-session summary.
- **Suspect a runaway** → `/status` shows the heartbeat; if STALE or last-5-calls-identical, the runtime-watchdog likely already warned, and you should interrupt with Esc.

## Tail in plain shell (no Claude required)

You can also just do this in any terminal:

```bash
tail -f .claude/logs/activity.log    # real-time
cat .claude/logs/sessions.log        # history
```

`/status` is the human-readable wrapper.
