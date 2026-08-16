## Changelog

## [Unreleased]

### Added
- `install.sh` one-liner installer: download and run `curl -fsSL https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/install.sh | bash` to clone the repo and execute `setup.sh` automatically. Runs `pkg update` and installs `git`, `curl`, `wget`, `proot-distro` and `pulseaudio` at the start; writes logs to `~/modded-ubuntu-install.log`; and backs up an existing `~/modded-ubuntu` directory instead of prompting.
- `update.sh` (Termux) e `distro/update-system.sh` (dentro do Ubuntu) para atualizar instalações existentes: atualizam pacotes via `apt`, reforçam locale `en_US.UTF-8` e timezone `America/Sao_Paulo` e limpam caches/temporários sem reinstalar o rootfs.
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
- `README.md` atualizado para destacar a origem modificada no Brasil, reorganizar a documentação em seções bilíngues (pt-BR/en-US) e melhorar as instruções de instalação, requisitos e créditos.
- `install.sh` verifica espaço livre (>= 5 GB), mantém a tela ligada durante o setup com `termux-wake-lock`/`termux-wake-unlock` e usa `pkg upgrade -y`.
- `setup.sh` também mantém a tela ligada, adiciona fallback para timezone e usa `$PREFIX` ao criar o comando `ubuntu`.
- `setup.sh` define o locale padrão como `en_US.UTF-8` e fallback de timezone para `America/Sao_Paulo` no rootfs, quando ainda não configurados.
- `distro/user.sh` permite criação não interativa de usuário via variáveis `MODDED_USER`/`MODDED_PASS` e evita duplicar a entrada no `/etc/sudoers`.
- `distro/user.sh` configura locale `en_US.UTF-8` e timezone `America/Sao_Paulo` como padrões do sistema, incluindo `/etc/default/locale`, `/etc/localtime`, `/etc/timezone` e `.bashrc`.
- `distro/user.sh` limpa dependências órfãs com `apt-get autoremove -y --purge` antes de `apt-get clean` e chama `clear` no final do cleanup.
- `distro/nodejs.sh`, `distro/angular.sh` e `distro/csharp.sh` também executam `apt-get autoremove -y --purge` antes de `apt-get clean` no final da instalação.
- `setup.sh` não sobrescreve o comando `ubuntu` em `$PREFIX/bin/ubuntu` se ele já existir (preserva o wrapper criado por `user.sh` durante atualizações).
- `install_vscode()` skips 32-bit ARM and uses `dpkg --print-architecture` for the APT repository.
- `install_opencode()` agora usa `install_node_nvm()` (Node.js via NVM) antes de instalar o `@opencode-ai/cli`.
- `install_sublime()` skips 32-bit ARM.
- `sound_fix()` is now idempotent and no longer duplicates `export` entries in `/etc/profile`.
- `install_devin_desktop()` agora segue a ordem exata da documentação oficial: instala `wget/gpg`, adiciona o repositório `windsurf-stable`, instala `apt-transport-https`, atualiza e depois instala `devin-desktop`.
- `downloader()` in `setup.sh` and `gui.sh` no longer uses `--insecure`.
- `remove.sh` safely handles missing `~/.sound` and uses `$HOME`.
- `distro/tools.sh` foi reestruturado para **modo minimal por padrão** (`MINIMAL=true`):
  - adiciona as flags `-y`/`--yes`, `-m`/`--minimal` e `-f`/`--full`;
  - no minimal instala apenas `ESSENTIAL`, `NETWORK`, `WEB` e `INFO` Gathering (ferramentas leves);
  - no full mantém o conjunto maior de ferramentas;
  - `apt-get` usa `--no-install-recommends` no modo minimal para reduzir espaço.
