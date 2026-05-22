---
description: Run /ship in a git worktree sandbox. The orchestrator chain executes in an isolated working copy. If everything passes, promotes via PR; if anything fails, the worktree stays for inspection. Use for risky refactors, big migrations, or experiments you want to be able to throw away cleanly.
allowed-tools: Read, Write, Grep, Glob, Bash(git:*), Bash(gh:*), Bash(mkdir:*), Bash(rm:*), Agent
---

# /ship-sandbox

Like `/ship`, but in a git worktree. The change never touches your current working copy until it's green and you promote it.

Task: $ARGUMENTS

## When to use

- **Risky refactor** — big surface area, unclear blast radius. Sandbox the experiment.
- **Migration / data change** — schema changes you want to dry-run.
- **Speculative spike** — "could we?" exploration that you might throw away.
- **Concurrent work** — you're mid-task; want the agent to do something else without disturbing your unstaged changes.

For normal work, use `/ship`. Sandboxing has overhead.

## Your steps

### 1. Verify clean enough state

Doesn't have to be fully clean — the user can keep working in the main worktree. But warn if there are conflicting paths likely to overlap.

```bash
git rev-parse --git-dir   # confirm we're in a repo
git fetch origin           # so the worktree branches from up-to-date origin
```

### 2. Generate a task ID and create the worktree

```bash
task_id="<short-slug-from-task>"   # or Linear ID if provided
date_slug="$(date +%Y%m%d)"
branch="yg/sandbox-${date_slug}-${task_id}"
worktree_dir="../$(basename "$(pwd)")-sandbox-${date_slug}-${task_id}"

git worktree add "$worktree_dir" -b "$branch" origin/main
```

Tell the user the paths so they can inspect later regardless of how the run ends.

### 3. Run the orchestrator chain inside the worktree

Hand off to the orchestrator with one critical addition to its environment:
- `CLAUDE_PROJECT_DIR` is set to the worktree path.
- All hooks (require-knowledge, secret-scan, design-reviewer, etc.) operate against the worktree.
- `.claude/tasks/<task_id>/` lives in the worktree.

The full normal chain runs: plan (with devil-advocate critique) → user approves → KB updates → implementer → security + compliance + design gates → code review → tests → commit.

### 4. Decide promotion

After the chain completes — successfully or not:

**If everything green (all gates approved, tests pass, commit landed in the worktree branch):**

```
## Sandbox passed

Worktree: <path>
Branch: <branch>
Commit: <sha + message>
Test/typecheck/lint: pass
Security/compliance/design: APPROVED

Promote? (y/n)
  y → git push -u origin <branch>; gh pr create ...; report PR URL
  n → leave the worktree intact; report path so the user can inspect / discard
```

**If anything failed:**

```
## Sandbox failed

Worktree: <path>
Branch: <branch>
Failure: <what stopped — e.g., "security-reviewer BLOCKED on PII egress at lib/notify.ts:34">
Last successful step: <step>

The worktree is left intact for inspection. To inspect:
  cd <worktree_path>
  git log --oneline
  git diff main..HEAD

To discard:
  git worktree remove <worktree_path>
  git branch -D <branch>
```

Do not auto-discard on failure. The user might want to dig in.

### 5. Cleanup (after promotion or explicit discard)

On user "y" (promote) OR explicit "discard":

```bash
git worktree remove "$worktree_dir"
# Don't delete the branch — it's now in origin (if promoted) or kept for posterity.
```

## Notes

- **Cost:** worktrees are cheap (no full clone — shared `.git` directory). One extra disk path; nothing more.
- **Concurrent sessions:** you can keep working in the main worktree while the sandbox runs. The runtime watchdog still watches the sandbox session.
- **`.claude/tasks/<task_id>/`** lives in the worktree, gitignored by default. Use the scratchpad to keep notes about what to do if you decide to retry.
- **Naming:** `yg/sandbox-YYYYMMDD-<task>` keeps sandbox branches distinct from regular feature branches. The cleanup step doesn't delete the branch (you may want it for reference).

## Example

```
You: /ship-sandbox "rewrite the trades reconciliation job using batching"

Agent: Creating worktree...
  Path: ../stock-navigator-sandbox-20260521-trades-recon
  Branch: yg/sandbox-20260521-trades-recon
  Branched from origin/main (rev abc1234).

Now running orchestrator chain inside the worktree.

[plan + devil-advocate critique shown]

You: go

Agent: [implementer + gates + tests run in the worktree]
  ...
  Sandbox passed.
  All gates APPROVED. Tests pass. Commit landed in sandbox.
  Promote? (y/n)

You: y

Agent: Pushed yg/sandbox-20260521-trades-recon to origin.
  PR opened: https://github.com/Yasel-Garces/stock-navigator/pull/72
  Worktree removed.
```
