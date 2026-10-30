#!/usr/bin/env bash
# update.sh — pull latest LTS patches, or upgrade to the next released LTS major
#
# Discovers the latest already-released Forgejo LTS from the official schedule
# JSON. Same-major updates run unattended. A newer LTS major prompts for
# confirmation (unless --yes), backs up volumes, rewrites the image tag, then
# rebuilds via install.sh.
#
# Usage:
#   ./scripts/update.sh
#   ./scripts/update.sh --dry-run
#   ./scripts/update.sh --yes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

DRY_RUN=0
ASSUME_YES=0

usage() {
  cat <<'EOF'
Usage: ./scripts/update.sh [--dry-run] [--yes]

  (no args)   Discover latest released Forgejo LTS; pull patches or upgrade.
  --dry-run   Print current/target major and planned action; make no changes.
  --yes       Skip the major-upgrade confirmation prompt (still backs up).

EOF
}

for arg in "$@"; do
  case "${arg}" in
    --dry-run) DRY_RUN=1 ;;
    --yes)     ASSUME_YES=1 ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: unknown argument: ${arg}" >&2
      usage >&2
      exit 1
      ;;
  esac
done

latest_released_lts_major() {
  python3 - "${FORGEJO_SCHEDULE_URL}" <<'PY'
import json, sys, urllib.request
from datetime import date

url = sys.argv[1]
with urllib.request.urlopen(url, timeout=30) as resp:
    data = json.load(resp)

today = date.today().isoformat()
best = None
for row in data:
    if not row.get("lts"):
        continue
    release = row.get("release") or ""
    if release > today:
        continue
    major = int(row["major"])
    if best is None or major > best:
        best = major

if best is None:
    sys.exit(2)
print(best)
PY
}

confirm_major_upgrade() {
  local current="$1"
  local target="$2"

  echo ""
  echo "  LTS major upgrade available: ${current} → ${target}"
  echo "  Review: https://forgejo.org/docs/latest/admin/upgrade/"
  echo ""

  if [[ "${ASSUME_YES}" -eq 1 ]]; then
    echo "  --yes: proceeding without prompt."
    return 0
  fi

  if [[ ! -t 0 ]]; then
    echo "ERROR: LTS major upgrade requires confirmation, but stdin is not a TTY." >&2
    echo "  Re-run interactively, or pass --yes to opt in." >&2
    return 1
  fi

  local reply
  read -r -p "  Proceed with LTS major upgrade? [y/N] " reply
  case "${reply}" in
    y|Y|yes|YES) return 0 ;;
    *)
      echo "  Aborted — no changes made."
      return 2
      ;;
  esac
}

echo "========================================"
echo "  Forgejo — LTS update"
echo "========================================"
echo ""

current="$(current_forgejo_major)"
echo "Current image : ${FORGEJO_IMAGE}"
echo "Current major : ${current}"

target=""
if target="$(latest_released_lts_major 2>/dev/null)"; then
  echo "Latest LTS    : ${target}  (from release schedule)"
else
  echo "WARNING: could not fetch/parse Forgejo release schedule."
  echo "         Falling back to same-major patch pull only."
  target="${current}"
fi

echo ""

if [[ "${DRY_RUN}" -eq 1 ]]; then
  if [[ "${target}" -gt "${current}" ]]; then
    echo "Dry-run: would prompt for LTS major upgrade ${current} → ${target},"
    echo "         then backup volumes, rewrite image tags, and run install.sh."
  elif [[ "${target}" -eq "${current}" ]]; then
    echo "Dry-run: same LTS major (${current}); would run install.sh (pull patches)."
  else
    echo "Dry-run: schedule LTS (${target}) is older than configured (${current});"
    echo "         would run install.sh without rewriting tags."
  fi
  exit 0
fi

if [[ "${target}" -gt "${current}" ]]; then
  if ! confirm_major_upgrade "${current}" "${target}"; then
    status=$?
    if [[ "${status}" -eq 2 ]]; then
      exit 0
    fi
    exit "${status}"
  fi

  echo ""
  echo "[1/3] Backing up volumes..."
  backup_project_volumes
  echo "      Done."

  echo ""
  echo "[2/3] Setting Forgejo image major → ${target}"
  set_forgejo_major "${target}"
  echo "      FORGEJO_IMAGE=${FORGEJO_IMAGE}"

  echo ""
  echo "[3/3] Running install.sh..."
  echo ""
  exec "${SCRIPT_DIR}/install.sh"
fi

if [[ "${target}" -lt "${current}" ]]; then
  echo "Configured major (${current}) is newer than schedule LTS (${target})."
  echo "Leaving tags unchanged; pulling current images via install.sh."
  echo ""
fi

echo "Same LTS major (${current}) — pulling latest patches via install.sh."
echo ""
exec "${SCRIPT_DIR}/install.sh"
