# Forgejo — AGENTS.md

[![Forgejo](https://img.shields.io/badge/Forgejo-15%20LTS-orange?logo=forgejo&logoColor=white)](https://forgejo.org)
[![Podman](https://img.shields.io/badge/Podman-rootless-892CA0?logo=podman&logoColor=white)](https://podman.io)
[![Systemd](https://img.shields.io/badge/systemd-Quadlet-0d7eb8)](https://www.freedesktop.org/software/systemd/man/latest/quadlet.html)

---

## Table of Contents

- [Update / Rebuild](#update--rebuild)
- [Ports](#ports)
- [Quick Reference](#quick-reference)
- [Environment](#environment)

---

## Update / Rebuild

[![Systemd](https://img.shields.io/badge/systemd-Quadlet-0d7eb8)](https://www.freedesktop.org/software/systemd/man/latest/quadlet.html)

```bash
# LTS image update (patches; prompts on next LTS major)
./scripts/update.sh

# Install / rebuild after Quadlet or .env changes
./scripts/install.sh
```

`update.sh` is the routine image path: discovers the latest released Forgejo LTS
(LTS-only; never 16/17/18), pulls patches on the same major, or after confirm
upgrades to the next LTS major (backs up volumes under `backups/` first).
`install.sh` is **idempotent** — stops the pod, copies Quadlet files, pulls images,
reloads systemd, and restarts. Use it for first install and Quadlet/`.env` rebuilds.

[↑ Back to Table of Contents](#table-of-contents)

---

## Ports

[![Podman](https://img.shields.io/badge/Podman-rootless-892CA0?logo=podman&logoColor=white)](https://podman.io)

| Service  | Host port |
|----------|-----------|
| Web UI   | 13400     |
| SSH (git)| 13401     |

[↑ Back to Table of Contents](#table-of-contents)

---

## Quick Reference

[![Systemd](https://img.shields.io/badge/systemd-Quadlet-0d7eb8)](https://www.freedesktop.org/software/systemd/man/latest/quadlet.html)

```bash
# Update images (LTS patches / next LTS)
./scripts/update.sh

# Start / Stop
./scripts/start.sh
./scripts/stop.sh

# Remove units, keep data
./scripts/uninstall.sh

# Full teardown (data preserved by default)
./scripts/teardown.sh

# Full teardown + delete all volumes (DATA LOSS — irreversible)
./scripts/teardown.sh --purge-volumes

# Full teardown + delete pulled images
./scripts/teardown.sh --purge-images

# Logs
journalctl --user -u forgejo.service -f
journalctl --user -u forgejo-db.service -f

# Status
systemctl --user status forgejo-pod.service
```

[↑ Back to Table of Contents](#table-of-contents)

---

## Environment

[![Forgejo](https://img.shields.io/badge/Forgejo-config-orange?logo=forgejo&logoColor=white)](https://forgejo.org)

- Canonical env file: `<repo>/.env` (gitignored)
- Template:           `<repo>/.env.example` (gitignored — copy and fill in secrets)
- Never create host-level env files outside the repo.

[↑ Back to Table of Contents](#table-of-contents)
