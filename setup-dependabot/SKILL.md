---
name: setup-dependabot
description: Configure, update, or audit Dependabot for the current GitHub repository by detecting supported package ecosystems and update roots, creating or preserving `.github/dependabot.yml`, adding the required GitHub labels, validating the result, and reporting Dependabot security settings and CI risks. Use when asked to add, set up, configure, update, review, or audit Dependabot, dependency update automation, or Dependabot pull request grouping.
---

# Set Up Dependabot

## Safety And Scope

- Reviews, explanations, and audits are read-only. A request to set up, add, configure, or update Dependabot authorizes the Dependabot file and creation of its missing labels. Preserve existing labels and unrelated edits.
- Commit, push, open a PR, edit workflows, or change security settings only on separate request.
- If GitHub is unavailable, continue local work within the requested scope and report remote state as unknown. Apply the label rules below.
- Consult GitHub's current official [supported ecosystems](https://docs.github.com/en/code-security/reference/supply-chain-security/supported-ecosystems-and-repositories) and [options reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference) instead of relying on a stale ecosystem list.

## 1. Inspect The Repository

1. Confirm the current directory belongs to a Git repository and inspect `git status --short --branch` without disturbing user changes.
2. Read applicable `AGENTS.md` files and repository contribution instructions.
3. Enumerate Git-tracked manifests, lockfiles, runtime version declarations, workspace definitions, and `.github/workflows/*.yml` or `.yaml`. Exclude dependency caches, vendored trees, build output, and generated files.
4. Read any existing `.github/dependabot.yml` or `.yaml` in full. Record its ecosystems, directories, target branches, registries, schedules, cooldowns, groups, labels, limits, and allow/ignore rules.
5. Verify the GitHub repo from remote metadata without assuming `origin`. Continue locally if no GitHub remote can be verified.

## 2. Select Ecosystems And Update Roots

- Match manifests and tool versions to package ecosystems that GitHub currently supports. Do not add an ecosystem merely because a language appears in the repository.
- Treat a directory as an update root when it owns a manifest or lockfile Dependabot can update. For workspaces sharing a root lockfile, prefer the workspace root; include a nested directory when it has an independently managed manifest or lockfile.
- Use a repository-root-relative path beginning with `/`. Use `directory` for one update root and `directories` for multiple roots of the same ecosystem.
- Add `github-actions` with `directory: "/"` when tracked workflows or a root action manifest uses remotely versioned actions. Local actions alone do not require an update entry.
- Check ecosystem-specific constraints in the official documentation. For example, only select `deno` when repository evidence is compatible with a supported Deno version and a supported Deno manifest exists.
- Do not create a configuration when no supported update root exists. Report the evidence and the missing prerequisite instead.

## 3. Build Or Update The Configuration

Store the configuration at `.github/dependabot.yml`. For a new ecosystem entry, use this policy unless repository instructions or the user's request require another value:

```yaml
version: 2
updates:
  - package-ecosystem: "<ecosystem>"
    directory: "/<update-root>"
    schedule:
      interval: "weekly"
    cooldown:
      default-days: 7
    labels:
      - "dependencies"
      - "<ecosystem>"
    groups:
      <ecosystem>-security-updates:
        applies-to: "security-updates"
        patterns:
          - "*"
      <ecosystem>-dependencies:
        applies-to: "version-updates"
        patterns:
          - "*"
    open-pull-requests-limit: 5
```

Derive stable group identifiers from the ecosystem, as in the template.

When updating an existing configuration:

- Preserve intentional schedules, registries, target branches, commit-message settings, reviewers, assignees, allow/ignore rules, versioning strategies, cooldown tiers, and pull-request limits.
- Add missing supported ecosystems or update roots without overlapping directories for the same ecosystem and target branch.
- Add separate catch-all version and security groups only where they do not conflict with more specific existing groups. Because group order determines the first match, retain specific groups before catch-all groups.
- Do not generalize repository-specific ignores. Add a new ignore only when compatibility evidence in the repository or the user's request requires it.
- Preserve `.yaml` when that is the existing filename; never leave both `.yml` and `.yaml` active.

## 4. Ensure Required Labels

Before finalizing YAML, resolve `dependencies` and the exact ecosystem label for each entry.

1. Verify authentication and repository access. Retry sandboxed `gh auth status` with network access or escalation before diagnosing invalid credentials. If `gh` is unavailable, use the GitHub connector for supported reads or label operations.
2. List repository labels and match case-insensitively. Use the existing spelling in YAML and retain color and description.
3. For missing labels, create `dependencies` with color `0366d6` and description `Pull requests that update dependencies`. Use `1d76db` and `Dependency updates for <ecosystem>` for ecosystem labels. Never force/update labels. If another process creates one first, refresh the list and confirm it.
4. Include only confirmed labels. On access or creation failure, omit that label and report the exact failure. If none are confirmed for an entry, omit its `labels` key to allow Dependabot defaults.

## 5. Inspect GitHub Settings And CI Risks

Read but do not change these repository settings:

- Check vulnerability alerts with `GET /repos/{owner}/{repo}/vulnerability-alerts`; distinguish enabled from disabled only when access is sufficient.
- Check Dependabot security updates with `GET /repos/{owner}/{repo}/automated-security-fixes`; report `enabled`, `paused`, `disabled`, or `unknown` from the response and verified permissions.
- Treat `404` as unknown rather than disabled when repository access or required administration-read permission cannot be established.

Inspect Dependabot PR workflows for unconditional secret use, notifications lacking secret checks, elevated permissions, and assumptions about PR secret access. Cite file and line for each risk.

## 6. Validate

1. Parse the YAML with existing repository tooling or another already-available YAML parser. Do not install a dependency solely for validation.
2. Verify `version: 2`, required keys, current ecosystem names, valid `directory` versus `directories` usage, non-overlapping update roots, unique group identifiers, and paths backed by detected manifests.
3. Confirm each configured label exists remotely and that catch-all groups do not shadow intended specific groups.
4. Inspect the focused diff and confirm only the Dependabot file and intentionally created remote labels changed.
5. Run the repository's existing YAML formatting or lint check when it covers `.github/dependabot.yml`. Do not run a formatter that rewrites unrelated files.

Do not claim GitHub has accepted the configuration merely because local YAML parsing succeeds. State the validation boundary explicitly.

## Final Report

- created or updated configuration path
- detected ecosystems and update roots, with the manifest evidence for each
- preserved custom policy and applied defaults
- existing and newly created labels, plus any omitted label and reason
- vulnerability-alert and security-update states, including permission uncertainty
- CI risks with file locations
- validation commands and results
- any unsupported manifest, unverified GitHub state, or follow-up action
