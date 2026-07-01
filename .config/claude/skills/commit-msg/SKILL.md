---
description: Draft a commit message for the staged changes, matching this repo's commit style, then print it and copy it to the clipboard. Never stages or commits. Use once you've staged what you want to commit.
argument-hint: [optional focus/scope hint]
disable-model-invocation: true
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git status:*), Bash(wl-copy:*), Read, Glob, Write
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
4. **Output** the message as a single fenced ` ```text ` block, copy-paste ready.
5. **Copy it to the clipboard**: write the message to a file in your scratchpad directory with the
   Write tool, then run `wl-copy < <that file>`. Tell me it's on the clipboard.
6. **Never** run `git add`, `git commit`, or `git push`, and never offer to — I stage and commit
   manually. Draft only.
