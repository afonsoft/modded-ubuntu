# ADR-010: Node.js via NodeSource `.deb`, NVM removed

## Status
Accepted — supersedes the earlier NVM-based install (CHANGELOG, NVM `v0.40.0` era)

## Date
2026-09-20 (documented; migration visible in `distro/nodejs.sh`)

## Context
An earlier iteration installed Node via **NVM** per-user (versions 20/22/24, default 22). In practice NVM caused friction: version activation only via `.bashrc` hooks (breaks non-interactive shells and `proot-distro login` wrappers), per-user divergence, and extra symlink machinery in `/usr/local/bin` to make `node` usable system-wide.

## Decision
`distro/nodejs.sh` installs Node.js LTS from the **NodeSource `.deb` repository** and *actively removes* previous NVM installs: deletes `$HOME/.nvm`, scrubs NVM lines from `.bashrc`, purges distro `nodejs`/`npm` packages, then configures `/etc/apt/keyrings` + `signed-by=` NodeSource repo (`nodejs.sh:51-110`).

## Alternatives Considered

### Keep NVM
- Rejected: shell-hook activation is incompatible with non-interactive/proot flows; state diverges per user; wrapper symlinks were fragile.

### Ubuntu repo nodejs
- Pros: zero third-party repo.
- Cons: distro version lags upstream LTS.
- Rejected: NodeSource tracks LTS properly and is the project's established source.

## Consequences
- Node is system-wide (`/usr/bin/node`) immediately — no `.bashrc` dependency, works in non-login shells and proot wrappers.
- Migration path is codified in the installer itself (NVM removal block) — running `nodejs.sh` converges old installs.
- NVM is a rejected option: do not reintroduce it without superseding this ADR.
