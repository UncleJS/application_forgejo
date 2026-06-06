#!/usr/bin/env bash
# stop.sh — stop the Forgejo pod
# Data volumes are NOT affected.
#
# Usage: ./scripts/stop.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

echo "==> Stopping Forgejo pod..."
stop_units
echo "    Done. Data volumes are preserved."
