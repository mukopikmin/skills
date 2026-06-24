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
user_skills_root="${HOME:?HOME is not set}/.agents/skills"

created=0
unchanged=0

ensure_link() {
  link_path=$1
  target=$2

  mkdir -p "$(dirname -- "$link_path")"

  if [ -L "$link_path" ]; then
    current_target=$(readlink "$link_path")
    if [ "$current_target" = "$target" ]; then
      unchanged=$((unchanged + 1))
      return
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
}

for skill_md in ./*/SKILL.md; do
  [ -e "$skill_md" ] || continue

  skill_dir=${skill_md%/SKILL.md}
  skill_name=${skill_dir#./}

  ensure_link "$skills_root/$skill_name" "../../$skill_name"
  ensure_link "$user_skills_root/$skill_name" "$script_dir/$skill_name"
done

printf 'Codex skill links ready: %s created, %s unchanged\n' "$created" "$unchanged"
