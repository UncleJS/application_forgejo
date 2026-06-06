#!/usr/bin/env bash
# teardown.sh — complete teardown of the Forgejo pod.
#
# By default: stops units, disables units, removes runtime and Quadlet files.
# Named volumes are KEPT unless an explicit flag is passed.
#
# Flags:
#   --purge-volumes   delete all named volumes   (DATA LOSS — irreversible)
#   --purge-images    remove pulled container images
#
# Usage:
#   ./scripts/teardown.sh
#   ./scripts/teardown.sh --purge-volumes
#   ./scripts/teardown.sh --purge-images
#   ./scripts/teardown.sh --purge-volumes --purge-images

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

OPT_PURGE_VOLUMES=false
OPT_PURGE_IMAGES=false

for arg in "$@"; do
  case "$arg" in
    --purge-volumes) OPT_PURGE_VOLUMES=true ;;
    --purge-images)  OPT_PURGE_IMAGES=true  ;;
    *)
      echo "ERROR: Unknown flag: $arg"
      echo "Usage: teardown.sh [--purge-volumes] [--purge-images]"
      exit 1
      ;;
  esac
done

echo "========================================"
echo "  Forgejo — teardown"
echo "========================================"
echo ""
echo "  purge-volumes : ${OPT_PURGE_VOLUMES}"
echo "  purge-images  : ${OPT_PURGE_IMAGES}"
echo ""

if [[ "${OPT_PURGE_VOLUMES}" == "true" ]]; then
  echo "  !! WARNING: --purge-volumes will permanently delete all Forgejo"
  echo "  !! repository and database data. This cannot be undone."
  echo ""
  echo "  Press Ctrl-C within 5 seconds to abort..."
  sleep 5
  echo ""
fi

echo "[1/6] Stopping units..."
stop_units

echo "[2/6] Disabling units..."
disable_units

echo "[3/6] Removing runtime (pod + containers, explicit rm — no prune)..."
remove_runtime

echo "[4/6] Removing Quadlet unit files..."
remove_unit_files

echo "[5/6] Reloading systemd daemon..."
systemctl --user daemon-reload

if [[ "${OPT_PURGE_IMAGES}" == "true" ]]; then
  echo "[+]   Removing images (explicit rm — no prune)..."
  remove_images
fi

if [[ "${OPT_PURGE_VOLUMES}" == "true" ]]; then
  echo "[6/6] Purging volumes (DATA DELETED — explicit rm — no prune)..."
  purge_volumes
else
  echo "[6/6] Volumes preserved (pass --purge-volumes to delete)."
fi

echo ""
echo "  Teardown complete."
echo ""
