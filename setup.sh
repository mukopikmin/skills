#!/usr/bin/env sh
set -eu

case "$0" in
  */*) script_path=$0 ;;
  *)
    if [ -f "$0" ]; then
      script_path=./$0
    else
      script_path=$(command -v -- "$0")
    fi
    ;;
esac

script_dir=$(CDPATH= cd -- "$(dirname -- "$script_path")" && pwd -P)
cd "$script_dir"

skills_root=".agents/skills"
mkdir -p "$skills_root"

created=0
unchanged=0

for skill_md in ./*/SKILL.md; do
  [ -e "$skill_md" ] || continue

  skill_dir=${skill_md%/SKILL.md}
  skill_name=${skill_dir#./}
  link_path="$skills_root/$skill_name"
  target="../../$skill_name"

  if [ -L "$link_path" ]; then
    current_target=$(readlink "$link_path")
    if [ "$current_target" = "$target" ]; then
      unchanged=$((unchanged + 1))
      continue
    fi

    printf 'error: %s already points to %s, expected %s\n' "$link_path" "$current_target" "$target" >&2
    exit 1
  fi

  if [ -e "$link_path" ]; then
    printf 'error: %s already exists and is not a symlink\n' "$link_path" >&2
    exit 1
  fi

  ln -s "$target" "$link_path"
  created=$((created + 1))
done

printf 'Codex skill links ready: %s created, %s unchanged\n' "$created" "$unchanged"
