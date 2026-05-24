---
description: Create a new git worktree for parallel feature development. Each worktree gets its own branch + independent working copy. You can then open a separate Claude Code session there and run /ship without interfering with the main worktree. Distinct from /ship-sandbox, which runs a single task end-to-end in a worktree; this just creates the worktree.
allowed-tools: Bash(git:*), Bash(ls:*), Bash(pwd:*), Read
---

# /worktree-new

Create a parallel worktree so two `/ship` runs can happen at the same time without interfering.

Description / feature name: $ARGUMENTS

## Why this exists

The main worktree (your current repo path) is one workspace. If you start `/ship "feature A"` here, you can't simultaneously run `/ship "feature B"` because both would touch the same working copy. **Worktrees** are git's native solution: multiple independent working copies of the same repository, each on its own branch, sharing the same `.git/` directly underneath.

Workflow:

```
your-repo/                    ← worktree 1 (main; you start here)
  → /ship "feature A"

your-repo-feature-b/          ← worktree 2 (created by /worktree-new)
  → open Claude Code there
  → /ship "feature B"

both run in parallel · two PRs · zero conflict
```

Distinct from `/ship-sandbox` which uses a worktree for *risky-change isolation* of a single task. This command creates a worktree as a *long-lived parallel workspace* you'll keep working in.

## Your steps

### 1. Verify we're in a git repo

```bash
git rev-parse --git-dir >/dev/null 2>&1 || exit  # not a repo → error
```

### 2. Generate a slug for the worktree

From `$ARGUMENTS`, produce a short kebab-case slug. E.g., "Refactor the trades reconciliation" → `refactor-trades-recon`. If empty, ask the user for a name.

### 3. Compute paths

```bash
repo_name="$(basename "$(pwd)")"
slug="<slug from step 2>"
worktree_path="../${repo_name}-${slug}"
branch="yg/${slug}"
```

### 4. Create the worktree

```bash
git fetch origin --quiet
git worktree add "$worktree_path" -b "$branch" origin/main
```

Fail clearly if the branch already exists (the user may want to reuse it — offer `git worktree add "$worktree_path" "$branch"` without `-b` to attach to existing).

### 5. Report

```
## Worktree created

Path:    <absolute path>
Branch:  <branch>
Based on: origin/main (rev <sha>)

To start working in it:

  cd "<absolute path>"
  claude                              # opens Claude Code there

Then in that session:
  /ship "your task"                   # uses the new worktree

To list all worktrees later:    /worktrees
To clean up when done:          /worktree-remove <slug>
```

## Tips

- **Naming:** the slug becomes both the directory suffix and the branch name. Keep it short and unique.
- **KB and config:** the worktree shares `.git/` but has its own working copy. `.claude/knowledge/*` will be present (committed); `.claude/logs/*` and `.claude/tasks/*` are gitignored and start empty in the new worktree.
- **Concurrent /ship runs:** each worktree has its own `.claude/logs/session-state.json`, so watchdogs / scratchpads / token tracking are scoped per-worktree. They don't cross-contaminate.
- **Cost:** worktrees are cheap — no extra clone, just an extra working tree pointing at the same `.git/`.
- **`/ship-sandbox` vs `/worktree-new`:** `/ship-sandbox` is for "run *this one task* in isolation, promote on green, throw away on red." `/worktree-new` is for "give me a parallel workspace I'll work in for a while."
