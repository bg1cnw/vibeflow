#!/usr/bin/env bash
# =============================================================================
# VibeFlow Marketplace Installer for Claude Code (macOS / Linux, local checkout)
# =============================================================================
#
# Usage from a cloned checkout:
#   cd /path/to/vibeflow
#   bash ./claude-code/install.sh
#
# Optional source root override:
#   VIBEFLOW_SOURCE_ROOT=/path/to/vibeflow bash ./claude-code/install.sh
#
# After installation, run:
#   /plugin install vibeflow@vibeflow
#
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_SOURCE_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SOURCE_ROOT="${VIBEFLOW_SOURCE_ROOT:-${DEFAULT_SOURCE_ROOT}}"
MARKETPLACE_NAME="vibeflow"

CLAUDE_PLUGINS_DIR="${HOME}/.claude/plugins"
MARKETPLACES_DIR="${CLAUDE_PLUGINS_DIR}/marketplaces"
TARGET_DIR="${MARKETPLACES_DIR}/${MARKETPLACE_NAME}"
KNOWN_MARKETPLACES_FILE="${CLAUDE_PLUGINS_DIR}/known_marketplaces.json"

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
  error "git is required to install vibeflow marketplace."
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
  local files

  mkdir -p "$destination"

  files="$(git -C "$source" ls-files -co --exclude-standard)"
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    [[ ! -e "${source}/${file}" ]] && continue
    mkdir -p "$(dirname "${destination}/${file}")"
    cp -p "${source}/${file}" "${destination}/${file}"
  done <<< "$files"
}

info "Installing vibeflow marketplace from local checkout..."
info "Source root: $SOURCE_ROOT"

mkdir -p "$MARKETPLACES_DIR"

if [[ -d "$TARGET_DIR" ]]; then
  info "Removing existing installation at $TARGET_DIR..."
  rm -rf "$TARGET_DIR"
fi

copy_local_tree "$SOURCE_ROOT" "$TARGET_DIR"

MARKETPLACE_JSON="${TARGET_DIR}/.claude-plugin/marketplace.json"
if [[ ! -f "$MARKETPLACE_JSON" ]]; then
  error "marketplace.json not found in local checkout"
  exit 1
fi

echo "$SOURCE_ROOT" >/dev/null

if [[ ! -d "${TARGET_DIR}/skills" ]]; then
  error "skills directory not found in local checkout"
  exit 1
fi

SKILL_COUNT=$(find "${TARGET_DIR}/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | xargs)
success "Local copy completed (${SKILL_COUNT} skills)"

info "Updating registration metadata..."
mkdir -p "$CLAUDE_PLUGINS_DIR"

if [[ ! -f "$KNOWN_MARKETPLACES_FILE" ]]; then
  printf '{}\n' > "$KNOWN_MARKETPLACES_FILE"
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
CLEAN_VERSION="$(get_source_version "$TARGET_DIR" | tr -d '\r\n')"

if command -v jq >/dev/null 2>&1; then
  jq --arg name "$MARKETPLACE_NAME" \
     --arg location "$TARGET_DIR" \
     --arg timestamp "$TIMESTAMP" \
     --arg source "$SOURCE_ROOT" \
     '.[$name] = {
       "source": {"source": "local", "path": $source},
       "installLocation": $location,
       "lastUpdated": $timestamp
     }' "$KNOWN_MARKETPLACES_FILE" > "${KNOWN_MARKETPLACES_FILE}.tmp" && \
  mv "${KNOWN_MARKETPLACES_FILE}.tmp" "$KNOWN_MARKETPLACES_FILE"
  success "Registered marketplace (jq)"
elif command -v python3 >/dev/null 2>&1; then
  python3 - "$KNOWN_MARKETPLACES_FILE" "$MARKETPLACE_NAME" "$TARGET_DIR" "$SOURCE_ROOT" "$TIMESTAMP" <<'PYEOF'
import json, sys
path = sys.argv[1]
name = sys.argv[2]
location = sys.argv[3]
source = sys.argv[4]
timestamp = sys.argv[5]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
data[name] = {
    "source": {"source": "local", "path": source},
    "installLocation": location,
    "lastUpdated": timestamp
}
with open(path, 'w', encoding="utf-8") as f:
    json.dump(data, f, indent=2)
PYEOF
  success "Registered marketplace (python3)"
elif command -v python >/dev/null 2>&1; then
  python - "$KNOWN_MARKETPLACES_FILE" "$MARKETPLACE_NAME" "$TARGET_DIR" "$SOURCE_ROOT" "$TIMESTAMP" <<'PYEOF'
import json, sys
path = sys.argv[1]
name = sys.argv[2]
location = sys.argv[3]
source = sys.argv[4]
timestamp = sys.argv[5]
with open(path, encoding="utf-8") as f:
    data = json.load(f)
data[name] = {
    "source": {"source": "local", "path": source},
    "installLocation": location,
    "lastUpdated": timestamp
}
with open(path, 'w', encoding="utf-8") as f:
    json.dump(data, f, indent=2)
PYEOF
  success "Registered marketplace (python)"
else
  error "jq and python are both unavailable, cannot update known_marketplaces.json"
  exit 1
fi

echo ""
echo -e "${GREEN}========================================${RESET}"
echo -e "${GREEN}  安装完成！${RESET}"
echo -e "${GREEN}========================================${RESET}"
echo ""
echo -e "Source root : ${SOURCE_ROOT}"
echo -e "Install dir : ${TARGET_DIR}"
echo -e "Version     : ${CLEAN_VERSION}"
echo -e "Next step (in Claude Code):"
echo -e "  ${CYAN}/plugin install vibeflow@vibeflow${RESET}"
