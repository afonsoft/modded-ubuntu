## Changelog

## [Unreleased]

### Added
- `install.sh` one-liner installer: download and run `curl -fsSL https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/install.sh | bash` to clone the repo and execute `setup.sh` automatically. Runs `pkg update` and installs `git`, `curl`, `wget`, `proot-distro` and `pulseaudio` at the start; writes logs to `~/modded-ubuntu-install.log`; and backs up an existing `~/modded-ubuntu` directory instead of prompting.
- Development tools menu in `distro/gui.sh`:
  - Git + GitHub CLI (`gh`)
  - Essential dev stack (`build-essential`, `python3-pip`, `python3-venv`, `nodejs`, `npm`, `cmake`, `make`, `gcc`, `g++`)
  - .NET SDK 8.0 (amd64/arm64)
- Novo script `distro/csharp.sh` para instalação da stack C# / .NET:
  - .NET SDK 10.0 via repositórios Ubuntu ou, como fallback, `dotnet-install.sh`;
  - ferramentas globais `dotnet-ef` e `dotnet-aspnet-codegenerator` em `/usr/local/bin`;
  - extensões C# do VS Code (`ms-dotnettools.csharp`, `ms-dotnettools.csdevkit`, `ms-dotnettools.vscode-dotnet-runtime`) para o usuário não-root;
  - dependências nativas (`libicu-dev`, `libssl3`, `libgdiplus`, etc.) e compatibilidade com Ubuntu 26.04+ sem conflitos de repositórios.
- `distro/gui.sh` exibe `.NET SDK 10.0 + C# tooling` no menu de ferramentas de desenvolvimento e chama `install_csharp_tools()`.
- `setup.sh` e `distro/user.sh` copiam `distro/csharp.sh` para `/usr/local/bin/csharp-setup` durante a instalação.
- Novo script `distro/nodejs.sh` para instalação do Node.js via NVM (versões 20, 22 e 24, com 22 como padrão).
  - Instala o NVM `v0.40.0` para o usuário não-root;
  - Cria symlinks de `node`, `npm`, `npx` e `corepack` em `/usr/local/bin` para uso imediato;
  - Persiste a ativação da versão padrão no `.bashrc` do usuário.
- Novo script `distro/angular.sh` para instalação do Angular 20:
  - Instala o Angular CLI (`@angular/cli@20` com fallback para a versão mais recente);
  - Instala extensões do VS Code: para Angular (`Angular.ng-template`, `johnpapa.Angular2`, ESLint, Prettier, EditorConfig, Path Intellisense, Auto Rename Tag, Material Icon Theme);
  - Garante Node.js/NVM antes de instalar o Angular.
- `distro/gui.sh` ganha as opções de instalação:
  - Node.js 20/22/24 via NVM;
  - Angular 20 + extensões VS Code:;
  - Full-Stack C# + Angular (instala a stack C# e em seguida Node.js/NVM + Angular).
- Novo menu "AI Coding Assistants" em `distro/gui.sh` com as opções:
  - **Claude Code CLI** (`@anthropic-ai/claude-code` via npm global);
  - **Antigravity CLI** (`agy` via script oficial `--dir /usr/local/bin`);
  - **Devin CLI** (`devin` via `cli.devin.ai/install.sh` + symlink em `/usr/local/bin`);
  - **Devin Desktop** (`devin-desktop` via repositório APT `windsurf-stable`).
- `setup.sh` e `distro/user.sh` também copiam `distro/nodejs.sh` e `distro/angular.sh` para `/usr/local/bin/node-setup` e `/usr/local/bin/angular-setup`.
- `distro/vncstop` now uses `${HOME}` instead of a hardcoded `/username/` path.

### Changed
- `install_vscode()` skips 32-bit ARM and uses `dpkg --print-architecture` for the APT repository.
- `install_opencode()` agora usa `install_node_nvm()` (Node.js via NVM) antes de instalar o `@opencode-ai/cli`.
- `install_sublime()` skips 32-bit ARM.
- `sound_fix()` is now idempotent and no longer duplicates `export` entries in `/etc/profile`.
- `install_devin_desktop()` agora segue a ordem exata da documentação oficial: instala `wget/gpg`, adiciona o repositório `windsurf-stable`, instala `apt-transport-https`, atualiza e depois instala `devin-desktop`.
- `downloader()` in `setup.sh` and `gui.sh` no longer uses `--insecure`.
- `remove.sh` safely handles missing `~/.sound` and uses `$HOME`.

### Fixed
- Syntax error (extra closing brace) in `distro/gui.sh` after `install_opencode()`.
- Broken 32-bit ARM exclusion logic in `distro/gui.sh` (`||` replaced by `!= arm*`).
- Missing IDE installation logic in `distro/gui.sh`; IDE selection now triggers `install_sublime`, `install_vscode` or `install_opencode`.
- ShellCheck warnings in `distro/gui.sh`, `distro/tools.sh` and `remove.sh`.
- VNC startup crash (`error: expected absolute path: "--shm-helper"`) by launching `proot-distro` with `--no-sysvipc` and passing `-extension MIT-SHM` to `vncserver`.
- `distro/csharp.sh` não tenta mais instalar `dotnet-sdk-8.0`/`dotnet-sdk-9.0` quando `dotnet-sdk-10.0` não está disponível, usando `dotnet-install.sh` como fallback para garantir a versão 10.0.
- Captura do diretório de binários do NVM em `distro/nodejs.sh` e `distro/angular.sh` agora suprime a saída de `nvm use default`, garantindo a criação correta dos symlinks em `/usr/local/bin`.
- `distro/angular.sh` `ensure_nodejs()` não reinstala o Node.js quando ele já está disponível e o NVM está instalado.
- `distro/gui.sh` `install_opencode()` detecta o binário `opencode`, `opencode2` ou `lildax` no diretório ativo do Node.js (via `readlink` do `node`) e cria o symlink `/usr/local/bin/opencode`.

## [2.0.0] - 2023-01-20

### Added
- Options to choose browser,IDE,media player (to reduce storage consumtion)
- Optimized code
- Better stability 
- Breeze Hacked (cursor theme)
- Kora Icon Theme 
- Custom config (to customize the ui by default)
- Some wallpaper
- Nerd fonts
- many more.

### Changed
- The installer UI (little bit)
- Default wallpaper
- Default font
- Default theme

### Fixed
- Firefox  (added new installer)
- Repository error 
- many many more.

<!-- END -->
