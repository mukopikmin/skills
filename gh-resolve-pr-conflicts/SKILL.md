---
name: gh-resolve-pr-conflicts
description: Inspect open GitHub pull requests and resolve merge conflicts or persistent GitHub CONFLICTING results, validate, push without force, and verify GitHub mergeability and CI. Leave confirmed conflict-free PRs untouched. Use when asked to find and fix conflicting PRs; use gh-update-open-prs when asked to refresh every PR regardless of conflicts.
---

# Resolve Pull Request Conflicts

Resolve conflicts in the open PRs that exist when the run begins, including cases where GitHub reports `CONFLICTING` but a local merge check is clean. Being behind base, failing CI, or waiting for review alone never justifies an update. A repeated run must leave confirmed conflict-free PRs untouched.

## Scope And Safety

- Treat inspection-only requests as read-only. Merge, commit, and push only when the user asks to resolve conflicts.
- Never update a confirmed conflict-free PR: no base merge commit, rebase, empty commit, push, branch-update API call, CI rerun, or PR comment. A clean local check does **not** establish this outcome while GitHub reports `CONFLICTING` or mergeability remains undetermined. The narrowly scoped base-integration exception is in section 3.
- Do not merge or close PRs, change their labels or review state, or post comments. Report results in the conversation.
- Never discard, stash, overwrite, or reformat changes in the user's existing worktree. Use an isolated temporary worktree for each PR needing a real merge.
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

GitHub MCP can supply PR metadata, branch information, diffs, checks, and logs where exposed. Local `git` must still perform fetches, merge checks, worktree creation, conflict resolution, commits, and pushes. If required metadata is unavailable from both sources, report the affected PR as undetermined rather than mutating it.

## 2. Establish Current SHAs And Reconcile Mergeability

1. Refresh the PR before processing. Skip a closed or merged PR. Record GitHub mergeability separately from local results; never overwrite one with the other.
2. An explicit `MERGEABLE` result permits a read-only no-conflict outcome when there is no contradictory evidence. Do not infer conflicts from `BEHIND`, `BLOCKED`, `UNSTABLE`, failed checks, pending reviews, or branch protection. These alone never authorize an update.
3. For `CONFLICTING`, `UNKNOWN`, null, missing, or contradictory results, establish the exact current commits. Record each SHA with its source and observation time:
   - PR metadata head SHA and base SHA, with repository and branch names.
   - Current remote head and base branch tips from `git ls-remote <verified-remote> refs/heads/<branch>` or GitHub branch information. Query the appropriate repository for each branch.
   - Fetched head and base SHAs. Fetch into uniquely named temporary refs; use `refs/pull/<number>/head` if needed, but never push to a pull ref.
4. Use the **current base branch tip**, not the PR metadata base SHA, for local checks and merges. If they differ, explicitly report both values and their sources. A metadata base mismatch alone is not proof of a concurrent branch update and must not cause repeated checks against the stale SHA. If branch-tip sources disagree, or the fetched head does not match PR metadata and the remote head, refresh and refetch until the pair is consistent. Never choose an arbitrary SHA.
5. Run `git merge-tree --write-tree --name-only <head-sha> <current-base-sha>` on the verified commits. Capture its exit code, stdout, and stderr without a pipeline masking the status. Check both the exit code and the unmerged-path section of the output; the initial tree SHA and informational messages are not unmerged paths. Use `-z` and a NUL-aware parser when paths require it. This simulation does not populate the current index, so `git diff --diff-filter=U` in the user's worktree cannot confirm its result.
   - Exit 0 **and** no unmerged paths means locally clean.
   - Exit 1 with unmerged paths confirms local conflicts.
   - Other errors, inconsistent status/output, or unsupported options are undetermined; use the isolated real merge in section 3 if safe, rather than interpreting the error as clean.
6. When GitHub and local results disagree, refresh GitHub mergeability and reverify both branch tips. For unknown results, retry read-only retrieval up to three times with delays of at most ten seconds. Limit concurrent-update restarts to three attempts per PR as well. Retain the evidence from each attempt.
7. Classify the verified pair:
   - GitHub explicitly mergeable and locally clean, or mergeable without contradictory evidence: **No conflict**, no writes.
   - Local conflicts: proceed to section 3, recording any GitHub disagreement.
   - GitHub still `CONFLICTING` with a clean or inconclusive local check: proceed to section 3. Never terminate as no conflict.
   - GitHub still unknown and locally clean: **Undetermined**, no writes. Unknown alone does not authorize a base update.

