# ADR-005: VNC without external `dbus-launch` / systemd

## Status
Accepted

## Date
2026-09-20 (documented; fixes landed 2026-08-16, commits `6b757f5`, `4efe6c1`, `5c6b1ae`)

## Context
Early `vncstart` hung in proot: launching the VNC server through `dbus-launch` deadlocks inside proot (no real dbus/systemd machinery — commits `6b757f5`, `05e4d56`). Password management also hung headless, and TigerVNC versions differ in binary names and config locations.

## Decision
`distro/vncstart` runs `vncserver`/`tigervncserver` **directly** — `xfce4-session` spawns its own dbus when needed (`vncstart:73-76`). Password: TTY → interactive prompt; headless → write default `modded` via `vncpasswd -f`, `chmod 600`. Both config roots (`~/.vnc` and `~/.config/tigervnc`) are created since TigerVNC migrated paths. An optional `distro/systemd/modded-ubuntu-vnc.service` exists for non-proot contexts but is a no-op inside proot.

## Alternatives Considered

### Keep dbus-launch wrapper
- Rejected: proven hang in proot; xfce4-session handles session bus itself.

### Require interactive password always
- Rejected: blocks CI/headless installs; default password + documented `vncpasswd` escape is better.

### Manage VNC via systemd inside proot
- Rejected: systemd cannot run as init inside proot; the shipped unit only helps when the same rootfs runs where systemd exists.

## Consequences
- Default VNC password `modded` exists on headless installs — documented; user must change it (`vncpasswd`).
- Log location is `~/.config/tigervnc/<host>:1.log` on modern TigerVNC (not `~/.vnc/*.log`) — testing skill §GUI.
- `vncstop`/`vncstart` are the service manager; no daemon supervision inside proot.
