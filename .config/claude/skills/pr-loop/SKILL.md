---
description: Babysit the current branch's PR — address review comments that don't need my input, re-check every ~10 min, and stop when there are no open comments left or the Codex reviewer hits its limit. Prep-only — stages fixes and drafts the commit message; never commits, pushes, or merges.
argument-hint: [pr number or url — optional; defaults to the current branch's PR]
disable-model-invocation: true
allowed-tools: Bash(gh:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git rev-parse:*), Bash(git fetch:*), Bash(git add:*), Bash(wl-copy:*), Read, Edit, Write, Grep, Glob, ScheduleWakeup
---

# Watch this PR and resolve review comments (prep-only)

A self-paced loop over one PR's review feedback: fix the comments that don't need my judgement,
stage them, draft a commit message, then wait ~10 min and re-check — until there are no unresolved
comments left or the Codex reviewer hits a usage limit.

**The contract — read this first:**
- **I never commit, push, or merge.** Each cycle you *prepare*: edit + `git add` + draft a commit
  message + reply on the threads you handled. Then you **ping me to commit & push**, and the loop
  resumes after I do. This honours the global no-commit/no-push rule; nothing in `settings.json`
  changes.
- The 10-minute cadence uses `ScheduleWakeup`, so the loop only advances **while this Claude
  session stays open**. If I close it, the loop stops.

Current state (auth + the current branch's PR):

!`echo "=== gh auth ==="; gh auth status 2>&1 | head -3; echo; echo "=== PR (current branch) ==="; gh pr view --json number,url,state,headRefName,baseRefName,headRefOid 2>/dev/null || echo "(no open PR for current branch — or gh not authed)"; echo; echo "=== repo ==="; gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null`

## Each cycle (one invocation / wake-up)

1. **Preflight.**
   - If `gh auth status` failed above → **stop** and tell me to run `! gh auth login`, then re-run
     `/pr-loop`. Do nothing else.
   - Resolve the target PR: use my argument if given (**$ARGUMENTS**), else the current branch's PR
     from the context block. If there's no open PR → **stop** and say so.
   - Capture `owner`, `repo` (from `nameWithOwner`), `number`, and the remote `headRefOid`.

2. **Load state.** Read `<git-dir>/pr-loop-state.json` (find `<git-dir>` with
   `git rev-parse --absolute-git-dir`). It's inside `.git/`, so it never shows in `git status` and
   survives wake-ups. Shape:
   ```json
   { "number": 0, "lastHeadOid": "", "handledThreadIds": [], "awaitingPush": false,
     "idleCount": 0, "cycleCount": 0 }
   ```
   If it's missing or for a different `number`, start fresh. Increment `cycleCount`.

3. **Fetch unresolved review threads** (resolved/unresolved is GraphQL-only):
   ```bash
   gh api graphql --paginate -F owner=OWNER -F repo=REPO -F number=NUM -f query='
   query($owner:String!,$repo:String!,$number:Int!,$cursor:String){
     repository(owner:$owner,name:$repo){ pullRequest(number:$number){
       reviewThreads(first:100,after:$cursor){ pageInfo{hasNextPage endCursor}
         nodes{ id isResolved isOutdated
           comments(first:100){ nodes{ databaseId author{login} path line body } } } } } } }'
   ```
   Keep only threads with `isResolved == false`. Also grab `gh pr view NUM --json reviews,comments`
   to see the Codex reviewer's latest activity.

4. **Check stop conditions — before doing any work:**
   - **No unresolved threads** → the PR is clean. Report that it's done, save state, and **do not**
     schedule another wake-up. STOP.
   - **Codex hit a limit** → the Codex reviewer's most recent review/comment body matches a limit
     signal (case-insensitive: `rate/usage/quota/credit … limit`, `limit reached`,
     `exceeded … quota`, `out of … credits`). Identify the Codex reviewer as a comment/review
     author whose `login` matches `codex` (or a `[bot]` that leaves review comments; confirm with
     `gh api users/<login> --jq .type` → `Bot`). If matched → STOP and report the limit. Do not
     schedule.
   - **Safety caps** → if `cycleCount > 20`, or `idleCount > 6`, or
     `gh api rate_limit --jq .resources.core.remaining` is `< 100` → STOP and hand back to me with
     a summary.

5. **Did I push since last cycle?** Compare the current remote `headRefOid` to `lastHeadOid`.
   - If **unchanged and `awaitingPush` is true** → I haven't pushed yet. Don't re-fix anything:
     `idleCount += 1`, remind me once (briefly) to commit & push, save state, and go to step 8.
   - If **changed** → I pushed. Set `awaitingPush=false`, update `lastHeadOid`, and continue —
     including resolving threads whose fix is now live (step 7's resolve note).

6. **Triage** each unresolved thread **not already in `handledThreadIds`**:
   - **Auto-handle (no input needed):** typos, lint/format, naming, missing null/error checks,
     applying the reviewer's concrete suggested diff, docs/comments, and small localized bugs with
     one obvious correct fix.
   - **Leave for me (needs input):** architecture/design decisions, security or performance
     trade-offs, ambiguous or broad requests, anything needing product/domain judgement. Never
     guess these — list them for me with the `path:line` and why.

7. **Prepare the auto-handled set (no commit, no push):**
   - Apply the edits (the PostToolUse format hook auto-formats). `git add` the changed files.
   - Post a short reply on each thread you addressed:
     ```bash
     gh api --method POST repos/{owner}/{repo}/pulls/NUM/comments/COMMENT_DATABASEID/replies \
       -f body="Addressed — fix staged, pending push."
     ```
   - Add those thread ids to `handledThreadIds`; set `awaitingPush=true`.
   - **Resolve** a thread — `gh api graphql -f query='mutation($id:ID!){
     resolveReviewThread(input:{threadId:$id}){ thread{ id isResolved } } }' -F id=THREAD_ID` —
     **only** once its fix is live (a cycle where `headRefOid` advanced, per step 5) and the
     reviewer hasn't re-flagged it. Never resolve unpushed work or a "needs input" thread. This
     resolves the review *conversation*, not any linked GitHub Issue.

8. **Draft the commit message — exactly like `/commit-msg`:** from the staged diff and the repo's
   recent `git log` style (this repo uses `[Scope] summary`), write a message that matches. Then:
   - **(a) Print it** in your reply as a fenced ` ```text ` block — the durable copy.
   - **(b) Write it** to `<git-dir>/COMMIT_EDITMSG` with the Write tool (so I can `git commit -F` it).
   - **(c) Copy it:** `wl-copy < <git-dir>/COMMIT_EDITMSG`.
   - Tell me all three locations. **Never** run `git commit`.

9. **Ping + schedule.** Give me a tight summary:
   - fixed & staged: threads (with `path:line`);
   - left for you: threads + one-line reason each;
   - resolved on GitHub this cycle (if any);
   - the commit message (printed above) and "commit & push when ready — I'll recheck in ~10 min."

   Save state to `<git-dir>/pr-loop-state.json`. Then call
   `ScheduleWakeup(delaySeconds=600, prompt="/pr-loop", reason="recheck PR #<num> review comments")`
   and end the turn. (Omit the wake-up only when a stop condition in step 4 fired.)

## Guardrails

- **Never** `git commit`, `git push`, `gh pr merge`, `gh pr create`, `gh pr close`, or `gh pr edit`
  — I do all of those. You stage, reply, resolve, and draft; nothing more.
- Act only on the target PR. Don't touch unrelated files or other PRs.
- If anything is unclear or risky, leave it for me rather than guessing.
