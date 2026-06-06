# Forgejo — AGENTS.md

[![Forgejo](https://img.shields.io/badge/Forgejo-15.0.1-orange?logo=forgejo&logoColor=white)](https://forgejo.org)
[![Podman](https://img.shields.io/badge/Podman-rootless-892CA0?logo=podman&logoColor=white)](https://podman.io)
[![Systemd](https://img.shields.io/badge/systemd-Quadlet-0d7eb8)](https://www.freedesktop.org/software/systemd/man/latest/quadlet.html)

---

## Table of Contents

- [Rebuild Command](#rebuild-command)
- [Ports](#ports)
- [Quick Reference](#quick-reference)
- [Environment](#environment)

---

## Rebuild Command

[![Systemd](https://img.shields.io/badge/systemd-Quadlet-0d7eb8)](https://www.freedesktop.org/software/systemd/man/latest/quadlet.html)

```bash
./scripts/install.sh
```

`install.sh` is **idempotent** — it stops the running pod, copies updated Quadlet
files, pulls images, reloads systemd, and restarts. Safe to run repeatedly.

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
