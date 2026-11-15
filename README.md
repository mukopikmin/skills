# Skills

Portable agent skills. See [apm.yml](apm.yml) for available packages and each skill directory's `SKILL.md` for usage.

Each skill directory is its single source of truth: `SKILL.md` contains portable instructions and `agents/openai.yaml` provides optional OpenAI interface metadata. Other compatible agents can use the instructions without that metadata.

## Install with APM

Install all skills through the dependencies in [apm.yml](apm.yml):

```sh
apm install mukopikmin/skills
```

To install only one skill, append the target skill directory name:

```sh
apm install mukopikmin/skills/setup-dependabot
```

Each installed skill includes its `SKILL.md` and `agents/openai.yaml`; the root package does not duplicate them. For either installation method, update from the installation target:

```sh
apm update
```

## Install with symbolic links

Run [setup.sh](setup.sh) to link every skill without APM:

```sh
./setup.sh
```

The script links each original skill directory at `.agents/skills/<skill>` in the repository and `~/.agents/skills/<skill>` for the user. It refuses to overwrite regular files or links pointing elsewhere. Update linked skills with `git pull` in this repository. Use APM to install a single skill.
