---
description: Remove a finished worktree. Cleans the working tree directory and (optionally) the branch. Never deletes a worktree with uncommitted changes without explicit confirmation.
allowed-tools: Bash(git:*), Bash(ls:*), Bash(rm:*), Read
---

# /worktree-remove

Garbage-collect a worktree.

Worktree slug or path: $ARGUMENTS

## Your steps

### 1. Resolve the target

`$ARGUMENTS` is either:
- A slug (e.g., `refactor-trades-recon`) → resolves to `../<repo>-<slug>` and `yg/<slug>`.
- An absolute path to a worktree.

If empty, run `git worktree list` and ask the user which to remove.

### 2. Pre-flight checks

```bash
git -C "<path>" status --porcelain      # must be empty for safe remove
git -C "<path>" log <branch> ^origin/main --oneline    # commits not in origin?
```

If working tree is NOT clean OR there are commits not pushed to origin/main:
- **Stop and warn.** Show the user what's there.
- Ask for explicit confirmation with `--force` (the user passes it via $ARGUMENTS).
- Without `--force`, refuse — these are the kinds of mistakes that lose work.

### 3. Remove the worktree

```bash
git worktree remove "<path>"
```

(Use `--force` only if the user explicitly authorized it.)

### 4. Decide on the branch

The branch is NOT deleted by `git worktree remove`. Ask:

```
Branch <yg/slug> still exists. Delete it?
  - If the branch has been merged or you don't need it: yes, delete (`git branch -D <branch>`).
  - If you might want to revisit / re-attach later: no, keep it.
```

Wait for the user's answer. Default: keep the branch (safer).

### 5. Report

```
## Cleanup complete

Removed worktree: <path>
Branch <branch>: deleted | kept
```

## Safety rules

- **Never `git branch -D` without confirmation.** The branch may have unpushed commits.
- **Never remove a worktree with uncommitted changes without `--force`.** Surface what's there first; let the user decide.
- **Never operate on the main worktree.** `git worktree list` marks it; refuse if the resolved path is the main one.
- The deny list in `settings.json` already blocks `git branch -D` from raw Bash, so even with permission you'll need user approval. That's by design.
