#!/usr/bin/env bash
# uninstall.sh — stop, disable, and remove Quadlet unit files.
# Data volumes are NOT touched. Re-install with install.sh at any time.
#
# Usage: ./scripts/uninstall.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

echo "========================================"
echo "  Forgejo — uninstall (volumes kept)"
echo "========================================"
echo ""

echo "[1/5] Stopping units..."
stop_units

echo "[2/5] Disabling units..."
disable_units

echo "[3/5] Removing runtime (pod + containers)..."
remove_runtime

echo "[4/5] Removing Quadlet unit files..."
remove_unit_files

echo "[5/5] Reloading systemd daemon..."
systemctl --user daemon-reload

echo ""
echo "  Uninstall complete. Named volumes are preserved."
echo ""
echo "  To reinstall:       ./scripts/install.sh"
echo "  To delete volumes:  ./scripts/teardown.sh --purge-volumes"
echo "  To delete images:   ./scripts/teardown.sh --purge-images"
echo ""
