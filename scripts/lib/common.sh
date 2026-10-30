#!/usr/bin/env bash
# lib/common.sh — shared project constants and lifecycle helpers
# Source this file; do not execute directly.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
QUADLET_SRC="${REPO_ROOT}/.quadlet"
QUADLET_DEST="${HOME}/.config/containers/systemd"
ENV_FILE="${REPO_ROOT}/.env"
BACKUP_DIR="${REPO_ROOT}/backups"
FORGEJO_CONTAINER_FILE="${QUADLET_SRC}/forgejo.container"
COMMON_SH_FILE="${REPO_ROOT}/scripts/lib/common.sh"

# ---- Images (single source of truth) ----

FORGEJO_IMAGE="codeberg.org/forgejo/forgejo:15"
MARIADB_IMAGE="docker.io/library/mariadb:lts"
FORGEJO_SCHEDULE_URL="https://codeberg.org/forgejo/docs/raw/branch/next/release-schedule.json"

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
  "${FORGEJO_IMAGE}"
  "${MARIADB_IMAGE}"
)

# Both bare and systemd- prefixed variants — Quadlet-managed volumes
# receive a systemd- prefix (e.g. forgejo-data.volume → systemd-forgejo-data).
PROJECT_VOLUMES=(
  "forgejo-data"
  "systemd-forgejo-data"
  "forgejo-db-data"
  "systemd-forgejo-db-data"
)

# Volumes used for backup (Quadlet-prefixed names that exist at runtime).
BACKUP_VOLUMES=(
  "systemd-forgejo-data:/data"
  "systemd-forgejo-db-data:/var/lib/mysql"
)

# ---- Image / LTS helpers ----

current_forgejo_major() {
  local tag="${FORGEJO_IMAGE##*:}"
  echo "${tag%%.*}"
}

set_forgejo_major() {
  local major="$1"
  local new_image="codeberg.org/forgejo/forgejo:${major}"

  if [[ ! "${major}" =~ ^[0-9]+$ ]]; then
    echo "ERROR: invalid Forgejo major: ${major}" >&2
    return 1
  fi

  sed -i "s|^FORGEJO_IMAGE=.*|FORGEJO_IMAGE=\"${new_image}\"|" "${COMMON_SH_FILE}"
  sed -i "s|^Image=codeberg.org/forgejo/forgejo:.*|Image=${new_image}|" "${FORGEJO_CONTAINER_FILE}"

  FORGEJO_IMAGE="${new_image}"
  PROJECT_IMAGES=(
    "${FORGEJO_IMAGE}"
    "${MARIADB_IMAGE}"
  )
}

backup_project_volumes() {
  local stamp
  stamp="$(date +%F-%H%M%S)"
  mkdir -p "${BACKUP_DIR}"

  echo "  Backing up volumes → ${BACKUP_DIR}"
  for spec in "${BACKUP_VOLUMES[@]}"; do
    local vol="${spec%%:*}"
    local mnt="${spec#*:}"
    local name="${vol#systemd-}"
    local out="${BACKUP_DIR}/${name}-${stamp}.tar.gz"

    if ! podman volume exists "${vol}" 2>/dev/null; then
      echo "      SKIP (volume missing): ${vol}"
      continue
    fi

    podman run --rm \
      -v "${vol}:${mnt}:ro" \
      -v "${BACKUP_DIR}:/backup" \
      docker.io/library/alpine \
      tar czf "/backup/$(basename "${out}")" "${mnt}"
    echo "      ${out}"
  done
}

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
