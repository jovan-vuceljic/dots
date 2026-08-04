---
description: Draft a commit message for the staged changes, matching this repo's commit style, then print it in the reply, save it to the repo's CLAUDE_COMMIT_MSG file, and copy it to the clipboard. Never stages or commits. Use once you've staged what you want to commit.
argument-hint: [optional focus/scope hint]
disable-model-invocation: true
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(git rev-parse:*), Bash(wl-copy:*), Read, Glob, Write
---

# Draft a commit message for the staged changes

Context for the current commit — what's staged, plus this repo's recent style:

!`echo "=== Staged (git diff --cached --stat) ==="; git --no-pager diff --cached --stat 2>/dev/null; echo; echo "=== Working tree (git status --short) ==="; git --no-pager status --short 2>/dev/null; echo; echo "=== Recent subjects — match this convention ==="; git --no-pager log -20 --pretty=format:'%s' 2>/dev/null`

## What to do

1. **See exactly what's being committed.** Read the full staged diff with
   `git --no-pager diff --cached`. If nothing is staged (the stat above is empty), tell me and
   **stop** — I stage changes myself; never run `git add`.
2. **Learn the repo's commit style** from the recent subjects above — prefix convention (this repo
   uses `[Scope] summary`), imperative vs. past tense, subject length, whether bodies are used.
   Match what's already there; don't impose Conventional Commits / gitmoji if the repo doesn't use
   them.
3. **Write the message from the *actual* staged diff** (not a guess):
   - A concise subject in the repo's style (~50 chars, imperative). Fold in my hint if given:
     **$ARGUMENTS**.
   - Add a short body (wrapped ~72 cols) only when the change needs the *why*; otherwise
     subject-only. Don't invent motivation that isn't evident from the diff.
4. **Print the message in your reply first** — as a single fenced ` ```text ` block, copy-paste
   ready. This in-reply copy is the durable one: it lives in the transcript, so it survives even if
   the clipboard gets overwritten later (by me copying something else, or another Claude session
   running `wl-copy`). Always print it; don't rely on the clipboard alone.
5. **Save it to a file in the repo** so I can recover it any time: resolve the path with
   `git rev-parse --git-path CLAUDE_COMMIT_MSG` (per-worktree correct), then use the Write tool to
   write the raw message there — **not** `COMMIT_EDITMSG`, which git overwrites on every
   `git commit` before the editor opens. My `prepare-commit-msg` hook prefills the commit editor
   from `CLAUDE_COMMIT_MSG` (one-shot) on the next `git commit` / lazygit `C`. The file lives
   inside the git dir so it never shows up in `git status`.
6. **Also copy it to the clipboard** as a convenience: `wl-copy < <path from step 5>`. Then
   tell me all three places it is: **printed above**, **saved to `CLAUDE_COMMIT_MSG`** (hook
   prefills the next commit), and **on the clipboard** — so I never lose it to a stray copy.
7. **Never** run `git add`, `git commit`, or `git push`, and never offer to — I stage and commit
   manually. Draft only.
