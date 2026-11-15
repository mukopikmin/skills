# Repository Instructions

## Skill Updates

- Whenever updating a skill, always read and apply [optimize-agent-docs](optimize-agent-docs/SKILL.md), including when updating that skill itself. Review the changed documentation before finishing.

## Package Versions

- Before finishing a PR, review changes against its latest base branch and update the affected `apm.yml` versions in the same PR.
- Version each skill independently: start new skills at `1.0.0`; bump an existing skill for changes to its distributed instructions or interface metadata. Use PATCH for compatible corrections or clarifications, MINOR for compatible capabilities, and MAJOR for incompatible behavior or requirements. README-only or repository-maintenance changes do not require a package bump.
- Version the root bundle when its package metadata or dependency set changes: use MINOR for added skills, MAJOR for removed or replaced skills, and PATCH for compatible metadata corrections. Skill-content changes alone do not require a root bump when the bundle definition is unchanged.
- Choose one resulting version per affected package for the whole PR relative to the latest base; do not increment again for every follow-up commit. Re-evaluate after base updates, and report changed package versions and the reason in the PR description.

## GitHub Access

- If `gh auth status` fails inside a sandbox, retry with network-enabled or escalated execution before concluding that the token is invalid or expired.
- If an authenticated `gh` session is unavailable, use GitHub MCP for repository and pull request operations when available.
- Treat Git remote authentication for operations such as `git push` independently from GitHub CLI authentication.
- Ask the user to authenticate or intervene only when neither `gh` nor GitHub MCP is available. Ask for re-authentication only after the retry confirms that the token is invalid or expired.
