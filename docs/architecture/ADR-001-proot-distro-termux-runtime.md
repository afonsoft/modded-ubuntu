# ADR-001: Ubuntu rootfs inside `proot-distro` on Termux

## Status
Accepted (inherited from upstream `modded-ubuntu`, extended by this fork)

## Date
2026-09-20 (documented; decision predates the fork)

## Context
The project must run a full Ubuntu userspace on Android devices **without root**. Android's kernel cannot run containers (no namespaces/cgroups for unprivileged users), and Termux provides only a minimal Linux environment. We needed Ubuntu's `apt` ecosystem, glibc, and standard dev tooling on a phone.

## Decision
Run Ubuntu as a `proot-distro` rootfs inside Termux. `proot` emulates `chroot` via `ptrace` — no root needed. `setup.sh` installs `proot-distro ubuntu` and generates the `${PREFIX}/bin/ubuntu` wrapper (`setup.sh:359-360`).

## Alternatives Considered

### Full VM / QEMU
- Pros: real kernel, real systemd, real containers inside.
- Cons: 10-50x slower on ARM phones, heavy storage, poor UX.
- Rejected: performance and footprint unacceptable for a phone-first tool.

### chroot (requires root)
- Pros: native speed, real isolation.
- Cons: requires a rooted device — excludes the entire target audience.
- Rejected: root requirement is a dealbreaker.

### Termux native packages only (no Ubuntu)
- Pros: simplest, no emulation layer.
- Cons: Termux `pkg` repo is much smaller than Ubuntu `apt`; many dev tools/PPAs don't exist.
- Rejected: defeats the purpose of an Ubuntu environment.

### Andronix/other proot distros
- Same underlying technique; this fork extends `modded-ubuntu` rather than starting over.
- Chosen: build on the existing Brazilian fork with its polish.

## Consequences
- **No systemd** — service management must be script-driven (`vncstart`/`vncstop`; the `distro/systemd/` unit is optional for non-proot contexts). See ADR-005.
- **No real IPC/kernel features** — `--no-sysvipc` is mandatory on `proot-distro login`; Android may signal-9 long processes (`fix-signal9.sh`).
- **ptrace overhead** — I/O-heavy operations (apt, npm) are slower than native.
- Positive: works on any Android with Termux, ~3 GB storage, no root, removable with `remove.sh`.
