---
name: setup-dependabot
description: Configure, update, or audit Dependabot for the current GitHub repository by detecting supported package ecosystems and update roots, creating or preserving `.github/dependabot.yml`, adding the required GitHub labels, validating the result, and reporting Dependabot security settings and CI risks. Use when asked to add, set up, configure, update, review, or audit Dependabot, dependency update automation, or Dependabot pull request grouping.
---

# Set Up Dependabot

Inspect the repository before choosing ecosystems or directories. Preserve intentional policy, keep unrelated files unchanged, and distinguish repository-file changes from GitHub settings.

## Safety And Scope

- Treat review, explanation, and audit requests as read-only. Create or update files and labels only when the user asks to set up, configure, add, or update Dependabot.
- Preserve unrelated working-tree changes. Do not commit, push, open a pull request, change workflows, or enable or disable repository security settings unless the user separately requests it.
- Limit GitHub writes in the normal setup workflow to creating missing labels referenced by the generated configuration. Never delete or rewrite existing labels.
- Continue local inspection and YAML work when GitHub access is unavailable. Report remote state as unknown and omit labels that could not be confirmed or created.
- Consult GitHub's current official [supported ecosystems](https://docs.github.com/en/code-security/reference/supply-chain-security/supported-ecosystems-and-repositories) and [options reference](https://docs.github.com/en/code-security/reference/supply-chain-security/dependabot-options-reference) instead of relying on a stale ecosystem list.

## 1. Inspect The Repository

1. Confirm the current directory belongs to a Git repository and inspect `git status --short --branch` without disturbing user changes.
2. Read applicable `AGENTS.md` files and repository contribution instructions.
3. Enumerate Git-tracked manifests, lockfiles, runtime version declarations, workspace definitions, and `.github/workflows/*.yml` or `.yaml`. Exclude dependency caches, vendored trees, build output, and generated files.
4. Read any existing `.github/dependabot.yml` or `.yaml` completely. Record its ecosystems, directories, target branches, registries, schedules, cooldowns, groups, labels, limits, and allow/ignore rules.
5. Identify the GitHub repository from verified remote metadata. Do not assume the remote is named `origin`. Keep local configuration possible when no GitHub remote can be established.

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

Replace `directory` with `directories` when the ecosystem has multiple update roots. Use stable group identifiers derived from the ecosystem value, such as `github-actions-security-updates` and `github-actions-dependencies`.

When updating an existing configuration:

- Preserve intentional schedules, registries, target branches, commit-message settings, reviewers, assignees, allow/ignore rules, versioning strategies, cooldown tiers, and pull-request limits.
- Add missing supported ecosystems or update roots without overlapping directories for the same ecosystem and target branch.
- Add separate catch-all version and security groups only where they do not conflict with more specific existing groups. Because group order determines the first match, retain specific groups before catch-all groups.
- Do not generalize repository-specific ignores. Add a new ignore only when compatibility evidence in the repository or the user's request requires it.
- Preserve `.yaml` when that is the existing filename; never leave both `.yml` and `.yaml` active.

## 4. Ensure Required Labels

Use `dependencies` plus one label for each configured `package-ecosystem`, using the exact ecosystem value such as `npm`, `deno`, or `github-actions`.

1. Confirm GitHub authentication and repository access. If `gh auth status` fails inside a sandbox, retry with network-enabled or escalated execution before treating the credentials as invalid. Use the available GitHub connector for repository reads or label operations when `gh` is unavailable and the connector exposes the required capability.
2. List repository labels and compare names case-insensitively. When a matching label exists, preserve its actual spelling, color, and description and reference that spelling in the YAML.
3. Create only missing labels:
   - `dependencies`: color `0366d6`, description `Pull requests that update dependencies`
   - ecosystem label: color `1d76db`, description `Dependency updates for <ecosystem>`
4. Do not use a force/update option when creating labels. If creation reports that a concurrent creator already added the label, refresh the label list and use the confirmed label.
5. Reference only labels confirmed to exist. If access or creation fails, omit the missing label from the entry and report the exact failure. If no label can be confirmed, omit the `labels` key so Dependabot can apply its default label behavior.

Create labels before finalizing the YAML so the file never intentionally references a nonexistent label.

## 5. Inspect GitHub Settings And CI Risks

Read but do not change these repository settings:

- Check vulnerability alerts with `GET /repos/{owner}/{repo}/vulnerability-alerts`; distinguish enabled from disabled only when access is sufficient.
- Check Dependabot security updates with `GET /repos/{owner}/{repo}/automated-security-fixes`; report `enabled`, `paused`, `disabled`, or `unknown` from the response and verified permissions.
- Treat `404` as unknown rather than disabled when repository access or required administration-read permission cannot be established.

Inspect workflows for behavior likely to break or create noise on Dependabot pull requests, including unconditional secret use, notifications that run without checking secret availability, elevated permissions, and assumptions that every pull request has access to repository secrets. Report file and line evidence. Do not edit workflows as part of ordinary Dependabot setup.

## 6. Validate

1. Parse the YAML with existing repository tooling or another already-available YAML parser. Do not install a dependency solely for validation.
2. Verify `version: 2`, required keys, current ecosystem names, valid `directory` versus `directories` usage, non-overlapping update roots, unique group identifiers, and paths backed by detected manifests.
3. Confirm each configured label exists remotely and that catch-all groups do not shadow intended specific groups.
4. Inspect the focused diff and confirm only the Dependabot file and intentionally created remote labels changed.
5. Run the repository's existing YAML formatting or lint check when it covers `.github/dependabot.yml`. Do not run a formatter that rewrites unrelated files.

Do not claim GitHub has accepted the configuration merely because local YAML parsing succeeds. State the validation boundary explicitly.

## Final Report

Report:

- created or updated configuration path
- detected ecosystems and update roots, with the manifest evidence for each
- preserved custom policy and applied defaults
- existing and newly created labels, plus any omitted label and reason
- vulnerability-alert and security-update states, including permission uncertainty
- CI risks with file locations
- validation commands and results
- any unsupported manifest, unverified GitHub state, or follow-up action