Fetching and merge simulation do not authorize remote writes. Check head ownership and push access before preparing an update. Inspection-only runs report the discrepancy and any local findings without committing or pushing.

## 3. Resolve Conflicts Or Persistent GitHub Disagreement

1. Create a unique temporary branch/worktree at the verified PR head. Use PR-number-qualified names and check for collisions. Never check out over the user's current branch. Read repository validation instructions, contribution documentation, CI workflows, task runners, and relevant manifests. Record pre-update CI before changing the branch.
2. Check `git merge-base --is-ancestor <current-base-sha> <head-sha>` and distinguish exit 0 (included), 1 (not included), and errors. If base is already included but GitHub remains `CONFLICTING`, do not manufacture an empty commit. Recheck refs and GitHub; if the disagreement persists, report it as unresolved with the evidence.
3. If base is not included, run in the temporary worktree:

   ```bash
   git merge --no-ff --no-commit <current-base-sha>
   ```

   Record the exit code and unmerged paths using `git diff --name-only --diff-filter=U` (or `git ls-files -u`). A failed merge without unmerged entries is an error to diagnose, not proof of conflicts. Do not commit after an unrelated merge failure.
4. If there are conflicts, inspect the common ancestor, both sides of each conflict, nearby callers and tests, and relevant history. Integrate both changes according to their intended behavior. Change tests and dependent code only where needed; distinguish resolution edits from changes introduced by base.
5. If the real merge is clean, refresh GitHub and both tips before deciding:
   - When GitHub still reports `CONFLICTING`, the verified head lacks current base, and the user requested conflict resolution, keep the merge and create a **normal base-integration merge commit** after validation. This is authorized even when `merge-tree` and the real merge found no conflicts. Report that distinction explicitly.
   - If GitHub is now mergeable, abort the temporary merge and leave the PR untouched. If GitHub is unknown, report undetermined without pushing. Mere base lag never authorizes this exception.
6. If either tip changed, restart classification using section 5. If a conflict requires an unresolved product decision or incompatible contract, abort only the temporary merge and report the exact decision needed. Do not invent requirements.
7. Before validation, verify no unmerged paths remain and inspect the full diff for unintended changes or leftover conflict markers.

## 4. Validate The Merge

1. Apply these checks to both conflict resolutions and clean base-integration merges. Confirmed conflict-free PRs need no local validation or CI monitoring.
2. Run repository-standard checks appropriate to the combined changes: applicable formatting checks, lint, type checks, tests, and build checks. Start with focused checks, then run required broader validation according to repository instructions.
3. Prefer check-only formatting. Scope required rewriting to relevant files and inspect generated changes.
4. Fix failures caused by the merge or resolution. Compare with the original head and base to identify pre-existing failures; do not expand the task to unrelated repairs.
5. Inspect staged and unstaged changes. Commit and push only after required validation succeeds. If validation is blocked or fails, preserve useful diagnostic work when necessary and report the blocker without pushing an unverified merge.

## 5. Recheck And Push Without Force

1. Immediately before committing, and again immediately before pushing, refresh PR state, GitHub mergeability, and current head/base branch tips; fetch and verify them as in section 2. Compare remote head with the original verified head, not the local merge commit. Record metadata base discrepancies separately.
2. If closed or merged, discard the temporary attempt safely and skip it. If either actual branch tip changed, abandon the stale attempt and restart classification at section 2 on the new pair. Do not merge fresh remote changes into a stale resolution. Limit concurrent-update restarts to three attempts per PR.
3. If reclassification confirms no conflict, discard the attempt and do nothing remotely. A clean local result with persistent GitHub `CONFLICTING` must instead follow section 3's exception. If a clean base-integration attempt no longer has an explicit GitHub `CONFLICTING` result, do not push it.
4. When the verified pair remains unchanged and validation passed, create a normal merge commit incorporating current base into head. Preserve the standard merge message unless repository conventions specify otherwise. Never create an empty commit to provoke recalculation.
5. Push using an explicit refspec to the exact PR head branch, without force. A non-fast-forward rejection requires restarting from current metadata within the retry budget. For permissions or branch-policy rejection, stop that PR and report the server response.
6. Record original head, metadata base, integrated current base, merge commit, and pushed SHAs; conflict files; resolution edits; validation results. Confirm the push against the remote PR head and report any subsequent concurrent update.

