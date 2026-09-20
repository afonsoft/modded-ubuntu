# SPEC-20260920-gap-analysis

## 0. Metadata

| Field | Value |
| --- | --- |
| Feature | Repo gap analysis (upstream parity + internal audit) |
| Type | Roadmap / Analysis |
| Stack | Bash / Infra / Docs |
| Repository | `github.com/afonsoft/modded-ubuntu` |
| Branch | `feature/devin-20260920-gap-analysis` |
| Status | Draft (analysis only — autonomy level 0) |
| Date | 2026-09-20 |
| Baseline | `master` @ `8988aa5`; upstream `modded-ubuntu/modded-ubuntu` @ `4f187c8` (v2.1.0) |

## 1. Summary

The fork is **159 commits ahead and 26 commits behind** upstream `modded-ubuntu/modded-ubuntu`
(merge-base `560c3a7`). Upstream released **v2.1.0 (2026-09-02)** after the fork diverged.

Most upstream v2.1.0 changes are already covered or superseded by the fork (Ubuntu 26.04,
`DEBIAN_FRONTEND=noninteractive`, GPG `dearmor` keyrings, `tigervnc-tools`, hardened
`vncstart`/`vncstop`, modular installers). The remaining gaps are listed below with evidence.

**No implementation in this SPEC** — each gap maps to a recommended follow-up SPEC.

## 2. Upstream parity matrix (v2.1.0 changes since merge-base)

| Upstream change | Evidence (upstream) | Fork status | Verdict |
| --- | --- | --- | --- |
| Ubuntu 26.04 base | CHANGELOG 2.1.0 | resolute 26.04 (CI `termux-test.yml`, docs) | ✅ Covered |
| Non-interactive apt (`DEBIAN_FRONTEND`, `TZ`) | `1633cfd`, `4fd66da` | exported in `user.sh:8`, `gui.sh:16`, `update-system.sh:10`, `update.sh:59` | ✅ Covered |
| Auto-run `user.sh` inside `setup.sh` | `9002e8d` | manual step (`setup.sh` prints "Run `ubuntu` first & then type `bash user.sh`") | 🔴 GAP-01 |
| Firefox via `packages.mozilla.org` APT + `--no-sandbox` shim | upstream `firefox.sh` | tarball install + `unset LD_PRELOAD` only; `MOZ_FAKE_NO_SANDBOX=1` comes from vendored `proot-distro.sh:393` | 🟡 GAP-02 (verify) |
| `bwrap_fix()` shim (`/usr/local/bin/bwrap`) | upstream `gui.sh:212-257` | no bwrap shim; Chromium runs with `--no-sandbox` | 🟡 GAP-02 (same fix) |
| `.config-done` idempotency markers | CHANGELOG 2.1.0 | idempotency via `gui.sh --update` + `xfce-apply --all` | ⚪ Diverged (equivalent) |
| Samsung audio/perf fixes | CHANGELOG 2.1.0 | `fix-signal9.sh`, `s26-optimize.sh`, `termux-s26.properties` | ⚪ Diverged (fork-specific) |
| Modular installers (chromium/vscode/sublime) | CHANGELOG 2.1.0 | `chromium.sh` + menu-integrated vscode/sublime + csharp/nodejs/angular/vscode-ext | ✅ Covered (superset) |
| GPG `dearmor` keyrings (no `apt-key`) | CHANGELOG 2.1.0 | `setup_xtradeb.sh` uses `gpg --dearmor` + `Signed-By` | ✅ Covered |
| `tigervnc-tools` in base packs | CHANGELOG 2.1.0 | `gui.sh:120` | ✅ Covered |
| apt retry loop (50 attempts on lock) | upstream `setup_xtradeb.sh` | fork fails fast (`set -u`) | 🔴 GAP-03 |
| Comprehensive `.gitignore` | upstream `7061be6` | 1 line (`.claude/settings.local.json`) | 🔴 GAP-04 |
| Version banner (`Version: 2.1`) | upstream banners | no version string printed | 🟡 GAP-05 (cosmetic) |
| `vncstop` `~/.vnc` pid cleanup | upstream `42fa79e` | fork's `vncstop` is more robust (both dirs, `pkill`, lock cleanup) | ✅ Covered |

## 3. Internal gaps (docs ↔ code, dead code, quality gates)

