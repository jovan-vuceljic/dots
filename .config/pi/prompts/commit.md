---
description: Write a Conventional Commits message for the staged changes
argument-hint: "[extra context]"
---
Inspect the staged changes with `git diff --cached` (and `git status` for context). Then write a single Conventional Commits message:

- A `<type>(<scope>): <subject>` summary line, imperative mood, ≤72 chars (types: feat, fix, refactor, docs, chore, test, perf, build).
- An optional short body explaining the *why* only when it isn't obvious from the diff.
- Do NOT run `git commit`. Output only the message inside a code block so I can review it.

Extra context to incorporate: ${1:-none}
