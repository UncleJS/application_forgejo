#!/usr/bin/env bash
# start.sh — start the Forgejo pod
#
# Usage: ./scripts/start.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

echo "==> Starting Forgejo pod..."
systemctl --user start forgejo-pod.service

echo ""
echo "  Web UI : http://localhost:13400"
echo "  SSH    : ssh -p 13401 git@localhost"
echo ""
systemctl --user status forgejo-pod.service --no-pager || true
