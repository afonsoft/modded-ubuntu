# ADR-006: Chromium via XtraDeb PPA + `--no-sandbox` shim

## Status
Accepted

## Date
2026-09-20 (documented; landed 2026-09-01, commit `a2a04f4`)

## Context
Recent Ubuntu (resolute/26.04) ships Chromium only as a **snap** — and snapd cannot run inside proot (needs systemd + real mounts). Users still need a mainstream browser option in the desktop.

## Decision
`distro/chromium.sh` + `distro/setup_xtradeb.sh` add the **XtraDeb PPA** (which publishes real `.deb` builds for `resolute/main amd64`), install `chromium`, and drop a shim at `/usr/local/bin/chromium`:

```
exec /usr/bin/chromium --no-sandbox --disable-gpu --disable-software-rasterizer --disable-dev-shm-usage "$@"
```

`.desktop` files are rewritten to point at the shim (`chromium.sh:63-78`).

## Alternatives Considered

### Snap / snapd inside proot
- Rejected: snapd requires systemd and real mount namespaces — impossible under proot.

### Firefox only (no Chromium)
- Viable fallback (`distro/firefox.sh` exists), but users asked for Chromium; XtraDeb keeps it a `.deb`.

### Debian chromium .deb / manual tarball
- Pros: no third-party PPA.
- Cons: dependency mismatches on resolute; manual updates.
- Rejected: XtraDeb tracks Ubuntu releases properly.

## Consequences
- **Security trade-off**: `--no-sandbox` disables Chromium's sandbox — required because proot cannot create the needed namespaces. Documented limitation; the browser runs with full user privileges.
- Third-party PPA trust: XtraDeb is now a supply-chain dependency — helper must never append to `/etc/apt/sources.list` (testing skill §APT asserts `md5sum` before/after) and keys go to `/etc/apt/keyrings/`.
- GPU absent → `--disable-gpu` flags are mandatory; a missing window is an env/flag problem, not a shim bug (testing skill §chromium).
