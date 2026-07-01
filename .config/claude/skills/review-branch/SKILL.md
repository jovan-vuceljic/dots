---
description: Review all changes on the current branch (diff vs its base) for bugs, security issues, optimizations, and readability/scannability, then apply the readability + safe improvements after you approve. Use right before opening a PR.
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
2. **Gather context.** Read the full diff for that range (`git diff <merge-base>...HEAD`) and
   review **only the lines this branch changed** — not pre-existing code. Read surrounding code
   with the Read tool when you need it to judge a finding. Also read the repo's `CLAUDE.md` (root,
   and any in the directories the branch touched) and treat its guidance as a review lens.
3. **Find issues** across four lenses:
   - 🐞 **Correctness / bugs** — logic errors, unhandled edge cases, swallowed/ignored errors,
     race conditions, wrong/loose types, off-by-ones, and anything that violates the repo's
     `CLAUDE.md`.
   - 🔒 **Security** — injection (SQL / command / path traversal), missing input validation or
     output encoding, authn/authz gaps, secrets or credentials committed / logged / echoed,
     unsafe deserialization, SSRF, weak crypto or randomness, unsafe defaults, and sensitive data
     leaked in logs or error messages.
   - ⚡ **Optimizations** — redundant work, needless allocations/copies, N+1 patterns, a simpler
     or standard-library equivalent.
   - 📖 **Readability & scannability** — naming, structure, dead code, stale/misleading comments,
     formatting, over-long functions, unclear control flow.
4. **Verify the bugs and security findings before reporting.** Double-check each 🐞 and 🔒
   finding against the real code and keep only the ones you're confident are real and exploitable
   / will bite in practice. **Do not flag:**
   - issues on lines the branch didn't change (pre-existing);
   - theoretical vulnerabilities with no reachable exploit path in the changed code, or anything a
     SAST / dependency scanner would own;
   - anything a linter / type-checker / compiler / CI catches (imports, type errors, formatting) —
     assume those run separately;
   - pedantic nitpicks a senior engineer wouldn't raise, or "needs more tests/docs" unless the
     repo's `CLAUDE.md` requires it;
   - changes that are clearly intentional and part of the feature.

   (This filter is for 🐞 bugs and 🔒 security. ⚡ optimizations and 📖 readability are the
   deliberate polish pass — minor suggestions there are welcome, since the goal is PR-readiness.)
5. **Report**, grouped by the four lenses, most-severe-first, each finding one or two lines with
   a `path:line` reference so it's scannable. If a category is clean, say so in one line. No walls
   of text.
6. **Then stop and ask** whether to apply the fixes. On approval, apply **only** the readability
   improvements and behavior-preserving optimizations. Anything that changes behavior, public API,
   or semantics: list it separately and let me decide — do **not** apply it silently. Treat 🔒
   security fixes the same way: propose them, but never apply them silently. After editing, re-run
   the repo's formatter/linter if it has one.
7. **Never** run `git commit` or `git push` — I do that manually.
