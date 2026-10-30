# Forgejo

[![Forgejo](https://img.shields.io/badge/Forgejo-15%20LTS-orange?logo=forgejo&logoColor=white)](https://forgejo.org)
[![MariaDB](https://img.shields.io/badge/MariaDB-LTS-blue?logo=mariadb&logoColor=white)](https://mariadb.org)
[![Podman](https://img.shields.io/badge/Podman-rootless-892CA0?logo=podman&logoColor=white)](https://podman.io)
[![Systemd](https://img.shields.io/badge/systemd-Quadlet-0d7eb8)](https://www.freedesktop.org/software/systemd/man/latest/quadlet.html)
[![Platform](https://img.shields.io/badge/Platform-Linux-lightgrey?logo=linux&logoColor=white)](https://kernel.org)
[![License](https://img.shields.io/badge/License-GPL--3.0-blue)](LICENSE)

Self-hosted [Forgejo](https://forgejo.org) git service running as a rootless Podman pod managed by systemd Quadlet. Backed by MariaDB LTS.

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Ports](#ports)
- [Scripts](#scripts)
- [Quadlet Structure](#quadlet-structure)
- [Logs & Status](#logs--status)
- [Maintenance](#maintenance)
- [License](#license)

---

## Overview

[![Forgejo](https://img.shields.io/badge/Forgejo-15%20LTS-orange?logo=forgejo&logoColor=white)](https://forgejo.org)
[![MariaDB](https://img.shields.io/badge/MariaDB-LTS-blue?logo=mariadb&logoColor=white)](https://mariadb.org)

This project deploys Forgejo as a rootless Podman pod using systemd Quadlet units. All persistent data lives in named Podman volumes — no bind mounts. The setup is fully idempotent: running `install.sh` again safely rebuilds and restarts the service.

| Component | Image |
|-----------|-------|
| Forgejo   | `codeberg.org/forgejo/forgejo:15` (LTS major tag) |
| Database  | `docker.io/library/mariadb:lts` |

[↑ Back to Table of Contents](#table-of-contents)

---

## Prerequisites

[![Platform](https://img.shields.io/badge/Platform-Linux-lightgrey?logo=linux&logoColor=white)](https://kernel.org)
[![Podman](https://img.shields.io/badge/Podman-rootless-892CA0?logo=podman&logoColor=white)](https://podman.io)

- **Podman** ≥ 4.4 (rootless, with Quadlet support)
- **systemd** user session active (`loginctl enable-linger $USER` is handled by `install.sh`)
- `sed`, `bash` ≥ 4

[↑ Back to Table of Contents](#table-of-contents)

---

## Quick Start

[![Systemd](https://img.shields.io/badge/systemd-Quadlet-0d7eb8)](https://www.freedesktop.org/software/systemd/man/latest/quadlet.html)

```bash
# 1. Copy and edit the environment file
cp .env.example .env
$EDITOR .env        # set DB passwords and host IP / domain

# 2. Install and start
./scripts/install.sh
```

On first run, open the web UI to complete the setup wizard:

```
http://<host-ip>:13400
```

[↑ Back to Table of Contents](#table-of-contents)

---

## Configuration

[![Forgejo](https://img.shields.io/badge/Forgejo-config-orange?logo=forgejo&logoColor=white)](https://forgejo.org/docs/latest/admin/config-cheat-sheet/)

All configuration is driven by `.env` (gitignored). Copy `.env.example` to get started.

| Variable | Purpose |
|----------|---------|
| `USER_UID` / `USER_GID` | UID/GID for the Forgejo process inside the container |
| `MARIADB_ROOT_PASSWORD` | MariaDB root password (set on first start) |
| `MARIADB_DATABASE` | Database name (default: `forgejo`) |
| `MARIADB_USER` | Database user (default: `forgejo`) |
| `MARIADB_PASSWORD` | Database user password |
| `FORGEJO__database__*` | Forgejo DB connection — must match MariaDB vars |
| `FORGEJO__server__DOMAIN` | Public hostname or IP |
| `FORGEJO__server__ROOT_URL` | Full public URL e.g. `http://192.168.10.41:13400/` |
| `FORGEJO__server__SSH_DOMAIN` | SSH hostname or IP |
| `FORGEJO__server__SSH_PORT` | SSH host port (default: `13401`) |

> Any `FORGEJO__[SECTION]__[KEY]` variable maps directly to an `app.ini` setting.
> See the [Forgejo config cheat sheet](https://forgejo.org/docs/latest/admin/config-cheat-sheet/) for all options.

[↑ Back to Table of Contents](#table-of-contents)

---

## Ports

[![Podman](https://img.shields.io/badge/Podman-rootless-892CA0?logo=podman&logoColor=white)](https://podman.io)

All ports are published on `0.0.0.0` (all host interfaces).

| Service    | Host port | Container port |
|------------|-----------|---------------|
| Web UI     | `13400`   | `3000`        |
| SSH (git)  | `13401`   | `22`          |

[↑ Back to Table of Contents](#table-of-contents)

---

## Scripts

[![Systemd](https://img.shields.io/badge/systemd-Quadlet-0d7eb8)](https://www.freedesktop.org/software/systemd/man/latest/quadlet.html)

All scripts live in `scripts/`. Shared helpers are in `scripts/lib/common.sh`.

| Script | Description |
|--------|-------------|
| `scripts/update.sh` | **LTS update.** Discovers the latest released Forgejo LTS, pulls patches on the same major, or (after confirm) upgrades to the next LTS major. |
| `scripts/install.sh` | **Idempotent install + rebuild.** Stops running units, copies Quadlet files, pulls images, reloads systemd, enables linger, starts pod. |
| `scripts/start.sh` | Start the pod (`systemctl --user start forgejo-pod.service`). |
| `scripts/stop.sh` | Stop the pod. Data volumes untouched. |
| `scripts/uninstall.sh` | Stop, disable, remove Quadlet unit files. Volumes kept. |
| `scripts/teardown.sh` | Full teardown. Accepts `--purge-volumes` and `--purge-images` flags. |

### Teardown flags

```bash
./scripts/teardown.sh                            # remove units + runtime; keep volumes + images
./scripts/teardown.sh --purge-volumes            # also delete all data (irreversible)
./scripts/teardown.sh --purge-images             # also remove pulled images
./scripts/teardown.sh --purge-volumes --purge-images   # full clean slate
```

[↑ Back to Table of Contents](#table-of-contents)

---

## Quadlet Structure

[![Podman](https://img.shields.io/badge/Podman-rootless-892CA0?logo=podman&logoColor=white)](https://podman.io)

Source Quadlet files live in `.quadlet/`. `install.sh` copies them to `~/.config/containers/systemd/`, substituting `@@REPO_ROOT@@` with the real absolute path so `EnvironmentFile=` always points to the repo-local `.env`.

```
.quadlet/
├── forgejo.pod               → forgejo-pod.service      (publishes ports)
├── forgejo.container         → forgejo.service           (app; depends on DB)
├── forgejo-db.container      → forgejo-db.service        (MariaDB)
├── forgejo-data.volume       → systemd-forgejo-data      (/data)
└── forgejo-db-data.volume    → systemd-forgejo-db-data   (/var/lib/mysql)
```

Named volumes are **never** bind-mounted. Quadlet-managed volumes are prefixed `systemd-` by Podman.

[↑ Back to Table of Contents](#table-of-contents)

---

## Logs & Status

[![Systemd](https://img.shields.io/badge/systemd-Quadlet-0d7eb8)](https://www.freedesktop.org/software/systemd/man/latest/quadlet.html)

```bash
# Pod status
systemctl --user status forgejo-pod.service

# Live logs
journalctl --user -u forgejo.service -f
journalctl --user -u forgejo-db.service -f

# All units at once
journalctl --user -u forgejo-pod.service -u forgejo.service -u forgejo-db.service -f
```

[↑ Back to Table of Contents](#table-of-contents)

---

## Maintenance

[![Forgejo](https://img.shields.io/badge/Forgejo-15%20LTS-orange?logo=forgejo&logoColor=white)](https://forgejo.org)

This project tracks **Forgejo LTS only** (major tag `:15`). Non-LTS stables (16/17/18) are never selected. Discovery uses the official [release schedule JSON](https://codeberg.org/forgejo/docs/raw/branch/next/release-schedule.json).

### Update (patches or next LTS)

```bash
./scripts/update.sh
```

- **Same LTS major** — pulls the floating `:15` (and `mariadb:lts`) image and recreates the pod. No prompt.
- **Newer LTS major** (e.g. 15 → 19 when released) — prompts `Proceed with LTS major upgrade? [y/N]`, backs up volumes to `backups/`, rewrites the image tag, then runs `install.sh`.
- `--dry-run` — print planned action only.
- `--yes` — skip the major-upgrade confirm (for automation that opts in). Still backs up before rewriting.

> Major upgrades: review the [Forgejo upgrade guide](https://forgejo.org/docs/latest/admin/upgrade/) before confirming.

### Rebuild after config change

```bash
./scripts/install.sh
```

Use `install.sh` for first install or Quadlet/`.env` rebuilds without LTS discovery. Use `update.sh` for routine image updates.

### Backup volumes

`update.sh` creates dated tarballs under `backups/` automatically before an LTS major bump. Manual backup:

```bash
# Forgejo data
podman run --rm \
  -v systemd-forgejo-data:/data:ro \
  -v "$(pwd)/backups":/backup \
  docker.io/library/alpine \
  tar czf /backup/forgejo-data-$(date +%F).tar.gz /data

# MariaDB data
podman run --rm \
  -v systemd-forgejo-db-data:/var/lib/mysql:ro \
  -v "$(pwd)/backups":/backup \
  docker.io/library/alpine \
  tar czf /backup/forgejo-db-$(date +%F).tar.gz /var/lib/mysql
```

[↑ Back to Table of Contents](#table-of-contents)

---

## License

[![License](https://img.shields.io/badge/License-GPL--3.0-blue)](LICENSE)

GPL-3.0 — see [LICENSE](LICENSE) for full text.

[↑ Back to Table of Contents](#table-of-contents)
