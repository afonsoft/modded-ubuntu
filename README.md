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
- Leve — requer pelo menos 5 GB de armazenamento / Lightweight — requires at least 5 GB of storage
- 2 navegadores (Chromium e Mozilla Firefox) / 2 browsers (Chromium & Mozilla Firefox)
- Suporte a fontes e acentuação em português / Portuguese font and accent support
- VLC Media Player e MPV / VLC Media Player and MPV media player
- Visual Studio Code (com ressalvas em `armhf`/`armv7`) / Visual Studio Code (buggy on armhf/armv7)
- Sublime Text Editor (apenas `arm64`/`aarch64`) / Sublime Text Editor (only for arm64/aarch64)
- OpenCode CLI
- Git + GitHub CLI (`gh`)
- Ferramentas essenciais de desenvolvimento / Essential development tools:
  - `build-essential`, `python3-pip`, `python3-venv`
  - `nodejs`, `npm`, `cmake`, `make`, `gcc`, `g++`
- .NET SDK 10.0 + ferramentas C# / .NET SDK 10.0 + C# tooling
- Node.js 20 / 22 / 24 via NVM (`nvm` para alternar versões) / Node.js 20 / 22 / 24 via NVM (`nvm` to switch versions)
- Angular 20 CLI + extensões do VS Code: / Angular 20 CLI + VS Code: extensions
- Instalação full-stack C# + Angular / Full-Stack C# + Angular install option
- Assistentes de IA para código / AI coding assistants:
  - **Claude Code CLI** (`claude`)
  - **Antigravity CLI** (`agy`)
  - **Devin CLI** (`devin`)
  - **Devin Desktop** IDE (instalação via APT; depende da arquitetura do dispositivo)
- Fácil para iniciantes / Beginner-friendly
- Temas e cursores personalizados / Custom themes and cursors
- Instalador de ferramentas do Kali Linux (inclui Metasploit) / Kali Linux tools installer (Metasploit included)
- Ghost Framework e Wireshark / Ghost Framework and Wireshark

## Requisitos / Requirements

- Android 8.0 ou superior / Android 8.0 or higher
- [Termux](https://termux.com/) instalado pelo F-Droid / [Termux](https://termux.com/) installed from F-Droid
- Pelo menos 5 GB de armazenamento livre / At least 5 GB of free storage
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
- **OpenCode CLI:** Node.js 22.x do NodeSource e `@opencode-ai/cli` global.
- **Git + GitHub CLI (`gh`):** adiciona Git e o repositório oficial `gh`.
- **Essential Dev Stack:** `build-essential`, `python3-pip`, `python3-venv`, `nodejs`, `npm`, `cmake`, `make`, `gcc`, `g++`.
- **.NET SDK 10.0 + C# tooling:** instala o SDK 10.0 (se o pacote Ubuntu não estiver disponível, usa `dotnet-install.sh` como fallback), adiciona as ferramentas globais `dotnet-ef` e `dotnet-aspnet-codegenerator` em `/usr/local/bin`, e instala as extensões C# do VS Code: quando o editor está presente. Verifique com `dotnet --version` e `dotnet tool list --tool-path /usr/local/bin`.
- **AI Coding Assistants:**
  - **Claude Code CLI:** instala o Node.js 22 via NVM e o pacote `@anthropic-ai/claude-code` globalmente (`claude`).
  - **Antigravity CLI:** baixa e instala o binário nativo `agy` em `/usr/local/bin`.
  - **Devin CLI:** instala o binário `devin` (dados em `~/.local/share/devin`) e cria symlink em `/usr/local/bin`.
  - **Devin Desktop:** adiciona o repositório APT `windsurf-stable` e instala o pacote `devin-desktop`. Pode falhar em arquiteturas não suportadas pelo repositório.

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
