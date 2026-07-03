---
description: Babysit the current branch's PR — address review comments that don't need my input, re-check every ~10 min, and stop when there are no open comments left or the automated reviewers (Codex, Claude) hit their limit. Prep-only — stages fixes and drafts the commit message; never commits, pushes, or merges.
argument-hint: [pr number or url — optional; defaults to the current branch's PR]
disable-model-invocation: true
allowed-tools: Bash(gh:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git rev-parse:*), Bash(git fetch:*), Bash(git add:*), Bash(wl-copy:*), Read, Edit, Write, Grep, Glob, ScheduleWakeup
---

# Watch this PR and resolve review comments (prep-only)

A self-paced loop over one PR's review feedback: fix the comments that don't need my judgement,
stage them, draft a commit message, then wait ~10 min and re-check — until there are no unresolved
comments left or the automated reviewers (Codex/Claude) hit a usage limit.

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
   { "number": 0, "lastHeadOid": "", "handledThreadIds": [], "handledCommentIds": [],
     "awaitingPush": false, "idleCount": 0, "cycleCount": 0 }
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
   for the automated reviewers' latest activity **and the PR conversation**. Act on feedback from
   **any** reviewer — especially the automated ones, **Codex and Claude** (`author.login` matching
   `codex`/`claude`, or a Bot account). And treat any comment — inline review **or** PR
   conversation — whose body **mentions `@claude`** as an explicit request to act on, same as a
   review comment.

4. **Check stop conditions — before doing any work:**
   - **No unresolved threads** → the PR is clean. Report that it's done, save state, and **do not**
     schedule another wake-up. STOP.
   - **The automated reviewers are spent** → an automated reviewer's most recent review/comment
     body matches a limit signal (case-insensitive: `rate/usage/quota/credit … limit`,
     `limit reached`, `exceeded … quota`, `out of … credits`). Automated reviewers = authors whose
     `login` matches `codex` or `claude` (or a `[bot]` that leaves review comments; confirm with
     `gh api users/<login> --jq .type` → `Bot`). STOP and report which reviewer hit the limit
     **only** when no unresolved threads (incl. `@claude` requests) remain that you can still act
     on. If one reviewer is limited but other threads still need work, handle those first, then
     re-check.
   - **Safety caps** → if `cycleCount > 20`, or `idleCount > 6`, or
     `gh api rate_limit --jq .resources.core.remaining` is `< 100` → STOP and hand back to me with
     a summary.

5. **Did I push since last cycle?** Compare the current remote `headRefOid` to `lastHeadOid`.
   - If **unchanged and `awaitingPush` is true** → I haven't pushed yet. Don't re-fix anything:
     `idleCount += 1`, remind me once (briefly) to commit & push, save state, and go to step 8.
   - If **changed** → I pushed. Set `awaitingPush=false`, update `lastHeadOid`, and continue —
     including resolving threads whose fix is now live (step 7's resolve note).

6. **Triage** each unresolved review thread and every `@claude` request **not already handled**:
   - **Auto-handle (no input needed):** typos, lint/format, naming, missing null/error checks,
     applying the reviewer's concrete suggested diff, docs/comments, and small localized bugs with
     one obvious correct fix.
   - **Leave for me (needs input):** architecture/design decisions, security or performance
     trade-offs, ambiguous or broad requests, anything needing product/domain judgement. Never
     guess these — list them for me with the `path:line` and why.

   Apply the same split to Codex's and Claude's review suggestions and to every `@claude` request:
   a concrete ask is auto-handled; a judgement call is left for me. Skip anything whose id is
   already in `handledThreadIds` / `handledCommentIds`.

7. **Prepare the auto-handled set (no commit, no push):**
   - Apply the edits (the PostToolUse format hook auto-formats). `git add` the changed files.
   - Post a short reply on each thread you addressed:
     ```bash
     gh api --method POST repos/{owner}/{repo}/pulls/NUM/comments/COMMENT_DATABASEID/replies \
       -f body="Addressed — fix staged, pending push."
     ```
     For a plain PR **conversation** comment (e.g. an `@claude` request, not an inline review
     thread), reply with `gh pr comment NUM --body "…"` instead of the replies endpoint.
   - Add handled review-thread ids to `handledThreadIds` and handled conversation/`@claude`
     comment ids to `handledCommentIds`; set `awaitingPush=true`.
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
