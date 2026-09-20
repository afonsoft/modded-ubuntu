# ADR-008: Versioned xfconf XML + `xfce-apply --all`

## Status
Accepted

## Date
2026-09-20 (documented; `--all` multi-user apply landed 2026-08-17, commit `53e3503`)

## Context
The desktop layout (top panel + bottom dock, themes, wallpaper, Whisker favorites) must be reproducible across installs and re-applicable on `--update`. XFCE stores config in xfconf channels backed by XML — but `xfconfd` also persists *runtime* overrides, so live state and shipped state drift.

## Decision
Version the canonical desktop config as XML in `distro/xfce-config/` (xfconf channel XML + `.desktop` launchers + autostart). `distro/xfce-apply.sh` applies it, and `--all` iterates over user homes so customizations land for every user (including root — commit `81ba74a`). Wallpaper resolution prefers `$HOME/.config/xfce4/wallpaper/*.jpg` via an autostart `set-wallpaper` call.

## Alternatives Considered

### Runtime `xfconf-query -s` calls only (no versioned files)
- Pros: no XML maintenance.
- Cons: not diffable/reviewable; nothing to re-apply on update; per-user drift invisible.
- Rejected.

### Copy skeleton `/etc/skel` only
- Pros: standard mechanism for new users.
- Cons: does nothing for *existing* users on `--update`.
- Rejected: `--all` must cover existing homes too.

## Consequences
- **Testing gotcha**: `xfconfd` writes live state back on session end — `rm -rf <home>/.config` before re-testing shipped XML, and assert live values via `xfconf-query`, not file greps (testing skill §xfce).
- Panel geometry can only be judged via `xwininfo`/`xprop _NET_WORKAREA` — XML `p=` values render differently across XFCE/TigerVNC versions.
- Adding a desktop customization = edit the XML in `xfce-config/`, not a one-off `xfconf-query`.
