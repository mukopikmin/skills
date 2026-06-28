---
name: gh-update-open-prs
description: Update every open GitHub pull request in the current repository by merging the latest version of each PR's base branch into its head branch, resolving conflicts with intent-aware edits, running repository-standard validation, pushing without force, monitoring CI, and reporting per-PR outcomes. Use when asked to refresh, synchronize, or bring all open PRs up to date with their base branches, including requests to resolve resulting conflicts or CI failures.
---

# Update Open Pull Requests

Update the open pull requests that exist when the run begins. Preserve contributor work, isolate each PR in a temporary worktree, and produce a result for every PR even when one PR fails.

## Safety Rules

- Never discard, stash, overwrite, or reformat changes in the user's existing worktree.
- Never use `git reset --hard`, force push, or mechanically choose one side of a conflict.
- Treat the repository hosting the PR's base branch as the base repository. Update only same-repository head branches that the authenticated user can push.
- Do not create replacement branches or PRs for forks or unpushable heads. Record them as failures with the missing permission or ownership constraint.
- Use a distinct temporary worktree and temporary local branch for each PR. Never check a PR branch out over the user's current branch.
- Process PRs sequentially so pushes, CI attribution, and failure reports remain unambiguous.
- Continue with the next PR after a PR-specific failure. Stop the whole run only when a shared prerequisite such as authentication or base-repository access is unavailable.
- Keep the original language of code and documentation. Use the user's language for progress updates and result reports, including the final report.

## 1. Establish The Run Snapshot

1. Confirm that the current directory belongs to a Git repository and inspect `git status --short --branch` without modifying it.
2. Identify the base repository and its Git remote. Do not assume the remote is named `origin` when repository metadata proves otherwise.
3. Confirm `gh auth status` and confirm access to the base repository before fetching or creating worktrees.
4. List all open PRs with structured `gh` output. Capture at least:
   - PR number, URL, title, and draft status
   - head repository, head branch, and head SHA
   - base repository, base branch, and base SHA
   - cross-repository status and maintainer modification setting
   - current check names, states, conclusions, and links
5. Freeze this list as the run snapshot and process it in PR-number order. Include draft PRs. PRs opened after the snapshot belong to a later run.
6. Record the initial CI state before changing any branch. Use check names and logs later to distinguish pre-existing failures from failures introduced by the merge.

Prefer `gh pr list --state open --json ...` for the initial set and `gh pr view <number> --json ...` when fields or current values need refreshing. Query available JSON fields with `gh ... --json` rather than guessing unsupported fields.

## 2. Prepare One PR

For each PR in the snapshot:

1. Refresh the PR metadata. If it was closed or merged, report it as skipped.
2. Reject a cross-repository head or any head that cannot be pushed by the authenticated user. Do not mutate it.
3. Fetch the current base branch and the PR head SHA into uniquely named temporary refs. Fetch the PR head through `refs/pull/<number>/head` when that is the reliable source of truth.
4. Verify that the fetched head SHA matches the refreshed PR metadata. Refresh and retry when it changed during preparation.
5. Create a unique directory with `mktemp -d` and attach a temporary branch and worktree at the fetched PR head.
6. Inspect repository instructions and validation entrypoints before editing. Check `AGENTS.md`, contributor documentation, CI workflows, task runners, and language manifests relevant to the changed files.

Use names containing the PR number for temporary refs, branches, and worktrees. Check for collisions instead of deleting an existing name that may belong to another process.

## 3. Merge The Latest Base

1. If the latest base SHA is already an ancestor of the PR head, do not create an empty merge. Record the PR as already current, then verify its current CI state.
2. Otherwise, run a non-fast-forward, no-commit merge of the fetched base into the isolated PR branch, equivalent to:

   ```bash
   git merge --no-ff --no-commit <fetched-base-ref>
   ```

3. If conflicts occur, list every unmerged path and inspect:
   - the base and PR versions of the complete conflicting region
   - nearby callers, types, tests, and documentation
   - relevant commit history when the intended evolution is unclear
