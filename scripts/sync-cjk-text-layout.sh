#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_url="${CJK_LAYOUT_SKILLS_REPO_URL:-${CJK_LAYOUT_SKILL_REPO_URL:-https://github.com/sichengchen/cjk-layout-skills.git}}"
source_ref="${CJK_LAYOUT_SKILLS_REF:-${CJK_LAYOUT_SKILL_REF:-main}}"
target_skills_root="$repo_root/plugins/cjk-text-layout/skills"
tmp_root="${TMPDIR:-/tmp}"
workdir="$(mktemp -d "$tmp_root/cjk-text-layout-sync.XXXXXX")"

cleanup() {
  rm -rf "$workdir"
}
trap cleanup EXIT

checkout="$workdir/cjk-layout-skills"

git clone --depth 1 --branch "$source_ref" "$source_url" "$checkout"

sync_skill() {
  local skill_name="$1"
  local source_skill="$checkout/$skill_name"
  local target_skill="$target_skills_root/$skill_name"

  if [[ ! -f "$source_skill/SKILL.md" ]]; then
    cat >&2 <<EOF
Unable to find $skill_name skill source in cloned repository.
Source URL: $source_url
Source ref: $source_ref
Expected: $source_skill/SKILL.md
EOF
    exit 1
  fi

  rm -rf "$target_skill"
  mkdir -p "$(dirname "$target_skill")"

  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete \
      --exclude '__pycache__/' \
      --exclude '*.pyc' \
      "$source_skill/" "$target_skill/"
  else
    cp -R "$source_skill" "$target_skill"
    find "$target_skill" -name '__pycache__' -type d -prune -exec rm -rf {} +
    find "$target_skill" -name '*.pyc' -type f -delete
  fi

  printf 'Synced %s#%s:%s -> %s\n' "$source_url" "$source_ref" "$skill_name" "$target_skill"
}

sync_skill cjk-layout
sync_skill cjk-layout-audit
