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
  session stays open**. **To stop it: press `Esc` while I'm idle between cycles** (that clears the
  queued wake-up); closing the session also stops it. A plain message does **not** cancel a pending
  wake-up — use `Esc`.
- **Every token counts.** Each wake-up re-reads the whole conversation with a cold prompt cache
  (the 10-min cadence outlives the 5-min cache TTL), so cost compounds with every cycle and every
  extra line in context. Therefore: fetch **filtered** data only (use the `--jq` filters below —
  never let raw unfiltered JSON into the conversation), summarize deltas rather than restating
  unchanged state, and keep idle cycles to **one cheap API call and ≤2 lines of output**.

Current state (auth + the current branch's PR):

!`echo "=== gh auth ==="; gh auth status 2>&1 | head -3; echo; echo "=== PR (current branch) ==="; gh pr view --json number,url,state,headRefName,baseRefName,headRefOid 2>/dev/null || echo "(no open PR for current branch — or gh not authed)"; echo; echo "=== repo ==="; gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null`

## Each cycle (one invocation / wake-up)

1. **Preflight.** If `gh auth status` failed above → **stop** and tell me to run `! gh auth login`,
   then re-run `/pr-loop`. Do nothing else. Capture `owner`/`repo` from `nameWithOwner`.

2. **Load state & resolve the PR.** Read `<git-dir>/pr-loop-state.json` (find `<git-dir>` with
   `git rev-parse --absolute-git-dir`). It's inside `.git/`, so it never shows in `git status` and
   survives wake-ups. Shape:
   ```json
   { "number": 0, "lastHeadOid": "", "lastSeenUpdatedAt": "", "handledThreadIds": [],
     "handledCommentIds": [], "awaitingPush": false, "idleCount": 0, "cycleCount": 0 }
   ```
   Resolve the target PR **in this order**: my argument if given (**$ARGUMENTS**) → the `number`
   in the state file (wake-ups re-invoke `/pr-loop` *without* arguments — the state file is the
   durable copy) → the current branch's PR from the context block. If none → **stop** and say so.
   If the state file is missing or for a different `number`, start fresh. Increment `cycleCount`.

   **Then print one status line before any network call** — so I always see the loop is alive:
   > 🔄 pr-loop cycle <N> — PR #<num>: checking…

3. **Cheap activity check — one API call, before any heavy fetch.**
   `gh pr view NUM --json headRefOid,updatedAt`
   - If `updatedAt == lastSeenUpdatedAt` **and** `headRefOid == lastHeadOid` → nothing happened at
     all (no comment, review, or push). This is an **idle cycle**: `idleCount += 1`; if a safety
     cap (step 5) is now exceeded, STOP per step 5. Otherwise save state and jump straight to
     step 10's reschedule. Total output ≤2 lines — if `awaitingPush`, one line is a brief
     commit-&-push reminder (remind at most twice across idle cycles, then just the status line).
   - Otherwise: remember the fetched `headRefOid` for step 6 and continue. (Don't update
     `lastSeenUpdatedAt` yet — step 10 refreshes it *after* you've posted replies, so your own
     replies don't defeat the next cycle's cheap check.)

4. **Fetch review state — filtered at the source, both calls in parallel** (one message, two
   tool calls). Never fetch unfiltered `reviews,comments`.

   Unresolved review threads (resolved/unresolved is GraphQL-only):
   ```bash
   gh api graphql --paginate -F owner=OWNER -F repo=REPO -F number=NUM -f query='
   query($owner:String!,$repo:String!,$number:Int!,$cursor:String){
     repository(owner:$owner,name:$repo){ pullRequest(number:$number){
       reviewThreads(first:100,after:$cursor){ pageInfo{hasNextPage endCursor}
         nodes{ id isResolved isOutdated
           comments(first:100){ nodes{ databaseId author{login} path line body } } } } } } }' \
     --jq '.data.repository.pullRequest.reviewThreads.nodes[]
           | select(.isResolved | not)
           | {id, isOutdated,
              comments: [.comments.nodes[] | {databaseId, author: .author.login, path, line, body}]}'
   ```

   Automated-reviewer activity + `@claude` requests from the PR conversation — latest review per
   bot (for the limit check in step 5) and only the relevant comments, not the whole history:
   ```bash
   gh pr view NUM --json reviews,comments --jq '{
     latestBotReviews: ([.reviews[] | select(.author.login | test("codex|claude"; "i"))]
       | group_by(.author.login) | map(max_by(.submittedAt))
       | map({author: .author.login, state, submittedAt, body})),
     relevantComments: ([.comments[] | select((.body | test("@claude"))
         or (.author.login | test("codex|claude"; "i")))
       | {id, author: .author.login, body}] | .[-10:])
   }'
   ```
   Act on feedback from **any** reviewer — especially the automated ones, **Codex and Claude**
   (`author.login` matching `codex`/`claude`, or a Bot account). Treat any comment — inline review
   **or** PR conversation — whose body **mentions `@claude`** as an explicit request to act on,
   same as a review comment.

5. **Check stop conditions — before doing any work:**
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
   - **Safety caps** (these apply on idle cycles too) → if `cycleCount > 20`, or `idleCount > 4`,
     or `gh api rate_limit --jq .resources.core.remaining` is `< 100` → STOP and hand back to me
     with a summary.

   **When any stop fires:** save state, do **not** call `ScheduleWakeup`, and end with a clear
   final line so I know the loop is over and won't run again — e.g.:
   > ✅ **Finished — no more active issues.** I won't re-check again.

   Adapt it to the reason: `✅ Finished — <reviewer> hit its usage limit; nothing left to address,
   I won't re-check again.` or `⏹ Stopped — hit safety cap (<which>); re-run \`/pr-loop\` to resume.`

6. **Did I push since last cycle?** Compare the `headRefOid` from step 3 to `lastHeadOid` (no
   extra API call).
   - If **unchanged and `awaitingPush` is true** → I haven't pushed yet. Don't re-fix anything for
     threads already handled: `idleCount += 1`, then continue with step 7 **only for genuinely new
     threads/comments** (something new must exist, or step 3 would have short-circuited).
   - If **changed** → I pushed. Set `awaitingPush=false`, `idleCount=0`, update `lastHeadOid`, and
     continue — including resolving threads whose fix is now live (step 8's resolve note).

7. **Triage** each unresolved review thread and every `@claude` request **not already handled**:
   - **Auto-handle (no input needed):** typos, lint/format, naming, missing null/error checks,
     applying the reviewer's concrete suggested diff, docs/comments, and small localized bugs with
     one obvious correct fix.
   - **Leave for me (needs input):** architecture/design decisions, security or performance
     trade-offs, ambiguous or broad requests, anything needing product/domain judgement. Never
     guess these — list them for me with the `path:line` and why.

   Apply the same split to Codex's and Claude's review suggestions and to every `@claude` request:
   a concrete ask is auto-handled; a judgement call is left for me. Skip anything whose id is
   already in `handledThreadIds` / `handledCommentIds`.

8. **Prepare the auto-handled set (no commit, no push):**
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
     **only** once its fix is live (a cycle where `headRefOid` advanced, per step 6) and the
     reviewer hasn't re-flagged it. Never resolve unpushed work or a "needs input" thread. This
     resolves the review *conversation*, not any linked GitHub Issue.

9. **Draft the commit message — exactly like `/commit-msg`:** from the staged diff and the repo's
   recent `git log` style (this repo uses `[Scope] summary`), write a message that matches. Then:
   - **(a) Print it** in your reply as a fenced ` ```text ` block — the durable copy.
   - **(b) Write it** to `<git-dir>/COMMIT_EDITMSG` with the Write tool (so I can `git commit -F` it).
   - **(c) Copy it:** `wl-copy < <git-dir>/COMMIT_EDITMSG`.
   - Tell me all three locations. **Never** run `git commit`.
   (Skip this step when nothing new was staged this cycle.)

10. **Ping + schedule.** Give me a tight summary — deltas only, don't restate unchanged threads:
    - fixed & staged this cycle: threads (with `path:line`);
    - left for you: threads + one-line reason each;
    - resolved on GitHub this cycle (if any);
    - the commit message (printed above), then "commit & push when ready".

    Refresh `lastSeenUpdatedAt` with one `gh pr view NUM --json updatedAt` call **after** your
    replies are posted (so your own activity doesn't defeat the next cheap check), then save state
    to `<git-dir>/pr-loop-state.json`. Then schedule:
    - **normal cycle:** `ScheduleWakeup(delaySeconds=600, prompt="/pr-loop", reason="recheck PR
      #<num> review comments")`;
    - **idle cycle** (step 3 short-circuited): back off — `delaySeconds=1200`, I'm clearly away;
      re-running `/pr-loop` checks immediately.

    End the turn with a sign-off that states when you'll run again and how to stop, e.g.:
    > ⏳ **Next check in ~10 min** (~20 when idle). To stop, press `Esc` while I'm idle between
    > cycles (or close the session).

    (When a stop condition in step 5 fired, skip both the wake-up and this sign-off — use the
    **Finished** line from step 5 instead.)

## Guardrails

- **Never** `git commit`, `git push`, `gh pr merge`, `gh pr create`, `gh pr close`, or `gh pr edit`
  — I do all of those. You stage, reply, resolve, and draft; nothing more.
- Act only on the target PR. Don't touch unrelated files or other PRs.
- **Keep context lean:** no raw JSON dumps in replies, no re-listing threads that haven't changed,
  idle cycles ≤2 lines. Every line you emit is re-read (uncached) on every later cycle.
- If anything is unclear or risky, leave it for me rather than guessing.
