#!/usr/bin/env bash
# lib/common.sh — shared project constants and lifecycle helpers
# Source this file; do not execute directly.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
QUADLET_SRC="${REPO_ROOT}/.quadlet"
QUADLET_DEST="${HOME}/.config/containers/systemd"
ENV_FILE="${REPO_ROOT}/.env"

# ---- Project inventory (explicit lists — no prune, ever) ----

PROJECT_POD="forgejo"

PROJECT_UNITS=(
  "forgejo-pod.service"
  "forgejo.service"
  "forgejo-db.service"
)

PROJECT_CONTAINERS=(
  "forgejo"
  "forgejo-db"
)

PROJECT_IMAGES=(
  "codeberg.org/forgejo/forgejo:15.0.1"
  "docker.io/library/mariadb:lts"
)

# Both bare and systemd- prefixed variants — Quadlet-managed volumes
# receive a systemd- prefix (e.g. forgejo-data.volume → systemd-forgejo-data).
PROJECT_VOLUMES=(
  "forgejo-data"
  "systemd-forgejo-data"
  "forgejo-db-data"
  "systemd-forgejo-db-data"
)

# ---- Lifecycle helpers ----

check_env_file() {
  if [[ ! -f "${ENV_FILE}" ]]; then
    echo "ERROR: .env not found at ${ENV_FILE}"
    echo "  Create it from the template:"
    echo "    cp ${REPO_ROOT}/.env.example ${REPO_ROOT}/.env"
    echo "  Then fill in the secrets before re-running."
    exit 1
  fi
}

stop_units() {
  echo "  Stopping units..."
  for unit in "${PROJECT_UNITS[@]}"; do
    systemctl --user stop "$unit" >/dev/null 2>&1 || true
  done
}

disable_units() {
  echo "  Disabling and resetting units..."
  for unit in "${PROJECT_UNITS[@]}"; do
    systemctl --user disable   "$unit" >/dev/null 2>&1 || true
    systemctl --user reset-failed "$unit" >/dev/null 2>&1 || true
  done
}

remove_unit_files() {
  echo "  Removing Quadlet unit files from ${QUADLET_DEST}..."
  for src in "${QUADLET_SRC}"/*; do
    fname="$(basename "$src")"
    rm -f "${QUADLET_DEST}/${fname}"
  done
}

remove_runtime() {
  echo "  Removing pod and containers (explicit rm — no prune)..."
  podman pod rm -f "${PROJECT_POD}" >/dev/null 2>&1 || true
  for ctr in "${PROJECT_CONTAINERS[@]}"; do
    podman rm -f "$ctr" >/dev/null 2>&1 || true
  done
}

remove_images() {
  echo "  Removing project images (explicit rm — no prune)..."
  for img in "${PROJECT_IMAGES[@]}"; do
    podman image rm -f "$img" >/dev/null 2>&1 || true
  done
}

purge_volumes() {
  echo "  Purging named volumes (explicit rm — no prune)..."
  for vol in "${PROJECT_VOLUMES[@]}"; do
    podman volume rm -f "$vol" >/dev/null 2>&1 || true
  done
}
