# Short-term Memory — modded-ubuntu

- **Active branch**: `feature/devin-20260922-e2e-defects-p2` (off master @ `319e489`, post PR #70 merge)
- **Task**: Fix the three defects from `.specs/SPEC-20260920-e2e-defects.md` (PR #69) — user asked "atualize e leia as issues do github"; no open GitHub issues exist, defects in the merged SPEC are the actionable items.
- **Status**: DEF-01/02/03 implemented + verified in termux-docker E2E (`mu-test` container, VNC :1 1440x720).
- **DEF-03** (merged PR #70): `x11-utils` added to `packs` in `distro/gui.sh`; xprop/xwininfo/xdpyinfo verified in rootfs.
- **DEF-01 root cause** (this branch): NOT the struts flag — `position p=1` maps to `SNAP_POSITION_E` in xfce4-panel 4.20.7's enum → `STRUTS_EDGE_NONE` for horizontal panels. Fix: `p=11` (SNAP_POSITION_N) in `distro/xfce-config/xfconf/xfce4-panel.xml` + `ensure_panel_struts` writes `position`, `enable-struts=true` (4.19+ name) and `disable-struts=false` (older). Verified: `_NET_WORKAREA = 0,34,1440,686`.
- **DEF-02** (this branch): `xfce4-panel -r` opens a blocking GTK error dialog when the session bus is unreachable → now `timeout 5` guarded; on timeout only pkill+setsid-respawn when `xfconf-query -l` works (otherwise respawn dies in `xfconf_init` and desktop is left panel-less). Verified: `xfce-apply --all` exits 0, exactly 3 panel windows, no new `<defunct>`.
- **Enum map** (4.20.7 `panel-window.c`): NONE=0, E=1, NE=2, EC=3, SE=4, W=5, NW=6, WC=7, SW=8, NC=9, SC=10, N=11, S=12. Struts for horizontal: only N*/S* (top/bottom) count; dock p=10=SC is correct.
- **Blockers**: none. Harness limit: session dbus unreachable from a second `proot-distro login` (peer-cred rejection) — in-session xfconf-query path untested live but guarded.
- **Next action**: commit, push, PR, watch CI, final report.
