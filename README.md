<p align="center">
<img src="./distro/image.jpg" alt="Modded Ubuntu no Termux">
</p>

<p align="center">
<img src="https://img.shields.io/badge/MODIFICADO%20NO-BRASIL-green?colorA=%23009c3b&colorB=%23ffdf00&style=for-the-badge" alt="Modificado no Brasil">
<img src="https://img.shields.io/badge/Version-2.0-blue?style=for-the-badge" alt="Version 2.0">
<img src="https://img.shields.io/badge/License-Apache%202.0-orange?style=for-the-badge" alt="Apache 2.0 License">
</p>

<p align="center">
<img src="https://img.shields.io/badge/Written%20In-Bash-darkgreen?style=flat-square" alt="Bash">
<img src="https://img.shields.io/badge/Open%20Source-Yes-darkviolet?style=flat-square" alt="Open Source">
<img src="https://img.shields.io/github/stars/afonsoft/modded-ubuntu?style=flat-square" alt="Stars">
<img src="https://img.shields.io/github/issues/afonsoft/modded-ubuntu?color=red&style=flat-square" alt="Issues">
<img src="https://img.shields.io/github/forks/afonsoft/modded-ubuntu?color=teal&style=flat-square" alt="Forks">
<a href="https://github.com/afonsoft/modded-ubuntu/actions/workflows/shellcheck.yml"><img src="https://github.com/afonsoft/modded-ubuntu/actions/workflows/shellcheck.yml/badge.svg" alt="ShellCheck Status" style="max-width: 100%;"></a>
</p>

<p align="center"><b>Execute o Ubuntu com interface gráfica (XFCE4) dentro do Termux no Android.</b></p>
<p align="center"><i>Run Ubuntu with a graphical desktop (XFCE4) inside Termux on Android.</i></p>

---

## Sobre / About

