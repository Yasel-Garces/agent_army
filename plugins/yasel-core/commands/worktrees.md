---
description: List all active git worktrees with their status — branch, uncommitted changes, last commit, last activity time. Use to keep track of parallel work sessions.
allowed-tools: Bash(git:*), Bash(ls:*), Bash(stat:*), Bash(date:*), Read
---

# /worktrees

Snapshot of every active worktree on this repo. Read-only.

## Your steps

### 1. List worktrees

```bash
git worktree list --porcelain
```

Parse: each block has `worktree <path>`, `HEAD <sha>`, `branch <ref>`. Skip the main one (it's the user's current cwd usually).

### 2. For each non-main worktree, gather:

- **Path** — absolute.
- **Branch** — short name (strip `refs/heads/`).
- **Status** — `git -C <path> status --porcelain` → "clean" if empty, else "N uncommitted" with counts.
- **Last commit** — `git -C <path> log -1 --format='%h %s (%cr)'`.
- **Has PR?** — `gh pr list --head <branch> --json number,state,url --limit 1` (skip if `gh` unavailable).
- **Session activity** — if `<path>/.claude/logs/session-state.json` exists, read `start_epoch` + `last_epoch` to report "active" vs "idle".

### 3. Output

```
## Worktrees

(main: <path>  branch: <current-branch>)  ← your current worktree

1. <path>
   Branch:    yg/refactor-trades-recon
   Status:    2 uncommitted (1 modified, 1 untracked)
   Last commit: abc1234 "feat(trades): add batching layer" (3 hours ago)
   Activity:  Claude active (last tool: 4 min ago)
   PR:        none

2. <path>
   Branch:    yg/notifications-mvp
   Status:    clean
   Last commit: def5678 "feat(notifications): mark-read endpoint" (1 day ago)
   Activity:  idle (no session today)
   PR:        #58 open  https://github.com/.../pull/58

Cleanup candidates (clean + idle + merged PR): #2

Run /worktree-remove <slug> to clean up.
```

### 4. Highlight cleanup candidates

A worktree is a cleanup candidate if it meets ALL:
- Working copy is clean.
- No active Claude session (`session-state.json` missing or last_epoch > 24h ago).
- Associated PR is merged or closed (or there's no PR and no commits ahead of main).

Surface them at the bottom so the user knows what to garbage-collect.

## Notes

- This is the most useful command when you forget how many parallel things you've started. Run it at the start of a session.
- If `gh` isn't installed/authenticated, the PR column shows `(gh unavailable)`. Everything else still works.
