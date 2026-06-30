---
description: Draft a ready-to-paste PR description by filling this repo's GitHub PR template from the branch diff and commits, then copy it to the clipboard. Use after finishing a feature.
argument-hint: [base-branch]
disable-model-invocation: true
allowed-tools: Bash(git diff:*), Bash(git log:*), Bash(git merge-base:*), Bash(git symbolic-ref:*), Bash(git rev-parse:*), Bash(git show-ref:*), Bash(ls:*), Bash(cat:*), Bash(wl-copy), Read, Glob
---

# Draft this branch's PR description

This repo's PR template (first match), plus the branch's changes:

!`for f in .github/pull_request_template.md .github/PULL_REQUEST_TEMPLATE.md docs/pull_request_template.md docs/PULL_REQUEST_TEMPLATE.md PULL_REQUEST_TEMPLATE.md pull_request_template.md; do if [ -f "$f" ]; then echo "=== PR template: $f ==="; cat "$f"; found=1; break; fi; done; if [ -z "$found" ]; then if [ -d .github/PULL_REQUEST_TEMPLATE ]; then echo "=== template dir .github/PULL_REQUEST_TEMPLATE/ (pick one) ==="; ls .github/PULL_REQUEST_TEMPLATE/; else echo "(no PR template found — use the fallback structure)"; fi; fi`

!`b=$(git symbolic-ref --short -q refs/remotes/origin/HEAD 2>/dev/null | sed 's@^origin/@@'); [ -z "$b" ] && { git show-ref -q --verify refs/heads/main && b=main || b=master; }; m=$(git merge-base "$b" HEAD 2>/dev/null); echo "Branch: $(git rev-parse --abbrev-ref HEAD 2>/dev/null)  Base: $b  Range: ${m:-?}..HEAD"; echo; echo "Commits:"; git --no-pager log --oneline "${m}..HEAD" 2>/dev/null; echo; echo "Files changed:"; git --no-pager diff --stat "${m}...HEAD" 2>/dev/null`

## What to do

1. **Resolve the base branch** (use the invocation argument if given — **$ARGUMENTS** — else the
   detected base) and read the full diff + commit messages for `merge-base..HEAD`.
2. **Fill the PR template shown above** from the *actual* changes:
   - Write the Summary / motivation and any "Implementation Notes" from the diff and commits.
   - Tick the **Type of Change** boxes that genuinely match (feature / fix / refactor / perf /
     tests / docs / chore).
   - Tick `Self-reviewed` and `LLM-assisted` if those boxes exist.
   - **Leave verification boxes unchecked** — e.g. "tests passed", "`validate:full` passes",
     "pre-commit hooks passed". I confirm those myself; never tick them for me.
   - Fill **Related Issues** from issue numbers in the branch name or commit trailers; otherwise
     keep the template's placeholder lines.
   - If a multi-template dir was listed (no single file), pick the most fitting one and say which.
   - **If no template exists**, use this fallback: `## Summary` / `## Changes` / `## Testing` /
     `## Notes`.
3. **Output** the filled description as a single fenced ```markdown code block, copy-paste ready.
4. **Copy it to the clipboard**: write the same markdown to a temp file (`mktemp`) and run
   `wl-copy < "$tmpfile"`, then remove the temp file. Tell me it's on the clipboard.
5. **Do not** create, push, or edit the PR (`gh pr ...`) — I add the text to the PR myself.
