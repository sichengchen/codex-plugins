#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_url="${CJK_LAYOUT_AUDIT_SKILL_REPO_URL:-https://github.com/sichengchen/cjk-layout-audit-skill.git}"
source_ref="${CJK_LAYOUT_AUDIT_SKILL_REF:-main}"
target_skill="$repo_root/plugins/cjk-text-layout/skills/cjk-layout-audit"
tmp_root="${TMPDIR:-/tmp}"
workdir="$(mktemp -d "$tmp_root/cjk-layout-audit-sync.XXXXXX")"

cleanup() {
  rm -rf "$workdir"
}
trap cleanup EXIT

checkout="$workdir/cjk-layout-audit-skill"

git clone --depth 1 --branch "$source_ref" "$source_url" "$checkout"
source_skill="$checkout/cjk-layout-audit"

if [[ ! -f "$source_skill/SKILL.md" ]]; then
  cat >&2 <<EOF
Unable to find cjk-layout-audit skill source in cloned repository.
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

printf 'Synced %s#%s -> %s\n' "$source_url" "$source_ref" "$target_skill"