| ID | Sev | Gap | Evidence |
| --- | --- | --- | --- |
| GAP-06 | P2 | **Dead systemd unit.** `distro/systemd/modded-ubuntu-vnc.service` is copied to `/etc/systemd/user/` by `update-system.sh:303-323`, but PRoot has no systemd — the unit can never start. `docs/README.md:32` also lists `distro/systemd/` in the architecture diagram. | `update-system.sh:303`; proot has no PID1/systemd |
| GAP-07 | P3 | **CHANGELOG malformed.** `[Unreleased]` contains two `### Added` sections; the NVM-based `nodejs.sh` entry is superseded by NodeSource (ADR-010); no version headings since fork history began. | `CHANGELOG.md` top |
| GAP-08 | P3 | **`docs/features.md` lags the code.** Missing: `s26-optimize`/`termux-s26.properties`, `zsh-setup` + `zsh-assets`, `fix-signal9.sh` details, `vncstart-fhd`/`vncstart-qhd`, `distro/systemd/`, `.specs/` template. `docs/README.md` itself says "update docs when changing code". | `docs/features.md` (27 lines) vs `distro/` |
| GAP-09 | P2 | **Runtime fetches pinned to `master` without integrity checks.** `gui.sh:220` downloads `tools.sh`; `update-system.sh:348` downloads `zsh-setup.sh`; `chromium.sh:28` downloads `setup_xtradeb.sh`; `update.sh`/`setup.sh` pull `vncstart*` from `master`. A broken/compromised `master` propagates to every live install/update. | grep `raw.githubusercontent.com/.../master` |
| GAP-10 | P3 | **CI E2E is thin.** `termux-test.yml` runs `setup.sh` then only `bash -n` inside proot — never exercises `user.sh` (which now supports non-interactive `MODDED_USER`/`MODDED_PASS`), `gui.sh --update`, or `update-system`. `bash-syntax.yml` exec-bit check warns instead of failing. | `.github/workflows/termux-test.yml` |
| GAP-11 | P4 | **`zsh-setup` log path inside proot.** `user.sh:131` writes to `${PREFIX:-/data/data/com.termux/files/usr}/tmp/zsh-setup.log` — inside the rootfs `PREFIX` is unset and the Termux path may not be bound, so the log may be lost. | `distro/user.sh` |

## 4. Fork-only additions (divergence record — not gaps)

`install.sh` one-liner (wake-lock, storage check, backup, log), `update.sh`/`update-system.sh`
idempotent `--update` flow, `fix-signal9.sh` (Phantom Process Killer), `s26-optimize` +
`termux-s26.properties`, `zsh-setup.sh` + vendored `zsh-assets`, `tools.sh` security installer,
AI assistants (Claude Code/Desktop, Antigravity, OpenCode, Devin), .NET 10/Node.js LTS/Angular
menus, `xfce-apply` + versioned xfconf XML + wallpapers, per-user `--user` wrapper, agent
harness (`.claude/`, `.devin/`, ADRs, `.specs/`), `docs/` + screenshots.

## 5. Recommended follow-up SPECs (priority order)

1. **SPEC: automate `user.sh` in `setup.sh`** (GAP-01, P2) — run
   `proot-distro login ubuntu -- env MODDED_USER=$u MODDED_PASS=$p bash /root/user.sh` when
   env vars are provided; keep the manual flow as fallback. Cuts one Termux restart + manual step.
2. **SPEC: fix VNC autostart story** (GAP-06, P2) — either remove `distro/systemd/` +
   `update_systemd_vnc_service()` and fix docs, or implement real autostart via XFCE autostart
   entry / shell profile hook (the mechanism already used by `set-wallpaper`).
3. **SPEC: pin remote fetches** (GAP-09, P2) — fetch from a release tag or verify a checked-in
   SHA-256 manifest before executing downloaded scripts.
4. **SPEC: docs & changelog sync** (GAP-04/07/08, P3) — port upstream `.gitignore`, fix
   `[Unreleased]` structure, refresh `docs/features.md` + `docs/packages.md`.
5. **SPEC: deepen `termux-test.yml`** (GAP-10, P3) — non-interactive `user.sh`, `gui.sh --update`,
   `update-system` smoke in the proot container; make exec-bit check fail.
6. **SPEC: verify Firefox in E2E** (GAP-02, P3) — launch `firefox --version`/headless in
   termux-docker; if sandbox errors appear, add the `--no-sandbox` shim and/or `bwrap_fix`.
7. **SPEC: apt retry helper** (GAP-03, P4) — small shared `apt_retry()` for proot apt-lock flakiness.
8. **SPEC: version banner + `zsh-setup` log path** (GAP-05/11, P4) — cosmetic/robustness fixes.

## 6. References

- Upstream: `github.com/modded-ubuntu/modded-ubuntu` v2.1.0 (CHANGELOG.md)
- Repo harness: `CLAUDE.md`, `.claude/RULES.md`, `docs/architecture/ADR-*.md`
- Previous audit: `.claude/memory/orchestrator_stats.md` (GAP-001..005, all closed)
- E2E guide: `.devin/skills/testing-modded-ubuntu/SKILL.md`
