---
description: Review the current diff for bugs and issues
argument-hint: "[focus area]"
---
Review the current changes. Check both `git diff` (unstaged) and `git diff --cached` (staged). Focus on:

- Correctness and logic bugs
- Error handling and missing edge cases
- Security issues (injection, secrets, unsafe input)
- Anything that doesn't match the surrounding code's conventions

List concrete findings as `file:line — issue — suggested fix`, ordered by severity. Be concise; skip praise. If nothing is wrong, say so.

Extra focus this round: ${1:-general correctness}
