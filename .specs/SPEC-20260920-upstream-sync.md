# SPEC-20260920: Upstream Sync (v2.1.0) — Analysis & Selective Port

## Metadata
- **Baseline**: fork `master` @ `e034743` (post PR #66/#67), upstream `modded-ubuntu/modded-ubuntu` @ `4f187c8` (v2.1.0)
- **Merge-base**: `560c3a7`; upstream delta: 26 commits
- **Strategy**: selective port — both sides rewrote the same files, so a raw `git merge` would produce conflict noise without gaining the fork's improvements (non-interactive install, MODDED_GIT_REF, bilingual docs, harness). Upstream deltas were classified as **port** (real improvement), **superseded** (fork already does it better) or **skip** (deliberate divergence / cosmetic).

## Ported (upstream → fork)

| # | Item | Where |
|---|------|-------|
| S1 | Pin distro image `proot-distro install ubuntu:26.04` (was unpinned `ubuntu` → drifts with `latest`) | `setup.sh` |
| S2 | Sudoers via drop-in `/etc/sudoers.d/90-modded-ubuntu` (mode 0440, atomically idempotent) instead of appending to `/etc/sudoers` | `distro/user.sh` |
| S3 | `set -u` + `set -o pipefail` hardening | `distro/user.sh` |
| S4 | Patch `/usr/share/applications/*chromium*.desktop` to add `--no-sandbox` so GUI launchers work under PRoot (shim alone only covers PATH) | `distro/chromium.sh` |
| S5 | `apt-get --fix-broken install -y` before the package loop | `distro/gui.sh` |
| S6 | Delete empty `.vscode/settings.json` | repo root |
| S7 | Whitespace normalization in `patches/code.desktop` | `patches/` |

## Superseded by the fork (no action)

| Item | Fork equivalent |
|------|-----------------|
| Automate `user.sh` in `setup.sh` | `MODDED_USER`/`MODDED_PASS` non-interactive path (PR #67) — upstream's is unconditional interactive |
| `~/.vnc` path fix in `vncstop` | Fork's vncstop handles `~/.vnc` + `~/.config/tigervnc`, `pkill`, stale locks |
| `[ -f ~/.sound ]` guards in `remove.sh` | Already present |
| `.sound` heredoc, wrapper shebang/`exec` | Fork wrappers already have shebang + `exec` + `.sound` |
| tzdata non-interactive | `DEBIAN_FRONTEND=noninteractive` + `policy-rc.d` + explicit tzdata config |
| `~/.sound` writes, storage setup | Fork already superset |
| `username` detection via `SUDO_USER` | Fork's `detect_user()` (SUDO_USER → logname → /etc/passwd scan) |

## Deliberately skipped (divergence documented)

- **Firefox via `packages.mozilla.org` APT** — upstream switched from PPA to the official Mozilla APT repo with pin-priority and a `--no-sandbox` shim. Fork uses the Mozilla tarball to `/opt/firefox` + `LD_LIBRARY_PATH` + `MOZ_DISABLE_*_SANDBOX`/`MOZ_FAKE_NO_SANDBOX` env exports (PR #67). Both solve the sandbox issue; the tarball gives version control independent of APT. Revisit if `/opt` installs prove hard to update.
- **`distro/vscode.sh`/`distro/sublime.sh` standalone scripts** — fork keeps these as `gui.sh` menu functions with `armhf`/`armv7` arch guards (upstream scripts lack guards and would install on unsupported 32-bit ARM).
- **`~/softwares/` script copies** — fork exposes helpers via `/usr/local/bin` (`csharp-setup`, `node-setup`, `angular-setup`, ...), no home-dir copies needed.
- **`Version : 2.1` banner line** — cosmetic; fork's version story is its own (GAP-05 stayed skipped).
- **`tigervnc` metapackage in gui.sh packs** — fork intentionally lists `tigervnc-standalone-server tigervnc-common tigervnc-tools` (smaller footprint).
- **Upstream README revamp** — fork's bilingual README is a superset and still references `distro/image.jpg`/`image1.jpg`, which upstream deleted.
- **Upstream CHANGELOG 2.1.0 entry** — fork keeps its own `[Unreleased]` history; sync recorded in this SPEC.
- **`TZ=Etc/UTC` export in gui.sh** — fork deliberately sets `America/Sao_Paulo` + `en_US.UTF-8`.
- **`set -e` in user.sh** — upstream uses `set -euo pipefail`; fork ports `set -u` + `pipefail` only, because `banner()` calls `clear` which fails when `TERM` is unset (non-interactive proot/CI path added by the fork).

## Verification
- `bash -n` + `shellcheck -S warning` on the repo lint list; `xmllint` on xfconf XMLs.
- CI `termux-test.yml` E2E runs `setup.sh` + non-interactive `user.sh` — validates S1–S3 end-to-end.
