# Technologies

| Layer | Technology | Version / Evidence |
|---|---|---|
| Scripts | Bash | 5.x — all `*.sh` must pass `bash -n` and `shellcheck -S warning` |
| Host runtime | Termux (Android) | `pkg` package manager; `pulseaudio`, `proot-distro` required |
| Container | PRoot / proot-distro | Ubuntu rootfs; test container = `termux/termux-docker:latest` (amd64, Ubuntu resolute 26.04) |
| Desktop | XFCE4 + TigerVNC | VNC port 5901; config XML in `distro/xfce-config/` |
| Audio | PulseAudio | `~/.sound` config loaded by the `ubuntu` wrapper |
| Shell (optional) | zsh + assets | `distro/zsh-assets/` |
| CI | GitHub Actions | `ubuntu-latest` — `bash-syntax`, `shellcheck`, `termux-test` |

## External services / install sources

| Source | Used by | Purpose |
|---|---|---|
| NodeSource `.deb` | `distro/nodejs.sh` | Node.js LTS (no NVM in current flow) |
| Microsoft / Ubuntu repos | `distro/csharp.sh` | .NET SDK 10.0 (fallback: `dotnet-install.sh`) |
| XtraDeb PPA | `distro/setup_xtradeb.sh`, `distro/chromium.sh` | Chromium on Ubuntu resolute |
| VS Code / vendor | `distro/gui.sh`, `distro/vscode-ext.sh` | VS Code arm64/amd64 + extensions |
| npm | `distro/gui.sh` | OpenCode CLI (fallback: official installer) |

> New external install sources are security-sensitive — see `.claude/RULES.md` escalation gates.

## Architecture guards

Features skipped on `armhf`/`armv7` (32-bit): VS Code, Sublime Text, OpenCode Desktop. The `arch` variable in `distro/gui.sh` gates them.
