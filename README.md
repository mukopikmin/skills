# Skills

This repository distributes four agent skills:

- `gh-update-open-prs`
- `gh-resolve-pr-conflicts`
- `setup-dependabot`
- `audit-test-suite`

`gh-update-open-prs` updates every open PR with its latest base branch. `gh-resolve-pr-conflicts` resolves and pushes only confirmed conflicts, leaving conflict-free PRs untouched to avoid unnecessary CI runs.

Each skill directory is its single source of truth. The root `apm.yml` bundles the four independent APM packages as dependencies without copying their skill files.

The skills are not limited to Codex. `SKILL.md` contains the portable skill instructions, while `agents/openai.yaml` provides optional OpenAI-specific interface metadata. A compatible agent can use the skill instructions without consuming that metadata.

## Install all skills with APM

```sh
apm install mukopikmin/skills
```

The root package installs all four skills through its dependencies. For each skill, the installed payload consists of `<skill>/SKILL.md` and `<skill>/agents/openai.yaml`. The root package does not contain duplicate skill files.

To update the installed packages, run the following command from the installation target:

```sh
apm update
```

## Install one skill with APM

Use the required skill's subdirectory as the package path. For example, install only the Dependabot skill with:

```sh
apm install mukopikmin/skills/setup-dependabot
```

The other package paths are `mukopikmin/skills/gh-update-open-prs`, `mukopikmin/skills/gh-resolve-pr-conflicts`, and `mukopikmin/skills/audit-test-suite`. An individual installation places only the selected skill's `SKILL.md` and `agents/openai.yaml`; it does not install the other skills. Use `apm update` to update an individual installation as well.

## Existing `setup.sh`

The existing script remains unchanged as the legacy way to set up every skill without APM. Running it links all skills in the repository:

```sh
./setup.sh
```

For each skill, the script creates symbolic links at `.agents/skills/<skill>` in the repository and `~/.agents/skills/<skill>` for the user. Both links point to the original skill directory. Because no files are copied, update the linked skills by running `git pull` in this repository. The script does not overwrite regular files or existing links that point elsewhere. For an individual installation, use the APM method above rather than this script.
