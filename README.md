<p align="center">
<img src="./distro/image.jpg">
</p>
<p align="center">
<img src="https://img.shields.io/badge/MADE%20IN-BANGLADESH-green?colorA=%23ff0000&colorB=%23017e40&style=for-the-badge">
<img src="https://img.shields.io/badge/Version-2.0-blue?style=for-the-badge">
</p>
<p align="center">
<img src="https://img.shields.io/badge/Written%20In-Bash-darkgreen?style=flat-square">
<img src="https://img.shields.io/badge/Open%20Source-Yes-darkviolet?style=flat-square">
<img src="https://img.shields.io/github/stars/afonsoft/modded-ubuntu?style=flat-square">
<img src="https://img.shields.io/github/issues/afonsoft/modded-ubuntu?color=red&style=flat-square">
<img src="https://img.shields.io/github/forks/afonsoft/modded-ubuntu?color=teal&style=flat-square">
<a href="https://github.com/afonsoft/modded-ubuntu/actions/workflows/shellcheck.yml"><img src="https://github.com/afonsoft/modded-ubuntu/actions/workflows/shellcheck.yml/badge.svg" alt="ShellCheck Status" style="max-width: 100%;"></a>
</p>
<p align="center"><b>Run Ubuntu GUI on your termux with much features.</b></p>

### Features

- Fixed Audio Output
- Lightweight {Requires at least 5GB Storage}
- 2 Browsers (Chromium & Mozilla Firefox)
- Supports Bangla Fonts
- VLC Media Player and MPV media player
- Visual Studio Code (buggy on armhf/armv7)
- Sublime Text Editor (only for arm64/aarch64)
- OpenCode CLI
- Git + GitHub CLI (gh)
- Essential Development Tools (build-essential, python3-pip, nodejs, npm, cmake, .NET SDK 10.0 + C# tooling)
- Easy for Beginners
- Comes with some cool themes.
- Kali linux tools installer. (Metasploit included)
- Ghost Framework and Wireshark included

### Installation (one-liner)
- Firstly install [Termux](https://termux.com) apk from [HERE](https://f-droid.org/repo/com.termux_118.apk)
- Then run the following single command in Termux:

```bash
curl -fsSL https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/install.sh | bash
```

This command updates Termux packages, installs `git`, `curl`, `wget`, `proot-distro` and `pulseaudio`, clones the repository and executes `setup.sh` automatically.
The full log is saved to `~/modded-ubuntu-install.log` so you can check the progress if the terminal seems stuck.

### Installation (manual)
If you prefer the manual method:

- Firstly install [Termux](https://termux.com) apk from [HERE](https://f-droid.org/repo/com.termux_118.apk)
- Secondly Clone the Repository & Run the setup File

   ```bash
    yes | pkg up
    ```
    ```bash
    pkg install git wget -y
     ```
     ```bash
    git clone --depth=1 https://github.com/afonsoft/modded-ubuntu.git
     ```
     ```bash
    cd modded-ubuntu
    ```
    ```bash
    bash setup.sh
    ```

- Then Restart your Termux & Type the following commands
```bash
   ubuntu
```
```bash
   bash user.sh
```
 
- Type your ubuntu root username. Must be lowercase & no space included.

 Restart your Termux

- Then for graphical user interface & Type the following commands
```bash
   sudo bash gui.sh
```

- **You have to note your VNC password !!**

- Ubuntu image is now successfully installed .

  - Type `vncstart` to run Vncserver
  - Type `vncstop` to stop Vncserver

- Install VNC VIEWER Apk on your Device. [Google Play Store](https://play.google.com/store/apps/details?id=com.realvnc.viewer.android&hl=en)

- Open VNC VIEWER & Click on + Button & Enter the Address `localhost:1` & Name anything you like
- Set the Picture Quality to High for better Quality
- Click on Connect & Input the Password 
- Enjoy :D

### Performance and Quality on Samsung S26 / High-DPI Devices

For high-resolution phones like the Samsung Galaxy S26, the default VNC geometry may look small or blurry.
The `vncstart` script now reads the `VNC_GEOMETRY` environment variable and has two optimized presets:

| Command | Resolution | Best for |
|---------|------------|----------|
| `vncstart` | `1440x720` (default) | Balanced performance |
| `vncstart-fhd` | `2340x1080` | Full-HD+ devices |
| `vncstart-qhd` | `3088x1440` | QHD+ screens like the S26 Ultra |

You can also set a custom geometry manually:
```bash
VNC_GEOMETRY=2400x1080 vncstart
```

Tips to get the best quality and lowest latency on the Samsung S26:
- Use the preset that matches your screen resolution in VNC Viewer.
- In VNC Viewer set **Picture Quality** to **High** and **Color Level** to **Full**.
- Run `s26-optimize` inside Ubuntu to apply XFCE performance tweaks (disables compositor, sets DPI).
- Disable the XFCE compositor if window dragging feels slow: `Settings Manager → Window Manager Tweaks → Compositor` → uncheck `Enable display compositing`.
- Disable XFCE animations: `Settings Manager → Settings Editor → xfwm4` set `general/vblank_mode` to `off`.
- Use `-zliblevel 0` (already set) for local connections to reduce CPU usage.
- Keep the Termux wake-lock active (`termux-wake-lock`) during long sessions.

### Development Tools

During `sudo bash gui.sh` you can install:

- **Visual Studio Code:** install via Microsoft APT repository (skipped on 32-bit ARM).
- **OpenCode CLI:** install Node.js 22.x from NodeSource and `@opencode-ai/cli` globally.
- **Git + GitHub CLI (gh):** add Git and the official `gh` APT repository.
- **Essential Dev Stack:** `build-essential`, `python3-pip`, `python3-venv`, `nodejs`, `npm`, `cmake`, `make`, `gcc`, `g++`.
- **.NET SDK 10.0 + C# tooling:** instala o SDK 10.0 (com fallback para 9.0/8.0), adiciona as ferramentas globais `dotnet-ef` e `dotnet-aspnet-codegenerator`, e instala as extensões C# do VS Code quando o editor está presente. Usa os repositórios Ubuntu quando disponíveis e evita conflitos de pacotes Microsoft/Ubuntu.

### NOTE :

- **Type `ubuntu` to run Ubuntu CLI.**
- **Type `vncstart` to run Vncserver**
- **Type `vncstop` to stop Vncserver**
- **Type `bash remove.sh` to remove Ubuntu Modded Os**

### Auto-start VNC Server
If you want to automatically start the VNC server when you log in, add `vncstart` to your `.bashrc`:
```bash
echo "vncstart" >> ~/.bashrc
```

### Video Tutorial : 

[![Watch the Tutorial](./distro/image1.jpg)](https://mega.nz/embed/QvIC1TLQ#3z27MRNPwANAg6JTtx1Ei8kDouOZsZgk00bg4TsJMNQ!1m)

#
### Click to see the [Changelog](./CHANGELOG.md)
Licensed under [Apache License](./LICENSE)
#

### Credits : 

```
This Tool Uses the ubuntu image provided by the termux package `proot-distro` 

Full Credit of the Ubuntu image goes to them .

Termux Proot Distro - https://github.com/termux/proot-distro
```

### If you like our work then dont forget to give a Star :)

## Maintainers

**Developed by by <a href="https://github.com/BDhackers009">Mustakim Ahmed</a>** & **Developed by<a href="https://github.com/htr-tech">Tahmid Rayat</a>**

**Developed by <a href="https://github.com/Mahfuz-THBD">0xBaryonyx</a>** & **Enhanced by <a href="https://github.com/Midohajhouj">MIDØ</a>**
