#!/usr/bin/env bash
# VibeFlow installer for Codex (macOS / Linux, local checkout)
#
# Usage from a cloned checkout:
#   cd /path/to/vibeflow
#   bash ./codex/install.sh
#
# Optional source root override:
#   VIBEFLOW_SOURCE_ROOT=/path/to/vibeflow bash ./codex/install.sh
#
# After installation, restart Codex to activate new skills.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_SOURCE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SOURCE_ROOT="${VIBEFLOW_SOURCE_ROOT:-${DEFAULT_SOURCE_ROOT}}"
CODEX_HOME="${CODEX_HOME:-${HOME}/.codex}"
INSTALL_DIR="${CODEX_HOME}/vibeflow"
SKILLS_DIR="${CODEX_HOME}/skills"

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET} $*"; }
success() { echo -e "${GREEN}[OK]${RESET} $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }

if [[ ! -d "$SOURCE_ROOT" ]]; then
  error "source root not found: $SOURCE_ROOT"
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  error "git is required to install vibeflow for Codex."
  exit 1
fi

get_source_version() {
  local root="$1"
  local plugin_json="${root}/.claude-plugin/plugin.json"
  local marketplace_json="${root}/.claude-plugin/marketplace.json"

  if [[ -f "$plugin_json" ]]; then
    if command -v jq >/dev/null 2>&1; then
      jq -r '.version // empty' "$plugin_json" 2>/dev/null || true
      return 0
    fi
    if command -v python3 >/dev/null 2>&1; then
      python3 - "$plugin_json" <<'PYEOF'
import json, sys
path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
print(data.get("version", ""))
PYEOF
      return 0
    fi
    if command -v python >/dev/null 2>&1; then
      python - "$plugin_json" <<'PYEOF'
import json, sys
path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
print(data.get("version", ""))
PYEOF
      return 0
    fi
  fi

  if [[ -f "$marketplace_json" ]]; then
    if command -v jq >/dev/null 2>&1; then
      jq -r '.plugins[0].version // empty' "$marketplace_json" 2>/dev/null || true
      return 0
    fi
    if command -v python3 >/dev/null 2>&1; then
      python3 - "$marketplace_json" <<'PYEOF'
import json, sys
path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
plugins = data.get("plugins") or []
print((plugins[0] or {}).get("version", "") if plugins else "")
PYEOF
      return 0
    fi
    if command -v python >/dev/null 2>&1; then
      python - "$marketplace_json" <<'PYEOF'
import json, sys
path = sys.argv[1]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
plugins = data.get("plugins") or []
print((plugins[0] or {}).get("version", "") if plugins else "")
PYEOF
      return 0
    fi
  fi

  printf 'unknown\n'
}

copy_local_tree() {
  local source="$1"
  local destination="$2"

  mkdir -p "$destination"

  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    [[ ! -e "${source}/${file}" ]] && continue
    mkdir -p "$(dirname "${destination}/${file}")"
    cp -p "${source}/${file}" "${destination}/${file}"
  done < <(git -C "$source" ls-files -co --exclude-standard)
}

info "Installing vibeflow for Codex from local checkout..."
info "Source root: $SOURCE_ROOT"

mkdir -p "$CODEX_HOME" "$SKILLS_DIR"

if [[ -d "$INSTALL_DIR" ]]; then
  info "Removing existing installation at $INSTALL_DIR..."
  rm -rf "$INSTALL_DIR"
fi

copy_local_tree "$SOURCE_ROOT" "$INSTALL_DIR"

if [[ ! -d "${INSTALL_DIR}/skills" ]]; then
  error "skills directory not found in local checkout"
  exit 1
fi

find "${INSTALL_DIR}/skills" -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -r -d '' skill_dir; do
  skill_name="$(basename "$skill_dir")"
  target_path="${SKILLS_DIR}/${skill_name}"
  rm -rf "$target_path"
  ln -s "$skill_dir" "$target_path"
done

installed_version="$(get_source_version "$INSTALL_DIR" | tr -d '\r\n')"

echo ""
success "VibeFlow installed for Codex."
echo ""
echo "  Source:   $SOURCE_ROOT"
echo "  Repo:     $INSTALL_DIR"
echo "  Skills:   $SKILLS_DIR"
echo "  Version:  ${installed_version}"
echo ""
echo "Restart Codex to activate new skills."