The base check and head push cannot be atomic. If base moves during push, reclassify the latest pair. Never create a follow-up commit solely to catch up a confirmed clean PR; persistent GitHub `CONFLICTING` still requires section 3 or an explicit unresolved outcome.

## 6. Verify GitHub And Monitor CI For Every Push

1. After each push, refresh GitHub mergeability for the **pushed head and current base**, recording both SHAs. Retry transient unknown or stale results up to three times with short delays of at most ten seconds. Do not use an older head's mergeability as proof of success.
2. If GitHub still reports `CONFLICTING`, reverify branch tips and return to classification within the retry budget. If the pushed head already includes current base, or reliable reads or safe updates are impossible, report the discrepancy as **unresolved**, never resolved because the local merge was clean. Persistently unknown results also prevent a resolved outcome. Continue monitoring CI for the pushed SHA even when mergeability remains unresolved, unless access or infrastructure blocks monitoring.
3. Read checks, statuses, and workflow runs for the exact pushed SHA using `gh` or connector fallbacks. Include PR merge-test runs when attributable to this head/base pair. Do not manually dispatch or rerun CI.
4. Monitor all applicable post-push CI until terminal states, even if mergeability is already clear. Check for delayed check registration; an initially empty list is not a pass. Record explicitly when no CI is configured or triggered. Pending, queued, or running checks are incomplete; a monitoring limit or unavailable service is a concrete blocker, not success. Follow repository policy for neutral or intentionally skipped checks.
5. Inspect failed logs and compare against initial CI. Fix only failures introduced by the merge, validate, recheck current head/base before committing and pushing normally, then repeat mergeability and CI verification for the new SHA. If head advanced, do not append fixes to the stale branch; reclassify first.
6. Report pre-existing failures, unavailable runners, cancelled runs, billing limits, and external-service failures without speculative edits or CI reruns. Do not label terminal failures as passing.
7. Recheck current head/base and GitHub mergeability after CI completes. Complete the resolution only when GitHub explicitly confirms the conflict is gone for the verified current pair and CI has a recorded terminal outcome (or confirmed absence). Separate remaining review, policy, or CI blockers from merge conflicts and disclose failures; do not claim the PR is ready to merge unless those requirements also pass.

## 7. Clean Up And Report

Remove only this run's temporary worktrees, branches, and refs when doing so cannot lose useful unresolved work. Never remove or modify the user's original worktree or pre-existing branches. Report preserved diagnostic paths.

Report every snapshot PR with its number, URL, head -> base, and one outcome:

- **Resolved and pushed**: actual conflict resolution or clean base integration; original head, metadata base, integrated base and pushed SHAs; conflict files and intentional edits; validation; final GitHub mergeability and terminal CI outcomes.
- **No conflict**: explicit GitHub mergeability, any local evidence, and confirmation that no commit, push, or CI trigger was performed, even if behind base. Never use this outcome for a persistent disagreement or unknown result.
- **Skipped**: closed/merged, fork, deleted head, or insufficient access, with the reason. An inaccessible `CONFLICTING` PR remains unresolved.
- **Unresolved / undetermined / failed**: state GitHub's remaining result, the checks attempted (metadata, branch tips, fetched SHAs, merge-tree exit code and paths, real merge if attempted), mismatched SHAs and sources, and the exact cause preventing safe determination or update. Include failed validation, rejected pushes, retry exhaustion, incomplete CI, and the next required action as applicable.

Include totals, metadata sources, SHA discrepancies, and incomplete validation or CI. A locally clean result alone never completes a task while GitHub still reports `CONFLICTING`. Do not claim this skill prevented CI triggered independently by other users or automation.
