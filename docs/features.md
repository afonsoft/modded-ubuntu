# Features

## Install / update / remove

- `install.sh` — curl one-liner; installs Termux deps, clones repo, runs `setup.sh`; backs up existing `~/modded-ubuntu`; logs to `~/modded-ubuntu-install.log`.
- `setup.sh` — installs Ubuntu via `proot-distro`, copies `distro/*` into the rootfs, generates the `${PREFIX}/bin/ubuntu` wrapper (sound + `proot-distro login --no-sysvipc`).
- `update.sh` (Termux) + `distro/update-system.sh` (rootfs) — `git pull`, `apt` update, locale `en_US.UTF-8`, timezone `America/Sao_Paulo`, re-runs `gui.sh --update` so existing installs receive new options non-interactively.
- `remove.sh` — purges the proot-distro ubuntu install, wrappers and pulseaudio config.
- `fix-signal9.sh` — recovery helper for signal-9 kills.

## Desktop

- XFCE4 + TigerVNC (`vncstart`/`vncstop`/`vncstart-fhd`/`vncstart-qhd`), top bar + bottom dock layout, custom themes/cursors, wallpapers (`distro/set-wallpaper.sh` + autostart).
- Portuguese fonts/accent support.

## Optional tooling (menus in `distro/gui.sh`)

- IDEs/editors: Sublime Text, VS Code (+ extensions via `distro/vscode-ext.sh`), OpenCode CLI/Desktop.
- Dev stacks: essential build tools, .NET SDK 10.0 + C# tooling (`distro/csharp.sh`), Node.js LTS (`distro/nodejs.sh`), Angular CLI (`distro/angular.sh`), full-stack C#+Angular option.
- AI assistants: Claude Code CLI/Desktop, Antigravity CLI (`agy`), OpenCode, Devin CLI/Desktop.
- Browsers: Chromium (XtraDeb), Firefox.
- Media: VLC/MPV. Security: tools installer (minimal default), Ghost Framework, Wireshark, GIMP.
- Git + GitHub CLI.

## Not supported on armhf/armv7

VS Code, Sublime Text, OpenCode Desktop — skipped with a warning.
