---
description: Token-usage report for the current session and recent history. Reads .claude/logs/tokens.jsonl. Best-effort estimates when Claude Code doesn't expose exact counts.
allowed-tools: Read, Bash(jq:*), Bash(cat:*), Bash(tail:*), Bash(wc:*), Bash(awk:*), Bash(stat:*), Bash(date:*), Bash(ls:*)
---

# /tokens

Report token usage. Read-only — safe to run anytime, including from a second terminal.

## Your steps

### 1. Locate the log

`.claude/logs/tokens.jsonl` — one JSON object per tool call (written by `hooks/token-tracker.sh`).

If the file is missing: tell the user no token data has been captured yet (probably means the plugin was just installed or this is the first session). No report; just acknowledge.

### 2. Read the active session's records

A "session" is bounded by the most recent entry of `.claude/logs/session-state.json` (start_epoch). Filter tokens.jsonl to records whose `epoch >= start_epoch`.

```bash
state_start=$(jq -r '.start_epoch // 0' .claude/logs/session-state.json 2>/dev/null || echo 0)
session_records=$(jq -c "select(.epoch >= $state_start)" .claude/logs/tokens.jsonl 2>/dev/null)
```

### 3. Aggregate

Compute:
- **Total tokens in** (sum of `tokens_in`).
- **Total tokens out** (sum of `tokens_out`).
- **Total tool calls**.
- **Breakdown by tool** (sum tokens per tool name).
- **Top 5 most expensive single calls** (sort by `tokens_in + tokens_out`, descending).
- **Estimate flag** — if any record has `is_estimate: true`, mark the totals as "estimated."

### 4. Output (concise, scannable)

```
## Token usage — current session

Session started: <ts of session-state.json start_epoch>
Tool calls: N
Tokens in (estimated):  X,XXX
Tokens out (estimated): Y,YYY
Total (estimated):      Z,ZZZ

Budget (CLAUDE_TOKEN_SOFT_LIMIT): <value or "not set">
% of budget used: NN%

### By tool
  Read           N calls    X,XXX tokens
  Edit           N calls    X,XXX tokens
  Bash           N calls    X,XXX tokens
  Agent          N calls    X,XXX tokens
  mcp__github__* N calls    X,XXX tokens

### Top 5 most expensive calls
  1. <tool>  <tokens>  at <ts>  — <summary>
  2. ...
```

### 5. Historical view (if user passes "all" or "history" or "--all")

If `$ARGUMENTS` contains "all" / "history" / "--all":
- Aggregate over the whole `tokens.jsonl` (all sessions).
- Show per-session totals (group by 30-min gap between records, or by matching with `sessions.log`).
- Show daily totals for the last 7 days.

### 6. Honesty about the estimate

Always include a note at the bottom when `is_estimate: true` records were used:

```
ℹ Numbers are estimates from input/output byte length (~4 bytes/token).
   Exact token counts aren't exposed to plugin hooks by Claude Code today;
   real-world tokens will be within ~20–30% of these estimates.
```

If `CLAUDE_TOKENS_IN` / `CLAUDE_TOKENS_OUT` env vars start being set in some records (you'll see `is_estimate: false`), the report shifts from "estimated" to "exact" automatically — flag that change ("mix of estimated + exact").

## Useful invocations

```
/tokens             — current session summary
/tokens all         — full history aggregated
/tokens history     — same as "all"
```

## When NOT to use /tokens

Don't run this constantly mid-task — it doesn't help while you're working. Run it:
- At the end of a heavy session ("did that cost more than I thought?").
- When the runtime-watchdog warns you're over a token threshold.
- When deciding whether to switch sessions or compact.

## Setting a budget

In your shell before starting Claude Code:

```bash
export CLAUDE_TOKEN_SOFT_LIMIT=500000     # warn at 500k tokens this session
export CLAUDE_TOKEN_HARD_LIMIT=1000000    # warn loudly at 1M
```

The runtime-watchdog hook reads these and emits warnings during the session; `/tokens` reads them to show "% of budget used."
