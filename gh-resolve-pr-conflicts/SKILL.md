---
name: gh-resolve-pr-conflicts
description: Inspect all open GitHub pull requests in a target repository and resolve and push only confirmed merge conflicts with their base branches. Leave conflict-free PRs untouched to avoid unnecessary CI runs. Use when asked to find and fix conflicting PRs; use gh-update-open-prs instead when explicitly asked to refresh every PR regardless of conflicts.
---

# Resolve Pull Request Conflicts

Resolve actual merge conflicts in the open PRs that exist when the run begins. A PR being behind its base, failing CI, or waiting for review is not a reason to update it. A repeated run must leave already resolved PRs untouched.

## Scope And Safety

- Treat inspection-only requests as read-only. Merge, commit, and push only when the user asks to resolve conflicts.
- Never update a conflict-free PR: no base merge commit, rebase, empty commit, push, branch-update API call, CI rerun, or PR comment. Report results in the conversation.
- Do not merge or close PRs, change their labels or review state, or post comments as part of this skill.
- Never discard, stash, overwrite, or reformat changes in the user's existing worktree. Use an isolated temporary worktree for each conflicting PR.
- Never use `git reset --hard`, force push, rebase, or a blanket ours/theirs conflict strategy.
- Update only same-repository head branches that the authenticated user can push. Report forks, deleted heads, and insufficient permissions without creating replacement branches or PRs.
- Process PRs sequentially. Continue after a PR-specific failure; stop the run only when a shared prerequisite is unavailable.
- Preserve the original language of code and documentation. Use the user's language for progress and reports.

## 1. Establish Access And Snapshot

1. Read applicable `AGENTS.md` and repository instructions. Inspect `git status --short --branch` without changing the worktree.
2. Identify the explicitly requested repository, or the current Git repository when none was specified. Verify its base-repository identity and Git remote; do not assume `origin`. If the target cannot be identified unambiguously, ask for it before any writes.
3. Prefer authenticated `gh` for GitHub reads. If `gh auth status` fails inside a sandbox, retry with permitted network access before concluding that credentials are invalid. Use available GitHub MCP / connector tools when `gh` is unavailable, blocked, unauthenticated, missing scopes, or rate-limited. Treat Git remote authentication independently.
4. Fetch all pages of open PR metadata, including drafts. Capture PR number, URL, title, draft status, head/base repositories, branch names and SHAs, cross-repository status, and mergeability. Freeze the PR-number list and process it in ascending order; new PRs belong to the next run.
5. Prefer structured `gh pr list` / `gh pr view` output. Inspect supported JSON fields instead of guessing field names. Normalize connector results into the same snapshot shape and record the source of critical fallback reads.

GitHub MCP can supply PR metadata, diffs, checks, and logs where exposed. Local `git` must still perform fetches, merge checks, worktree creation, conflict resolution, commits, and pushes. If required metadata is unavailable from both sources, report the affected PR as undetermined rather than mutating it.

## 2. Gate Every Mutation On A Confirmed Conflict

1. Refresh the PR before processing. Skip a closed or merged PR.
2. Read GitHub's mergeability result:
   - `MERGEABLE` (or an explicit equivalent): report no conflict and do nothing further to the PR.
   - `CONFLICTING` (or an explicit equivalent): proceed to local confirmation.
   - `UNKNOWN`, null, or missing: retry read-only metadata retrieval up to three times with short delays of at most ten seconds. If still unknown, use a local merge check when exact head/base SHAs can be obtained; otherwise report undetermined.
3. Do not infer conflicts from `BEHIND`, `BLOCKED`, `UNSTABLE`, failed checks, pending reviews, or branch-protection requirements. These alone never authorize an update.
4. For a candidate needing local confirmation, check head ownership and push access. Fetch its current base and head into uniquely named temporary refs. Use `refs/pull/<number>/head` if needed, but push only to the verified head repository and branch, never to the pull ref.
5. Verify fetched SHAs against refreshed metadata. If either changed, refresh and retry the classification, at most three attempts per PR. Report ongoing concurrent updates rather than looping indefinitely.
6. Check the exact fetched commits with `git merge-tree --write-tree <head-sha> <base-sha>` when supported. Interpret exit status and output together: a clean merge means no action, actual unmerged entries confirm a conflict, and unrelated Git errors mean undetermined.
7. If that command is unavailable or cannot provide a reliable result, use an isolated temporary branch/worktree at the fetched head and `git merge --no-ff --no-commit <base-sha>`. A successful merge must be aborted without committing or pushing; report no conflict. A failure confirms conflicts only when unmerged paths exist. Abort and report other failures as errors.

Fetching refs and local merge simulation do not authorize remote writes. Even a PR initially reported as conflicting must be left untouched if the fetched commits merge cleanly. Remove temporary state safely after a clean check.

