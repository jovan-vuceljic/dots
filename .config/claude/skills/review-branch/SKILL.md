---
description: Review all changes on the current branch (diff vs its base) for bugs, optimizations, and readability/scannability, then apply the readability + safe improvements after you approve. Use right before opening a PR.
argument-hint: [base-branch]
disable-model-invocation: true
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(git merge-base:*), Bash(git symbolic-ref:*), Bash(git rev-parse:*), Bash(git show-ref:*), Bash(git branch:*), Read, Grep, Glob
---

# Review this branch

Context auto-collected for the current branch vs. its base:

!`b=$(git symbolic-ref --short -q refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@'); [ -z "$b" ] && { git show-ref -q --verify refs/heads/main && b=main || b=master; }; m=$(git merge-base "$b" HEAD 2>/dev/null); echo "Current branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null)"; echo "Base branch:    $b"; echo "Diff range:     ${m:-?}..HEAD"; echo; echo "Commits:"; git --no-pager log --oneline "${m}..HEAD" 2>/dev/null; echo; echo "Files changed:"; git --no-pager diff --stat "${m}...HEAD" 2>/dev/null`

## What to do

1. **Resolve the base branch.** If a base branch was passed when invoking (it appears here:
   **$ARGUMENTS** — empty if none), use that. Otherwise use the base detected above. The changes
   to review are the diff `git merge-base <base> HEAD`..`HEAD`.
2. **Read the full diff** for that range (`git diff <merge-base>...HEAD`) and review **only those
   changes** — not the rest of the repo. Use the Read tool on the surrounding code whenever you
   need context to judge a finding.
3. **Report findings**, grouped and most-severe-first, each as one or two lines with a
   `path:line` reference so it's scannable:
   - 🐞 **Correctness / bugs** — logic errors, unhandled edge cases, missing error handling,
     race conditions, wrong/loose types, off-by-ones.
   - ⚡ **Optimizations** — redundant work, needless allocations/copies, N+1 patterns, a simpler
     or standard-library equivalent.
   - 📖 **Readability & scannability** — naming, structure, dead code, stale comments, formatting,
     over-long functions, unclear control flow.

   If a category is clean, say so in one line. No walls of text.
4. **Then stop and ask** whether to apply the fixes. On approval, apply **only** the readability
   improvements and behavior-preserving optimizations. Anything that changes behavior, public API,
   or semantics: list it separately and let me decide — do **not** apply it silently. After
   editing, re-run the repo's formatter/linter if it has one.
5. **Never** run `git commit` or `git push` — I do that manually.
