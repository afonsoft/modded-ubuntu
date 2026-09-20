# docs/ — modded-ubuntu

System documentation for the Ubuntu XFCE4 environment that runs inside Termux (Android) via `proot-distro`.

- [technologies.md](technologies.md) — stack, versions and external services
- [packages.md](packages.md) — packages installed by each script (Termux `pkg` vs rootfs `apt`)
- [features.md](features.md) — user-facing functionality and optional components
- [screenshots/](screenshots/) — VNC captures of the desktop

> **Rule:** when changing code, consult `docs/` before and update it after.

## Architecture at a glance

```
Android/Termux (host)
  install.sh ── curl one-liner: pkg deps + clone + run setup.sh
  setup.sh ──── installs proot-distro ubuntu, copies distro/* into rootfs,
                generates ${PREFIX}/bin/ubuntu wrapper (sound + proot login)
  update.sh ─── git pull + refresh scripts on existing installs
  remove.sh ─── purge proot-distro ubuntu + wrappers + pulseaudio config

Ubuntu rootfs (proot)
  distro/user.sh ─────── non-root user, sudo, per-user wrapper (--user flag)
  distro/gui.sh ──────── XFCE4 + TigerVNC + fonts/themes + tool menus
                          (--update: idempotent re-run for existing installs)
  distro/update-system.sh apt update + gui.sh --update + locale/timezone
  distro/*.sh ────────── per-feature installers (csharp, nodejs, angular,
                          firefox, chromium, vscode-ext, xfce-apply, ...)
  distro/xfce-config/ ── versioned xfconf XML, desktop files, autostart
  distro/zsh-assets/ ─── zsh theme/plugin assets (excluded from shellcheck CI)
  distro/systemd/ ────── systemd-related assets
```

Details of the VNC/desktop testing workflow: `.devin/skills/testing-modded-ubuntu/SKILL.md`.
