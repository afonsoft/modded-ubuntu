# ADR-009: `add_apt_key` helper replacing deprecated `apt-key`

## Status
Accepted

## Date
2026-09-20 (documented; landed 2026-08-17, commit `3e15897`)

## Context
`apt-key` is deprecated and removed on Ubuntu 24.10+/26.04 — every `apt-key add` call in `gui.sh`/helper scripts warned or failed on newer releases, breaking PPA setup (XtraDeb, NodeSource, Microsoft repos).

## Decision
All key handling goes through a local `add_apt_key` helper that writes dearmored keyrings to `/etc/apt/keyrings/*.gpg` and references them via `signed-by=` in `.sources` files — the post-`apt-key` mechanism.

## Alternatives Considered

### Keep `apt-key` (works on older releases)
- Rejected: gone on 26.04 — the target release.

### Key in trusted.gpg.d (flat directory)
- Works but loses the `signed-by=` scoping — any key can sign any repo.
- Rejected: `signed-by=` per-repo is the recommended, least-privilege pattern.

## Consequences
- Testing rule: after adding a repo, verify fingerprint with `gpg --show-keys --with-colons /etc/apt/keyrings/<name>.gpg | grep ^fpr` and confirm pre-existing `archive.ubuntu.com` entries still resolve (testing skill §APT).
- New third-party repos must follow the same `keyrings/` + `signed-by=` pattern — never `apt-key`, never append to `/etc/apt/sources.list`.