- `distro/gui.sh` chama `tools.sh` com `--minimal` ao instalar `Kali Linux Tools`, evitando downloads grandes por padrão.
- `distro/nodejs.sh` reescrito para instalar o Node.js LTS via repositório **NodeSource `.deb`** (`node_22.x nodistro main`):
  - remove a duplicidade do source `universe`;
  - remove o pacote `npm` quebrado do Ubuntu, usando o `npm` empacotado junto com o `nodejs` do NodeSource;
  - `distro/user.sh`, `distro/csharp.sh` e `distro/update-system.sh` exportam `DEBIAN_FRONTEND=noninteractive` e criam `/usr/sbin/policy-rc.d` retornando `101` para impedir que `postinst` inicie serviços no PRoot.
- `distro/gui.sh` ajustado para ambiente `noninteractive`:
  - preseed de `wireshark-common` para evitar prompt do debconf;
  - `install_kali_tools()` passa `-y --minimal` para o `tools.sh`;
  - `install_devin_cli()` baixa o script do Devin CLI, remove a última linha (`devin setup`) e instala o binário sem exigir login.

### Removed
- Removidas as seguintes categorias do `distro/tools.sh` para reduzir o tamanho da instalação:
  - `Vulnerability Analysis Tools`;
  - `Penetration Testing Tools`;
  - `Password Cracking Tools`;
  - `Exploitation Tools`;
  - `Miscellaneous Tools`;
  - `Additional Tools`.

### Added
- Limpeza automática de arquivos temporários e caches no final das instalações:
  - `distro/nodejs.sh`: remove `/tmp/nvm-install.sh` e o cache de downloads do NVM, além de executar `apt-get clean`, `npm cache clean --force` e `pip cache purge`;
  - `distro/angular.sh`: remove scripts temporários e executa `apt-get clean`, `npm cache clean --force` e `pip cache purge`;
  - `distro/csharp.sh`: remove `/tmp/dotnet-install.sh` e scripts temporários, executa `apt-get clean`, `dotnet nuget locals all --clear` e `pip cache purge`;
  - `distro/tools.sh`: executa `apt-get clean`/`pacman -Sc`/`yum|dnf clean all`, `npm cache clean --force`, `pip cache purge` e remove arquivos temporários;
  - `distro/gui.sh`: limpa APT, npm, pip, logs antigos e arquivos temporários conhecidos ao final do setup;
  - `install.sh` e `setup.sh`: limpam caches do Termux (`pkg clean`) e, no `setup.sh`, também removem o cache de downloads do `proot-distro`.

### Fixed
- Syntax error (extra closing brace) in `distro/gui.sh` after `install_opencode()`.
- Broken 32-bit ARM exclusion logic in `distro/gui.sh` (`||` replaced by `!= arm*`).
- Missing IDE installation logic in `distro/gui.sh`; IDE selection now triggers `install_sublime`, `install_vscode` or `install_opencode`.
- ShellCheck warnings in `distro/gui.sh`, `distro/tools.sh` and `remove.sh`.
- VNC startup crash (`error: expected absolute path: "--shm-helper"`) by launching `proot-distro` with `--no-sysvipc` and passing `-extension MIT-SHM` to `vncserver`.
- `distro/csharp.sh` não tenta mais instalar `dotnet-sdk-8.0`/`dotnet-sdk-9.0` quando `dotnet-sdk-10.0` não está disponível, usando `dotnet-install.sh` como fallback para garantir a versão 10.0.
- Corrigido travamento na instalação do Node.js/NVM em `distro/nodejs.sh`:
  - substitui o instalador oficial do NVM por clone direto do repositório (`git clone --depth=1 --branch v0.40.0`), evitando `nvm_check_global_modules`/`npm list -g` que travavam dentro do PRoot;
  - adiciona `coreutils` como dependência para garantir o comando `timeout`;
  - usa `nvm install -b <versão>` para forçar o download de binário e evitar compilação from-source;
  - aumenta o timeout de cada instalação para 900s com `timeout --kill-after=60 900`;
  - exibe o progresso do `curl` durante o download ao não setar `NVM_NO_PROGRESS=1`;
  - loga a arquitetura, o comando exato e o status de cada instalação do Node.js;
  - pula Node.js 24 em arquiteturas `armv7l`/`armhf` onde binários oficiais geralmente não existem;
  - adiciona logs detalhados em cada etapa (instalação do NVM, instalação de cada versão do Node, criação de symlinks).
