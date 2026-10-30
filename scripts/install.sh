#!/usr/bin/env bash
# install.sh — idempotent install + rebuild
#
# Safe to re-run at any time:
#   - Stops running units if already active
#   - Copies updated Quadlet files (@@REPO_ROOT@@ substituted with real path)
#   - Pulls images
#   - Reloads systemd daemon
#   - Enables linger for boot persistence
#   - Starts the pod
#
# Usage: ./scripts/install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

echo "========================================"
echo "  Forgejo — install / rebuild"
echo "========================================"
echo ""

# ---- [1/6] Validate .env ----
echo "[1/6] Checking .env..."
check_env_file
echo "      OK: ${ENV_FILE}"

# ---- [2/6] Stop any running units (idempotent — ok if not running) ----
echo "[2/6] Stopping any running units..."
stop_units
echo "      Done."

# ---- [3/6] Install Quadlet files ----
echo "[3/6] Installing Quadlet files → ${QUADLET_DEST}"
mkdir -p "${QUADLET_DEST}"
for src in "${QUADLET_SRC}"/*; do
  fname="$(basename "$src")"
  dest="${QUADLET_DEST}/${fname}"
  # Substitute @@REPO_ROOT@@ placeholder with the real absolute repo path
  sed "s|@@REPO_ROOT@@|${REPO_ROOT}|g" "$src" > "$dest"
  echo "      ${fname}"
done

# ---- [4/6] Pull images ----
echo "[4/6] Pulling images..."
for img in "${PROJECT_IMAGES[@]}"; do
  echo "      ${img}"
  podman pull "${img}"
done

# ---- [5/6] Reload systemd + enable linger ----
echo "[5/6] Reloading systemd daemon..."
systemctl --user daemon-reload

echo "      Enabling linger for ${USER}..."
loginctl enable-linger "${USER}"

# ---- [6/6] Start pod ----
echo "[6/6] Starting forgejo-pod.service..."
systemctl --user start forgejo-pod.service

HOST_IP="$(hostname -I | awk '{print $1}')"

echo ""
echo "========================================"
echo "  Forgejo is starting up"
echo "========================================"
echo ""
echo "  Web UI : http://${HOST_IP}:13400"
echo "  SSH    : ssh -p 13401 git@${HOST_IP}"
echo ""
echo "  Status : systemctl --user status forgejo-pod.service"
echo "  Logs   : journalctl --user -u forgejo.service -f"
echo "  DB logs: journalctl --user -u forgejo-db.service -f"
echo ""
echo "  First run: open the Web UI to complete the setup wizard."
echo ""
