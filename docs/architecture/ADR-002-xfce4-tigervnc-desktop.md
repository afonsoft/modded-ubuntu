# ADR-002: XFCE4 desktop served over TigerVNC

## Status
Accepted

## Date
2026-09-20 (documented; core choice predates the fork, VNC details refined 2026-08)

## Context
Users need a graphical desktop inside the proot Ubuntu. The display must reach the Android screen somehow, and ideally also be reachable from other machines (README documents LAN VNC access).

## Decision
XFCE4 as the desktop environment + TigerVNC (`tigervnc-standalone-server`) on display `:1` (port 5901), started via `distro/vncstart` with `-localhost no` (LAN-accessible), `-rfbauth` password file, and geometry presets (`vncstart`, `vncstart-fhd`, `vncstart-qhd`).

## Alternatives Considered

### Termux:X11 / XFCE over native Android X server
- Pros: hardware-accelerated, lower latency, no VNC client needed.
- Cons: requires the Termux:X11 companion app, trickier per-device setup, no remote access, less mature on some devices.
- Rejected: VNC is app-agnostic (any viewer works) and doubles as remote access.

### XServer XSDL
- Pros: simple, no extra packages in rootfs.
- Cons: poor performance, dated UX, no remote access.
- Rejected.

### Heavier DEs (GNOME/KDE) or lighter (LXDE/Openbox)
- GNOME/KDE: too heavy for proot+phone hardware, and depend on systemd/logind paths that don't exist in proot.
- LXDE/Openbox: lighter but far less polished for the "modded" UX goal.
- Chosen: XFCE4 — the sweet spot of polish vs. footprint, fully scriptable via `xfconf`.

## Consequences
- Desktop is reachable locally (`127.0.0.1:5901`) and on LAN — security posture relies on the `-rfbauth` password (default `modded` when headless, see ADR-005).
- XFCE state is versioned as xfconf XML (`distro/xfce-config/`) and applied via `xfce-apply` — see ADR-008.
- VNC lifecycle is script-managed because there is no systemd in proot — see ADR-005.