- Captura do diretório de binários do NVM em `distro/nodejs.sh` e `distro/angular.sh` agora suprime a saída de `nvm use default`, garantindo a criação correta dos symlinks em `/usr/local/bin`.
- `distro/angular.sh` `ensure_nodejs()` não reinstala o Node.js quando ele já está disponível e o NVM está instalado.
- `distro/gui.sh` `install_opencode()` detecta o binário `opencode`, `opencode2` ou `lildax` no diretório ativo do Node.js (via `readlink` do `node`) e cria o symlink `/usr/local/bin/opencode`.
- Corrigida detecção de arquitetura em `distro/gui.sh` e `distro/nodejs.sh`:
  - usa `dpkg --print-architecture` (com fallback para `uname -m`) para detectar a arquitetura de forma consistente dentro do PRoot;
  - normaliza `aarch64`/`arm64` para `arm64` e `armhf`/`armv7l`/`armv6l` para `arm` (32-bit);
  - evita que `arm64` seja confundido com `arm*` (32-bit) e fique sem VSCode/Sublime/Node 24.
- Substituída a instalação do Node.js via `nvm install -b` por download direto dos tarballs oficiais em `distro/nodejs.sh`:
  - resolve a versão completa a partir do `index.tab` do nodejs.org (com fallback para versões conhecidas);
  - usa `curl` com `--connect-timeout`, `--max-time`, `--retry` e `--progress-bar` para evitar travamentos silenciosos;
  - verifica o checksum `SHASUMS256.txt` antes de extrair o tarball;
  - extrai o tarball em `$NVM_DIR/versions/node/<versão>` mantendo a estrutura esperada pelo NVM;
  - adiciona `xz-utils` como dependência e usa `tar -xJf` para descompactar `.tar.xz`;
  - define Node 22 como padrão via `nvm alias default <versão completa>`.
- Node.js agora é instalado diretamente (sem NVM) em `distro/nodejs.sh`:
  - remove qualquer instalação anterior do NVM (`~/.nvm`) e suas referências no `.bashrc`;
  - instala o Node.js LTS mais recente a partir do tarball oficial em `/usr/local/lib/nodejs`;
  - cria symlinks em `/usr/local/bin` para `node`, `npm`, `npx` e `corepack`;
  - adiciona `/usr/local/lib/nodejs/bin` ao PATH via `/etc/profile.d/nodejs.sh` e `.bashrc`;
  - `distro/angular.sh` e `distro/gui.sh` foram ajustados para usar `npm` global sem depender do NVM.
- `setup.sh` agora instala `distro/gui.sh` em `/usr/local/bin/gui.sh` dentro do rootfs.
- `distro/user.sh` copia `gui.sh` e os scripts helpers preferindo a versão atualizada em `/usr/local/bin/`, caindo para o repo local ou download remoto.
- `distro/update-system.sh` sincroniza `/usr/local/bin/gui.sh` para o diretório home de todos os usuários regulares durante a atualização.
- `update.sh` continua fazendo `git pull`, executando `setup.sh` (que atualiza `/usr/local/bin/gui.sh`) e rodando `update-system` dentro do proot.
- `distro/nodejs.sh` reescrito para instalar o Node.js LTS via `apt` (pacotes `nodejs` e `npm` do repositório Ubuntu), evitando downloads diretos do nodejs.org que travavam dentro do PRoot:
  - habilita o repositório `universe` automaticamente, se necessário;
  - remove instalações anteriores do NVM e do tarball manual em `/usr/local/lib/nodejs`;
  - limpa symlinks legados em `/usr/local/bin` e o arquivo `/etc/profile.d/nodejs.sh`;
  - instala `nodejs` e `npm` a partir dos repositórios Ubuntu (v22.x LTS no Ubuntu 26.04);
  - `distro/gui.sh` atualiza a mensagem para "Node.js LTS (apt)".

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
