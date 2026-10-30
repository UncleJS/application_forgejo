# Scripts

[![Forgejo](https://img.shields.io/badge/Forgejo-15%20LTS-orange?logo=forgejo&logoColor=white)](https://forgejo.org)
[![Podman](https://img.shields.io/badge/Podman-rootless-892CA0?logo=podman&logoColor=white)](https://podman.io)
[![Systemd](https://img.shields.io/badge/systemd-Quadlet-0d7eb8)](https://www.freedesktop.org/software/systemd/man/latest/quadlet.html)

Lifecycle scripts for the Forgejo rootless Podman pod. All scripts source
`lib/common.sh` for shared constants and helper functions.

---

## Table of Contents

- [update.sh](#updatesh)
- [install.sh](#installsh)
- [start.sh](#startsh)
- [stop.sh](#stopsh)
- [uninstall.sh](#uninstallsh)
- [teardown.sh](#teardownsh)
- [lib/common.sh](#libcommonsh)

---

## update.sh

[![Forgejo](https://img.shields.io/badge/Forgejo-15%20LTS-orange?logo=forgejo&logoColor=white)](https://forgejo.org)

**LTS image update.** Discovers the latest already-released Forgejo LTS from the
official [release schedule JSON](https://codeberg.org/forgejo/docs/raw/branch/next/release-schedule.json).
LTS-only — never selects 16/17/18. Ends by running `install.sh`.

```bash
./scripts/update.sh
./scripts/update.sh --dry-run
./scripts/update.sh --yes
```

### Behaviour

| Situation | Action |
|-----------|--------|
| Same LTS major as configured | No prompt. Pull floating major tag + `mariadb:lts` via `install.sh`. |
| Newer LTS major available | Prompt `Proceed with LTS major upgrade? [y/N]` (default No). On yes: backup volumes to `backups/`, rewrite image tags, then `install.sh`. |
| Schedule fetch fails | Warn and fall back to same-major patch pull. |
| Major bump, no TTY, no `--yes` | Fail closed (exit non-zero). |

### Flags

| Flag | Effect |
|------|--------|
| `--dry-run` | Print current/target major and planned action; make no changes. |
| `--yes` | Skip the major-upgrade confirm (still backs up before rewrite). |

[↑ Back to Table of Contents](#table-of-contents)

---

## install.sh

[![Systemd](https://img.shields.io/badge/systemd-Quadlet-0d7eb8)](https://www.freedesktop.org/software/systemd/man/latest/quadlet.html)

**Idempotent install and rebuild.** Safe to run on first install and on every
subsequent config or Quadlet change. Running it again never causes data loss.
For routine LTS image updates prefer `update.sh`.

```bash
./scripts/install.sh
```

### What it does (in order)

| Step | Action |
|------|--------|
| 1/6 | Validates `.env` exists — fails fast with copy instructions if missing |
| 2/6 | Stops any already-running units (no-op if not running) |
| 3/6 | Copies all `.quadlet/*` files to `~/.config/containers/systemd/`, substituting `@@REPO_ROOT@@` with the real absolute repo path so `EnvironmentFile=` resolves correctly |
| 4/6 | Pulls each image in `PROJECT_IMAGES` (`forgejo:15` LTS major tag and `mariadb:lts`) |
| 5/6 | Reloads the systemd user daemon; enables linger for boot persistence |
| 6/6 | Starts `forgejo-pod.service` |

### Notes

- No flags — behaviour is always the same safe, full rebuild.
- Named volumes are **never** touched; existing Forgejo data and the database survive a rebuild.
- `loginctl enable-linger` is idempotent — harmless if linger is already enabled.

[↑ Back to Table of Contents](#table-of-contents)

---

## start.sh

[![Systemd](https://img.shields.io/badge/systemd-Quadlet-0d7eb8)](https://www.freedesktop.org/software/systemd/man/latest/quadlet.html)

Start the Forgejo pod. Assumes Quadlet units are already installed (i.e.
`install.sh` has been run at least once).

```bash
./scripts/start.sh
```

Equivalent to:

```bash
systemctl --user start forgejo-pod.service
```

Prints the Web UI and SSH URLs after starting, then shows a brief status output.

[↑ Back to Table of Contents](#table-of-contents)

---

## stop.sh

[![Systemd](https://img.shields.io/badge/systemd-Quadlet-0d7eb8)](https://www.freedesktop.org/software/systemd/man/latest/quadlet.html)

Stop the Forgejo pod. Named volumes and data are **not** affected.

```bash
./scripts/stop.sh
```

Equivalent to stopping all three project units:

```bash
systemctl --user stop forgejo-pod.service forgejo.service forgejo-db.service
```

[↑ Back to Table of Contents](#table-of-contents)

---

## uninstall.sh

[![Systemd](https://img.shields.io/badge/systemd-Quadlet-0d7eb8)](https://www.freedesktop.org/software/systemd/man/latest/quadlet.html)

Stop and disable all units, remove the Quadlet unit files from
`~/.config/containers/systemd/`, and reload the systemd daemon.
Named volumes and pulled images are **kept**.

```bash
./scripts/uninstall.sh
```

### What it does (in order)

| Step | Action |
|------|--------|
| 1/5 | Stops all project units |
| 2/5 | Disables units and resets any failed state |
| 3/5 | Removes the pod and containers via explicit `podman rm -f` (no prune) |
| 4/5 | Deletes the copied Quadlet files from `~/.config/containers/systemd/` |
| 5/5 | Reloads the systemd user daemon |

### After uninstall

- Re-install at any time with `./scripts/install.sh` — volumes are intact so all data is preserved.
- To also remove volumes or images, use `teardown.sh` instead.

[↑ Back to Table of Contents](#table-of-contents)

---

## teardown.sh

[![Systemd](https://img.shields.io/badge/systemd-Quadlet-0d7eb8)](https://www.freedesktop.org/software/systemd/man/latest/quadlet.html)

Complete teardown of the Forgejo pod. Performs everything `uninstall.sh` does,
then optionally removes named volumes and/or pulled images depending on the
flags passed.

```bash
./scripts/teardown.sh [--purge-volumes] [--purge-images]
```

### Flags

| Flag | Effect |
|------|--------|
| _(none)_ | Stop, disable, remove units and runtime. Volumes and images kept. |
| `--purge-volumes` | Also delete all named Podman volumes. **DATA LOSS — irreversible.** Triggers a 5-second abort window. |
| `--purge-images` | Also remove the pulled container images (`forgejo:15`, `mariadb:lts`). |

Both flags may be combined:

```bash
./scripts/teardown.sh --purge-volumes --purge-images
```

### What it does (in order)

| Step | Action |
|------|--------|
| 1/6 | Stops all project units |
| 2/6 | Disables units and resets failed state |
| 3/6 | Removes pod and containers via explicit `podman rm -f` (no prune) |
| 4/6 | Removes Quadlet unit files from `~/.config/containers/systemd/` |
| 5/6 | Reloads systemd daemon |
| +   | If `--purge-images`: removes images via explicit `podman image rm -f` (no prune) |
| 6/6 | If `--purge-volumes`: removes named volumes via explicit `podman volume rm -f` (no prune) |

### Safety

- `--purge-volumes` prints a warning and waits 5 seconds before proceeding. Press `Ctrl-C` to abort.
- All removals are **explicit** — only named project artifacts are touched. `podman prune` is never used.
- Volume names targeted: `forgejo-data`, `systemd-forgejo-data`, `forgejo-db-data`, `systemd-forgejo-db-data` (both bare and Quadlet-prefixed variants).

[↑ Back to Table of Contents](#table-of-contents)

---

## lib/common.sh

[![Podman](https://img.shields.io/badge/Podman-rootless-892CA0?logo=podman&logoColor=white)](https://podman.io)

Shared library sourced by all scripts. **Do not execute directly.**

```bash
source ./scripts/lib/common.sh
```

### Constants

| Variable | Value | Purpose |
|----------|-------|---------|
| `REPO_ROOT` | _(auto-detected)_ | Absolute path to the repository root |
| `QUADLET_SRC` | `$REPO_ROOT/.quadlet` | Source Quadlet unit files |
| `QUADLET_DEST` | `~/.config/containers/systemd` | Systemd Quadlet install target |
| `ENV_FILE` | `$REPO_ROOT/.env` | Canonical environment file |
| `BACKUP_DIR` | `$REPO_ROOT/backups` | Volume backups from `update.sh` |
| `FORGEJO_IMAGE` | `codeberg.org/forgejo/forgejo:15` | Forgejo LTS major image |
| `MARIADB_IMAGE` | `docker.io/library/mariadb:lts` | MariaDB LTS image |
| `FORGEJO_SCHEDULE_URL` | _(Codeberg docs JSON)_ | Official release schedule for LTS discovery |
| `PROJECT_POD` | `forgejo` | Podman pod name |
| `PROJECT_UNITS` | _(array)_ | `forgejo-pod.service`, `forgejo.service`, `forgejo-db.service` |
| `PROJECT_CONTAINERS` | _(array)_ | `forgejo`, `forgejo-db` |
| `PROJECT_IMAGES` | _(array)_ | `${FORGEJO_IMAGE}`, `${MARIADB_IMAGE}` |
| `PROJECT_VOLUMES` | _(array)_ | Both bare and `systemd-` prefixed volume names |

### Helper functions

| Function | Description |
|----------|-------------|
| `current_forgejo_major` | Parse major version from `FORGEJO_IMAGE` |
| `set_forgejo_major N` | Rewrite `FORGEJO_IMAGE` in `common.sh` and `Image=` in `.quadlet/forgejo.container` |
| `backup_project_volumes` | Tar Quadlet volumes into `backups/` |
| `check_env_file` | Fails with instructions if `.env` is missing |
| `stop_units` | `systemctl --user stop` each unit in `PROJECT_UNITS` |
| `disable_units` | `systemctl --user disable` + `reset-failed` each unit |
| `remove_unit_files` | Deletes each `.quadlet/*` file from `QUADLET_DEST` |
| `remove_runtime` | `podman pod rm -f` the pod; `podman rm -f` each container |
| `remove_images` | `podman image rm -f` each image in `PROJECT_IMAGES` |
| `purge_volumes` | `podman volume rm -f` each volume in `PROJECT_VOLUMES` |

[↑ Back to Table of Contents](#table-of-contents)
