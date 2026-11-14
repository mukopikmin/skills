# Repository Instructions

## Skill Updates

- Whenever updating a skill, always read and apply [optimize-agent-docs](optimize-agent-docs/SKILL.md), including when updating that skill itself. Review the changed documentation before finishing.

## GitHub Access

- If `gh auth status` fails inside a sandbox, retry with network-enabled or escalated execution before concluding that the token is invalid or expired.
- If an authenticated `gh` session is unavailable, use GitHub MCP for repository and pull request operations when available.
- Treat Git remote authentication for operations such as `git push` independently from GitHub CLI authentication.
- Ask the user to authenticate or intervene only when neither `gh` nor GitHub MCP is available. Ask for re-authentication only after the retry confirms that the token is invalid or expired.