O **modded-ubuntu** é um ambiente Ubuntu personalizado e otimizado para rodar em dispositivos Android através do [Termux](https://termux.com/) e do [PRoot](https://proot-me.github.io/). Este repositório é uma **versão modificada no Brasil**, mantida por [Afonso Dutra](https://github.com/afonsoft), com foco em desenvolvimento, produtividade e pentest no ecossistema mobile.

> **modded-ubuntu** is a customized Ubuntu environment designed to run on Android devices via [Termux](https://termux.com/) and [PRoot](https://proot-me.github.io/). This repository is a **Brazilian-modified version**, maintained by [Afonso Dutra](https://github.com/afonsoft), focused on development, productivity, and mobile pentesting.

## Recursos / Features

- Saída de áudio corrigida / Fixed audio output
- Leve — a partir de ~3 GB de armazenamento (5 GB+ recomendado para dev tools e navegadores) / Lightweight — from ~3 GB of storage (5 GB+ recommended for dev tools and browsers)
- Navegadores opcionais: Chromium e Mozilla Firefox / Optional browsers: Chromium and Mozilla Firefox
- Suporte a fontes e acentuação em português / Portuguese font and accent support
- VLC/MPV Media Player (opcional) / VLC/MPV media player (optional)
- Visual Studio Code (`arm64`/`aarch64` e x64; pulado em `armhf`/`armv7` 32-bit) / Visual Studio Code (arm64/aarch64 and x64; skipped on 32-bit armhf/armv7)
- Sublime Text Editor (`arm64`/`aarch64` e x64; pulado em `armhf`/`armv7` 32-bit) / Sublime Text Editor (arm64/aarch64 and x64; skipped on 32-bit armhf/armv7)
- OpenCode CLI (opcional) / OpenCode CLI (optional)
- Git + GitHub CLI (`gh`) (opcional) / Git + GitHub CLI (`gh`) (optional)
- Ferramentas essenciais de desenvolvimento (opcional) / Essential development tools (optional):
  - `build-essential`, `python3-pip`, `python3-venv`
  - `nodejs`, `npm`, `cmake`, `make`, `gcc`, `g++`
- .NET SDK 10.0 + ferramentas C# (opcional) / .NET SDK 10.0 + C# tooling (optional)
- Node.js LTS instalado diretamente via NodeSource .deb (sem NVM) / Node.js LTS installed directly via NodeSource .deb (no NVM)
- Angular 20 CLI + extensões do VS Code: (opcional) / Angular 20 CLI + VS Code: extensions (optional)
- Instalação full-stack C# + Angular (opcional) / Full-Stack C# + Angular install option (optional)
- Assistentes de IA para código (opcionais) / AI coding assistants (optional):
  - **Claude Code CLI** (`claude`)
  - **Antigravity CLI** (`agy`)
  - **Devin CLI** (`devin`)
  - **Devin Desktop** IDE (instalação via APT; depende da arquitetura do dispositivo)
- Fácil para iniciantes / Beginner-friendly
- Temas e cursores personalizados / Custom themes and cursors
- Instalador de ferramentas de segurança (modo minimal por padrão) / Security tools installer (minimal by default)
- Ghost Framework, Wireshark e GIMP (opcionais) / Ghost Framework, Wireshark and GIMP (optional)

## Requisitos / Requirements

- Android 8.0 ou superior / Android 8.0 or higher
- [Termux](https://termux.com/) instalado pelo F-Droid / [Termux](https://termux.com/) installed from F-Droid
- A partir de ~3 GB de armazenamento livre (5 GB+ recomendado para dev tools e navegadores) / From ~3 GB of free storage (5 GB+ recommended for dev tools and browsers)
- Conexão Wi-Fi recomendada para downloads grandes / Wi-Fi connection recommended for large downloads

## Instalação automática / One-liner installation

1. Instale o Termux pelo F-Droid: <a href="https://f-droid.org/repo/com.termux_118.apk">Download Termux 118</a>
2. Execute o comando abaixo no Termux: / Run the following single command in Termux:

```bash
curl -fsSL https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/install.sh | bash
```

Este comando atualiza os pacotes do Termux, instala `git`, `curl`, `wget`, `proot-distro` e `pulseaudio`, clona o repositório e executa o `setup.sh` automaticamente. O log completo é salvo em `~/modded-ubuntu-install.log`, então você pode acompanhar o progresso mesmo que o terminal pareça travado.

> This command updates Termux packages, installs `git`, `curl`, `wget`, `proot-distro` and `pulseaudio`, clones the repository and runs `setup.sh` automatically. The full log is saved to `~/modded-ubuntu-install.log` so you can check the progress if the terminal seems stuck.

## Instalação manual / Manual installation

Se preferir o método manual: / If you prefer the manual method:

1. Instale o Termux pelo F-Droid: <a href="https://f-droid.org/repo/com.termux_118.apk">Download Termux 118</a>
2. Atualize os pacotes e instale as dependências básicas: / Update packages and install basic dependencies:

```bash
yes | pkg up
pkg install git wget curl proot-distro pulseaudio -y
```

3. Clone este repositório: / Clone this repository:

```bash
git clone --depth=1 https://github.com/afonsoft/modded-ubuntu.git
cd modded-ubuntu
```

4. Execute o instalador: / Run the installer:

```bash
bash setup.sh
```

5. Reinicie o Termux e crie o usuário: / Restart Termux and create the user:

```bash
ubuntu
bash user.sh
```

   - Digite um nome de usuário root em minúsculas, sem espaços. / Type a lowercase root username with no spaces.
   - Opcionalmente, crie o usuário sem interação: / Optionally create the user non-interactively:
     ```bash
     MODDED_USER=meuuser MODDED_PASS=minhasenha bash user.sh
     ```

6. Reinicie o Termux novamente. / Restart Termux again.

7. Inicie a interface gráfica: / Start the graphical interface:

```bash
sudo bash gui.sh
```

8. Anote a senha do VNC! / Write down your VNC password!

9. O Ubuntu está instalado. Use: / Ubuntu is installed. Use:

- `vncstart` — iniciar o VNC server / start VNC server
- `vncstop` — parar o VNC server / stop VNC server

10. Instale o [VNC VIEWER](https://play.google.com/store/apps/details?id=com.realvnc.viewer.android&hl=pt) no Android.
11. Abra o VNC VIEWER, clique em `+`, adicione o endereço `localhost:1` e dê um nome qualquer. / Open VNC VIEWER, tap `+`, enter the address `localhost:1` and give it any name.
12. Defina a qualidade da imagem como **Alta** para melhor qualidade. / Set Picture Quality to **High** for better quality.
13. Conecte-se e digite a senha. Aproveite! / Connect and enter the password. Enjoy!

## Dicas para o Termux / Termux tips

Para que a instalação longa (rootfs, Node.js, Angular, .NET, CLIs de IA etc.) termine sem ser interrompida:

- **Mantenha a tela ligada** durante o setup: o `install.sh` usa `termux-wake-lock`/`termux-wake-unlock` automaticamente quando o Termux:API está disponível.
- **Desative a otimização de bateria** do Termux e do Termux:API nas configurações do Android; isso evita que o sistema mate o processo em instalações longas (Android 12+).
- **Use Wi-Fi e carregador** — o download do rootfs e dos pacotes pode consumir bastante dados e bateria.
- **Permissão de armazenamento**: o setup executa `termux-setup-storage` se necessário. Aceite a permissão quando o Android perguntar.
- **Depois de instalar**, reinicie o Termux e use `ubuntu` para entrar no CLI, depois `sudo bash gui.sh` para o menu gráfico/ferramentas.

## Erro `[Process completed (signal 9) - press Enter]` / `[Process completed (signal 9) - press Enter]` error

Esse erro ocorre no Android 12+ (comum em aparelhos Samsung) quando o sistema Android mata processos em segundo plano do Termux, como o `vncserver`. Isso é causado pelo **Phantom Process Killer** do Android, que limita processos "fantasmas" em execução.

> This error happens on Android 12+ (common on Samsung devices) when the Android OS kills background Termux processes like `vncserver`. It is caused by the Android **Phantom Process Killer**, which limits running "phantom" processes.

### Soluções / Fixes

- **Android 14+:**
  - Acesse **Configurações → Opções do desenvolvedor** e ative **Desativar restrições de processos filhos** (Disable child process restrictions).
  - Restart o aparelho.
  - Go to **Settings → Developer Options** and enable **Disable child process restrictions**, then reboot.

- **Android 12, 12L e 13 (sem root / non-root):**
  - Ative a **Depuração USB** (USB debugging) nas Opções do desenvolvedor.
  - Conecte o celular a um PC com [Android Platform Tools](https://developer.android.com/tools/releases/platform-tools) e execute:
  - Enable **USB debugging** in Developer Options, connect the phone to a PC with [Android Platform Tools](https://developer.android.com/tools/releases/platform-tools), and run:

  ```bash
  # Android 12L e 13+
  adb shell "settings put global settings_enable_monitor_phantom_procs false"

  # Android 12
  adb shell "/system/bin/device_config set_sync_disabled_for_tests persistent; /system/bin/device_config put activity_manager max_phantom_processes 2147483647"
  ```

  - Reinicie o aparelho / Reboot the phone.

- **Aparelho com root / Rooted device:**
  - No Termux, execute com `su` e reinicie:
  - Run inside Termux with `su`, then reboot:

  ```bash
  # Android 12L e 13+
  su -c "settings put global settings_enable_monitor_phantom_procs false"

  # Android 12
  su -c "/system/bin/device_config set_sync_disabled_for_tests persistent; /system/bin/device_config put activity_manager max_phantom_processes 2147483647"
  ```

> **Atenção / Warning:** essas alterações podem ser revertidas por uma atualização do sistema. Reaplique os comandos se o erro voltar. / These changes may be reverted by a system update. Reapply the commands if the error returns.

## Performance e qualidade em Samsung S26 / dispositivos High-DPI

Para telas de alta resolução como o Samsung Galaxy S26, a geometria padrão do VNC pode parecer pequena ou borrada. O script `vncstart` lê a variável `VNC_GEOMETRY` e oferece dois presets otimizados:

| Comando | Resolução | Ideal para |
|---------|-----------|------------|
| `vncstart` | `1440x720` (padrão) | Equilíbrio de desempenho |
| `vncstart-fhd` | `2340x1080` | Dispositivos Full-HD+ |
| `vncstart-qhd` | `3088x1440` | Telas QHD+ como S26 Ultra |

Geometria personalizada: / Custom geometry:

```bash
VNC_GEOMETRY=2400x1080 vncstart
```

Dicas para melhor latência e qualidade no S26: / Tips for best quality and lowest latency on the S26:

- Use o preset que corresponda à resolução da tela no VNC Viewer.
- No VNC Viewer, defina **Picture Quality** para **High** e **Color Level** para **Full**.
- Execute `s26-optimize` dentro do Ubuntu para aplicar otimizações XFCE (desabilita compositor, ajusta DPI).
- Desabilite o compositor do XFCE se arrastar janelas parecer lento: `Settings Manager → Window Manager Tweaks → Compositor` e desmarque `Enable display compositing`.
- Desabilite animações do XFCE: `Settings Manager → Settings Editor → xfwm4` e defina `general/vblank_mode` para `off`.
- Use `-zliblevel 0` (já configurado) para conexões locais, reduzindo o uso de CPU.
- Mantenha o wake-lock ativo (`termux-wake-lock`) durante sessões longas.

## Ferramentas de desenvolvimento / Development tools

Durante `sudo bash gui.sh` você pode instalar:

- **Visual Studio Code:** via repositório Microsoft APT (pulado em ARM 32-bit).
- **OpenCode CLI:** Node.js LTS e `@opencode-ai/cli` global.
- **Git + GitHub CLI (`gh`):** adiciona Git e o repositório oficial `gh`.
- **Essential Dev Stack:** `build-essential`, `python3-pip`, `python3-venv`, `nodejs`, `npm`, `cmake`, `make`, `gcc`, `g++`.
- **.NET SDK 10.0 + C# tooling:** instala o SDK 10.0 (se o pacote Ubuntu não estiver disponível, usa `dotnet-install.sh` como fallback), adiciona as ferramentas globais `dotnet-ef` e `dotnet-aspnet-codegenerator` em `/usr/local/bin`, e instala as extensões C# do VS Code: quando o editor está presente. Verifique com `dotnet --version` e `dotnet tool list --tool-path /usr/local/bin`.
- **AI Coding Assistants:**
  - **Claude Code CLI:** instala o pacote `@anthropic-ai/claude-code` globalmente (`claude`).
  - **Antigravity CLI:** baixa e instala o binário nativo `agy` em `/usr/local/bin`.
  - **Devin CLI:** baixa o instalador do `devin`, remove a etapa `devin setup` para evitar o login durante a instalação, instala o binário e cria symlink em `/usr/local/bin`.
  - **Devin Desktop:** adiciona o repositório APT `windsurf-stable` e instala o pacote `devin-desktop`. Pode falhar em arquiteturas não suportadas pelo repositório.

## Ferramentas de segurança / Security tools

O instalador de ferramentas de segurança (`distro/tools.sh`) agora trabalha em **modo minimal por padrão**:

- **Modo minimal (`--minimal` ou padrão):** instala apenas ferramentas leves nas categorias Essential, Network, Web e Information Gathering.
- **Modo completo (`--full`):** instala o conjunto maior de ferramentas, incluindo `wireshark`, `tshark`, `wpscan`, `theharvester`, `cewl`, `amass`, `subfinder`, `ettercap-common`, `arpwatch`, `ncat`, `ndiff` e `zenmap`.
- As categorias **Vulnerability Analysis**, **Penetration Testing**, **Password Cracking**, **Exploitation**, **Miscellaneous**, **Additional** e **Metasploit Framework** foram removidas do fluxo para reduzir o espaço em disco.

No `gui.sh`, a opção `Kali Linux Tools` executa o `tools.sh --minimal`, evitando downloads grandes por padrão.

## Comandos úteis / Useful commands

| Comando | Descrição / Description |
|---------|------------------------|
| `ubuntu` | Entra no shell do Ubuntu / Enter Ubuntu shell |
| `vncstart` | Inicia o servidor VNC / Start VNC server |
| `vncstop` | Para o servidor VNC / Stop VNC server |
| `vncstart-fhd` | Inicia VNC em 2340x1080 / Start VNC at 2340x1080 |
| `vncstart-qhd` | Inicia VNC em 3088x1440 / Start VNC at 3088x1440 |
| `s26-optimize` | Aplica otimizações para high-DPI / Apply high-DPI optimizations |
| `bash remove.sh` | Remove o Ubuntu modded / Remove the modded Ubuntu OS |

### Iniciar VNC automaticamente / Auto-start VNC Server

Para iniciar o VNC automaticamente ao fazer login: / If you want to automatically start the VNC server when you log in:

```bash
echo "vncstart" >> ~/.bashrc
```

## Tutorial / Video Tutorial

[![Watch the Tutorial](./distro/image1.jpg)](https://mega.nz/embed/QvIC1TLQ#3z27MRNPwANAg6JTtx1Ei8kDouOZsZgk00bg4TsJMNQ!1m)

## Changelog

Clique para ver o [Changelog](./CHANGELOG.md).

## Licença / License

Distribuído sob [Apache License 2.0](./LICENSE).

## Créditos / Credits

Este projeto utiliza a imagem Ubuntu fornecida pelo pacote `proot-distro` do Termux. Todo o crédito pela imagem base do Ubuntu vai para:

- [Termux Proot Distro](https://github.com/termux/proot-distro)

### Mantenedores / Maintainers

- **Modificado e mantido no Brasil por / Modified and maintained in Brazil by:** [Afonso Dutra Nogueira Filho](https://github.com/afonsoft)
- **Autores do projeto original / Original project authors:**
  - [Mustakim Ahmed](https://github.com/BDhackers009)
  - [Tahmid Rayat](https://github.com/htr-tech)
  - [Mahfuz-THBD](https://github.com/Mahfuz-THBD)
  - [MIDØ](https://github.com/Midohajhouj)

### Se gostou do projeto, deixe uma estrela! / If you like our work, don't forget to give a Star :)
