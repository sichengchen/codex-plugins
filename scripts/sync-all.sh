#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script_dir="$repo_root/scripts"

"$script_dir/sync-cjk-layout-audit.sh"

python3 - "$repo_root" <<'PY_README'
import json
import sys
from pathlib import Path

repo_root = Path(sys.argv[1])
marketplace_path = repo_root / ".agents/plugins/marketplace.json"
marketplace = json.loads(marketplace_path.read_text(encoding="utf-8"))
marketplace_name = marketplace.get("name", "marketplace")
display_name = marketplace.get("interface", {}).get("displayName", marketplace_name)

lines = [
    f"# {display_name} Codex Plugins",
    "",
    "Install this marketplace:",
    "",
    "```bash",
    "codex plugin marketplace add sichengchen/codex-plugins",
    "```",
    "",
    "## Plugins",
    "",
]

plugins = marketplace.get("plugins", [])
if plugins:
    lines.extend([
        "| Plugin | Description | Category | Capabilities | Version |",
        "| --- | --- | --- | --- | --- |",
    ])

for entry in plugins:
    name = entry.get("name", "unknown")
    source = entry.get("source", {})
    path = source.get("path")
    description = ""
    category = entry.get("category", "")
    capabilities = ""
    version = ""
    if isinstance(path, str):
        plugin_json = repo_root / path / ".codex-plugin/plugin.json"
        if plugin_json.exists():
            plugin = json.loads(plugin_json.read_text(encoding="utf-8"))
            interface = plugin.get("interface", {})
            description = interface.get("shortDescription") or plugin.get("description", "")
            category = interface.get("category") or category
            raw_capabilities = interface.get("capabilities", [])
            if isinstance(raw_capabilities, list):
                capabilities = ", ".join(str(item) for item in raw_capabilities)
            version = plugin.get("version", "")
    lines.append(
        f"| `{name}` | {description} | {category} | {capabilities} | {version} |"
    )

if not plugins:
    lines.append("No plugins are currently listed.")

(repo_root / "README.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
PY_README

printf 'Regenerated README.md\n'
