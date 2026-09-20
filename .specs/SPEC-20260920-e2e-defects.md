# SPEC-20260920: E2E Defects — findings from termux-docker run on `master`

## Metadata
- **Baseline**: fork `master` @ merged state of PRs #66/#67/#68
- **Environment**: `termux/termux-docker:latest` (amd64, Ubuntu resolute 26.04 rootfs), XFCE session over TigerVNC `127.0.0.1:5911→5901`
- **Evidence**: `~/modded-ubuntu-test/artifacts/` (desktop-full.png, maximized-under-panel-DEFECT.png, dock-zoom.png, *.log, test-plan.md); recording `rec-77499ebb`
- **Status**: Draft — findings documented; fixes listed as proposed actions (require decision on DEF-01 approach)

## Findings

### DEF-01 (P2 — real UX defect): xfce4 panels announce no window struts

- **Symptom**: all three `xfce4-panel` windows report `_NET_WM_STRUT`/`_NET_WM_STRUT_PARTIAL: not found`; `xprop -root _NET_WORKAREA` stays `0,0,1600,1127` (full screen). Maximizing a window puts its titlebar **under** the always-on-top top panel — proof: `maximized-under-panel-DEFECT.png`.
- **State**: shipped XML `distro/xfce-config/xfconf/xfce4-panel.xml` sets `disable-struts=true` only for panel-2 (intended: dock floats over windows). In the live xfconf channel `disable-struts` is **absent for both panels**, so panel-1 defaults to struts enabled — yet xfwm4 receives none.
- **Hypothesis (unconfirmed)**: xfce4-panel version on resolute changed strut emission, or struts are only set when the panel's position is locked in a way our config doesn't produce. Not introduced by PRs #66–#68 (none touched panel config); likely latent since the resolute base.
- **Proposed fix options** (pick one during implementation):
  1. Write `disable-struts=false` explicitly for panel-1 via `xfconf-query -c xfce4-panel -p /panels/panel-1/disable-struts -s false` inside `xfce-apply --all`, then `xfce4-panel -r`.
  2. If struts still don't materialize, treat as XFCE/resolute quirk: pin `xfce4-panel` version or set `_NET_WORKAREA` workaround via `wmctrl`/`xprop` in session startup.
- **Acceptance**: `xprop -root _NET_WORKAREA` shrinks by the top panel height (e.g. `0,34,1600,1093`); a maximized window's titlebar is fully visible below the top panel.

### DEF-02 (P3 — cosmetic/leak): in-session `xfce-apply --all` leaves stale dock window + defunct process

- **Symptom**: after `xfce-apply --all` inside a live session, `xwininfo -root -tree` lists two `320x52` dock windows (old `+640+1075`, new `+640+1124` — the new one partially below the 1127px screen) and `pgrep` shows `[xfce4-panel] <defunct>`.
- **Cause**: `reload_panel()` in `distro/xfce-apply.sh` doesn't cleanly restart xfce4-panel — the old panel process is killed but the dock window leaks and the new panel spawns before xfconfd settles.
- **Proposed fix**: make `reload_panel()` deterministic — `xfce4-panel -q`, wait for process exit (`while pgrep -x xfce4-panel; do sleep 0.2; done` with timeout), then `xfce4-panel` in background; or use `xfce4-panel -r` (built-in restart) only.
- **Acceptance**: after `xfce-apply --all` in a live session, `xwininfo -root -tree | grep 'xfce4-panel"'` returns exactly 3 windows (2 panels + 10x10 helper), `pgrep -a xfce4-panel` shows no `<defunct>`.

### DEF-03 (P3 — diagnostics gap): `x11-utils` not installed

- **Symptom**: `xprop`/`xwininfo`/`xdpyinfo` absent — every in-session geometry/strut assert in `.devin/skills/testing-modded-ubuntu/SKILL.md` needs them installed manually.
- **Proposed fix**: add `x11-utils` to the `packs` array in `distro/gui.sh` (`package()`).
- **Acceptance**: `command -v xprop xwininfo xdpyinfo` all present after `gui.sh` runs.

## Test coverage gaps (not defects — noted for future SPECs)

- Chromium via XtraDeb PPA not exercised (skill documents it as slow/flaky in docker).
- `update.sh` (Termux side), `remove.sh`, `distro/tools.sh` menu paths untested.
- Real Android/Termux differences (aaudio sink, phantom-process killer, storage access) — docker-only approximations.
- Host-mounted `/termux-logs` is not visible inside `proot-distro login` (only termux home is bound) — in-proot test artifacts must be staged under `~/test-logs`. Documented in the testing skill.

## Task Plan

- [ ] T1 — DEF-03: add `x11-utils` to `packs` (trivial).
- [ ] T2 — DEF-02: deterministic `reload_panel()` in `xfce-apply.sh`.
- [ ] T3 — DEF-01: investigate root cause in live session; implement option 1 or 2; verify `_NET_WORKAREA`.
- [ ] T4 — Lint (`bash -n`, `shellcheck -S warning`, `xmllint`) + E2E re-run of the affected panel path.
