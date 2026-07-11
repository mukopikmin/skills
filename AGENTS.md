# Repository Instructions

## Tool Usage

- Do not immediately conclude that a GitHub token is invalid when `gh auth status` fails inside a sandbox. Retry `gh auth status` with network-enabled or escalated execution.
- Ask the user to re-authenticate only when the retry confirms that the token is invalid or expired.
- If an authenticated `gh` session is unavailable but GitHub MCP is available, use GitHub MCP for repository and pull request operations.
- Treat Git remote authentication for operations such as `git push` independently from GitHub CLI authentication.
- Ask the user to authenticate or intervene only when neither `gh` nor GitHub MCP is available.