## 3. Resolve A Confirmed Conflict

1. Create a unique temporary worktree and branch at the verified head if the fallback check has not already done so. Use PR-number-qualified names and check for collisions. Never check out over the user's current branch.
2. Read repository validation instructions, contribution documentation, CI workflows, task runners, and manifests relevant to the PR.
3. Start `git merge --no-ff --no-commit <verified-base-sha>` in the temporary worktree. If it merges cleanly, abort it and report no conflict; create no commit.
4. List every unmerged path. Inspect the common ancestor, both sides of each conflict, nearby callers and tests, and relevant history. Integrate both changes according to their intended behavior.
5. Change tests and dependent code only where needed by the combined behavior. Separate conflict-resolution edits from changes introduced by the base merge itself.
6. If the conflict requires an unresolved product decision or incompatible contract, abort only the temporary merge and report the exact decision needed. Do not invent requirements.
7. Verify `git diff --name-only --diff-filter=U` is empty and inspect the full resolution diff for unintended changes or leftover conflict markers.

## 4. Validate The Resolution

1. Record the pre-update CI state for this conflicting PR before any push. There is no need to run local validation or monitor CI for conflict-free PRs.
2. Run repository-standard checks appropriate to the resolution: applicable formatting checks, lint, type checks, tests, and build checks. Start with focused checks, then run required broader validation according to repository instructions.
3. Prefer check-only formatting. Scope any required rewriting to relevant files and inspect generated changes.
4. Fix failures caused by the merge or resolution. Compare with the original head and base when needed to identify pre-existing failures; do not expand the task to unrelated repairs.
5. Inspect staged and unstaged changes. Commit and push only after required validation succeeds. If validation is blocked or fails, preserve useful diagnostic work when necessary and report the blocker without pushing an unverified resolution.

## 5. Recheck And Push Without Force

1. Immediately before committing and pushing, refresh PR state and fetch both head and base again.
2. If the PR was closed or merged, discard the temporary attempt safely and skip it.
3. If either SHA changed, abandon the stale attempt and restart at the conflict gate using the new head and base. Do not merge fresh remote changes into a stale resolution. If the new pair is conflict-free, discard the attempted resolution and do nothing remotely. Limit all concurrent-update restarts to three attempts per PR.
4. When the verified pair remains unchanged and validation passed, create a normal merge commit incorporating the base into the head. Preserve the standard merge message unless repository conventions specify otherwise.
5. Push using an explicit refspec to the exact PR head branch, without force. A non-fast-forward rejection requires restarting from current metadata and rechecking conflicts within the retry budget. For permissions or branch-policy rejection, stop that PR and report the server response.
6. Record the original head SHA, integrated base SHA, merge commit SHA, pushed SHA, conflict files, resolution edits, and validation results. Confirm the push result against the PR's remote head; report any concurrent subsequent update.

A check and push cannot be atomic with changes to a separate base branch. Record the exact base SHA resolved; if the base moves during the push, reclassify the latest pair and act again only on a newly confirmed conflict. Never create a follow-up commit solely to catch up a clean PR.

## 6. Monitor CI Only For Pushed Resolutions

1. Read checks and workflow runs for the exact pushed SHA using `gh` or connector fallbacks. Do not use manual CI dispatch or rerun commands.
2. Monitor checks to a terminal outcome or a concrete blocker. Report absent, pending, or running checks accurately; do not claim they passed. Follow repository policy for neutral or intentionally skipped checks.
3. Inspect failed logs and compare against the initial CI state. Fix only failures introduced by this merge or resolution, validate the focused fix, and push normally after checking for concurrent updates. Associate every result with the SHA actually checked.
4. If the remote head advanced, do not append fixes to the stale branch. Report the concurrent update and reclassify current conflicts before attempting further changes.
5. Report pre-existing failures, unavailable runners, cancelled runs, billing limits, and external-service failures without speculative edits or CI reruns.

## 7. Clean Up And Report

Remove only this run's temporary worktrees, branches, and refs when doing so cannot lose useful unresolved work. Never remove or modify the user's original worktree or pre-existing branches. Report preserved diagnostic paths.

Report every snapshot PR with its number, URL, head -> base, and one outcome:

- **Resolved and pushed**: original head, integrated base and pushed SHAs; conflict files; intentional resolution changes; validation and final CI outcome.
- **No conflict**: no commit, push, or CI trigger performed by this skill, even when the PR is behind its base.
- **Skipped**: closed/merged, fork, deleted head, or insufficient access, with the reason.
- **Undetermined / failed**: unavailable mergeability, fetch or merge-check errors, concurrent-update retry exhaustion, unresolved decisions, failed validation, or rejected pushes, with the next required action.

Include totals and disclose incomplete validation or CI. Record metadata sources when fallbacks were used. Do not claim this skill prevented CI triggered independently by other users or automation.