4. Integrate both changes according to their behavior. Update tests and dependent code when the combined design requires it. Do not resolve all files with a blanket `--ours` or `--theirs` strategy.
5. Confirm that no unmerged paths remain with `git diff --name-only --diff-filter=U`.
6. Record whether conflicts occurred and which files were changed by the resolution, separately from files changed by the base merge itself.
7. If the conflict represents an unresolved product decision or incompatible contract, do not invent a specification. Abort only the temporary merge, clean up the temporary branch when safe, and report the exact decision required.

## 4. Validate Before Commit

1. Derive the repository's standard checks from its own documentation, CI configuration, and task definitions. Run the applicable formatting check, lint, type check, unit/integration tests, and build or compile check.
2. Prefer check-only formatter commands. If formatting must rewrite files, scope it to files involved in this PR or merge and inspect the resulting diff to avoid unrelated churn.
3. Run focused checks first when they shorten diagnosis, but run the repository's normal full validation before push when feasible.
4. Diagnose failures against the pre-merge PR state and the base branch:
   - Fix failures caused by combining the PR with the new base.
   - Do not expand the task to repair an unrelated failure that was already present on the PR head.
   - Record pre-existing failures with evidence, including the check or command and relevant log summary.
5. Inspect the staged and unstaged diff after validation. Ensure generated files or formatter output are intentional and no user work from the original worktree entered the temporary branch.

If validation cannot run because of missing credentials, unavailable services, or environment constraints, report the limitation. Do not claim success based only on partial checks.

## 5. Recheck, Commit, And Push

1. Immediately before committing, fetch and compare both the remote head and base again.
2. If the head advanced, do not force or merge stale local work into it. Abort the temporary attempt, recreate the worktree from the new head, and repeat the merge and validation.
3. If the base advanced, merge the new base SHA into the still-isolated branch and repeat all affected validation.
4. Create a normal merge commit only after the latest fetched base is integrated and validation succeeds. Preserve the standard Git merge message unless repository conventions require another message.
5. Push with an explicit refspec from the temporary branch to the PR's exact head branch. Never use `--force` or `--force-with-lease`.
6. If a normal push is rejected because the head advanced, fetch current metadata and restart that PR from the new head. If rejected for permission or policy, stop that PR and report the server response.
7. Record the integrated base SHA, merge commit SHA, pushed head SHA, conflict files, changed files, and validation commands.

## 6. Monitor And Attribute CI

1. Confirm that checks started for the pushed SHA. Use `gh pr checks` and Actions run metadata or logs as appropriate.
2. Monitor all checks until they reach terminal states. Treat success, neutral, and intentionally skipped checks according to repository policy; do not treat pending or queued checks as complete.
3. On failure, verify that the failing run belongs to the pushed SHA and inspect its failed logs.
4. Compare the check with the initial CI snapshot:
   - Fix failures introduced by the base merge or conflict resolution.
   - Re-run the relevant local validation, commit the focused fix, push normally, and monitor the new SHA again.
   - Report failures that clearly predate the merge instead of changing unrelated PR behavior.
5. Treat cancelled runs, unavailable runners, billing limits, and external-service failures as infrastructure outcomes unless logs show a code failure. Report them without speculative code changes.
6. Continue until the latest pushed SHA has completed CI or a concrete blocker has been identified. Do not report a running check as passed.

## 7. Clean Up

After each PR, remove the temporary worktree, local temporary branch, and temporary refs when doing so cannot discard unresolved diagnostic work. If cleanup is unsafe, preserve the path and name it in the report. Never remove the user's original worktree or branches.

## Final Report

Report every PR in the run snapshot and group the results into `Updated`, `Already current`, `Skipped`, `Failed`, and `Pending` when applicable. For each PR include:

- PR number and head branch -> base branch
- integrated base branch and exact base SHA
- initial and final CI state
- merge commit SHA, or why no commit was created
- whether conflicts occurred and the files involved
- intentional changed files beyond the base merge
- validation commands and outcomes
- push result
- remaining risk or required decision

For each failure, state the cause and the next required permission, specification decision, or infrastructure action. End with totals for all snapshot PRs and explicitly disclose any validation or CI that did not complete.
