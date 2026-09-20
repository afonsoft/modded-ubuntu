# Packages

## Termux host (`pkg`)

| Package | Installed by | Purpose |
|---|---|---|
| `proot-distro` | `install.sh`, `setup.sh`, CI | Ubuntu rootfs runtime |
| `pulseaudio` | `install.sh`, `setup.sh`, CI | Audio forwarding (`~/.sound`) |
| `git`, `curl`, `wget` | `install.sh` | Clone + downloads |

## Ubuntu rootfs (`apt`) — highlights

| Group | Examples | Script |
|---|---|---|
| Desktop | `xfce4`, `xfce4-goodies`, `tigervnc-standalone-server`, fonts, themes, cursors | `distro/gui.sh` (`packs` array) |
| Browsers (optional) | `chromium` (XtraDeb), `firefox` | `distro/chromium.sh`, `distro/firefox.sh` |
| Dev tools (optional) | `build-essential`, `python3-pip`, `python3-venv`, `cmake`, `make`, `gcc`, `g++` | `distro/gui.sh` dev menu |
| .NET (optional) | .NET SDK 10.0 + `libicu-dev`, `libssl3`, `libgdiplus` | `distro/csharp.sh` |
| Node.js (optional) | Node.js LTS via NodeSource | `distro/nodejs.sh` |
| Media (optional) | `vlc`, `mpv` | `distro/gui.sh` |
| Security tools (optional) | minimal mode default; Ghost Framework, Wireshark | `distro/tools.sh`, `distro/gui.sh` |

> Source of truth: the `packs` arrays and `apt-get install` calls inside each `distro/*.sh`. Update this table when adding/removing packages.
