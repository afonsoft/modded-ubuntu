## Changelog

## [Unreleased]

### Added
- `install.sh` one-liner installer: `curl -fsSL https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/install.sh | bash` clones the repo and runs `setup.sh`; installs `git`, `curl`, `wget`, `proot-distro` and `pulseaudio`; writes logs to `~/modded-ubuntu-install.log`; backs up an existing `~/modded-ubuntu` directory instead of prompting.
- `update.sh` (Termux) e `distro/update-system.sh` (dentro do Ubuntu) para atualizar instalações existentes: atualizam pacotes via `apt`, reforçam locale `en_US.UTF-8` e timezone `America/Sao_Paulo` e limpam caches/temporários sem reinstalar o rootfs.
- Modo `--update` em `distro/gui.sh`: reinstala/atualiza pacotes base, instala novidades (ex.: Obsidian) e reaplica configurações XFCE sem interação; `update-system.sh` o re-executa automaticamente.
- `setup.sh` cria o usuário automaticamente quando `MODDED_USER`/`MODDED_PASS` estão definidos (instalação não interativa de ponta a ponta); sem as variáveis, mantém o fluxo manual (`ubuntu` + `bash user.sh`).
- `MODDED_GIT_REF` (padrão `master`) em todos os scripts que baixam arquivos do repositório em runtime (`setup.sh`, `user.sh`, `gui.sh`, `update-system.sh`, `chromium.sh`, `angular.sh`, `csharp.sh`), permitindo pinar branch, tag ou SHA.
- Development tools menu in `distro/gui.sh`:
  - Git + GitHub CLI (`gh`)
  - Essential dev stack (`build-essential`, `python3-pip`, `python3-venv`, `nodejs`, `npm`, `cmake`, `make`, `gcc`, `g++`)
  - .NET SDK 10.0 (amd64/arm64)
- Novo script `distro/csharp.sh` para instalação da stack C# / .NET:
  - .NET SDK 10.0 via repositórios Ubuntu ou, como fallback, `dotnet-install.sh`;
  - ferramentas globais `dotnet-ef` e `dotnet-aspnet-codegenerator` em `/usr/local/bin`;
  - extensões C# do VS Code para o usuário não-root;
  - `distro/gui.sh` exibe `.NET SDK 10.0 + C# tooling` e chama `install_csharp_tools()`;
  - `setup.sh`/`user.sh` copiam `csharp.sh` para `/usr/local/bin/csharp-setup`.
- Novo script `distro/nodejs.sh`: Node.js LTS via repositório NodeSource `.deb` (`node_22.x nodistro main`), removendo instalações NVM anteriores (ver ADR-010).
- Novo script `distro/angular.sh`: Angular CLI mais recente + extensões do VS Code para Angular; `gui.sh` ganha as opções Node.js LTS, Angular e Full-Stack C# + Angular; `setup.sh`/`user.sh` copiam `node-setup` e `angular-setup` para `/usr/local/bin`.
- Novo menu "AI Coding Assistants" em `distro/gui.sh`: Claude Code CLI (`@anthropic-ai/claude-code`), Antigravity CLI (`agy`), Devin CLI (`cli.devin.ai/install.sh`) e Devin Desktop (repositório `windsurf-stable`).
- Limpeza automática de caches/temporários no final das instalações em `nodejs.sh`, `angular.sh`, `csharp.sh`, `tools.sh`, `gui.sh`, `install.sh` e `setup.sh` (inclui `pkg clean`, cache do `proot-distro`, `npm cache clean`, `pip cache purge`, `apt-get clean`).

### Changed
- `README.md` reescrito: origem modificada no Brasil, seções bilíngues (pt-BR/en-US) e instruções de instalação, requisitos e créditos revisadas.
- `install.sh` verifica espaço livre (>= 5 GB) e mantém a tela ligada durante o setup com `termux-wake-lock`/`termux-wake-unlock`.
- `setup.sh` mantém a tela ligada, define locale `en_US.UTF-8` e timezone `America/Sao_Paulo` no rootfs e usa `$PREFIX` ao criar o comando `ubuntu`; não sobrescreve `ubuntu` em `$PREFIX/bin` se o wrapper de `user.sh` já existir.
- `distro/user.sh` aceita criação não interativa de usuário via `MODDED_USER`/`MODDED_PASS`, evita duplicar a entrada no `/etc/sudoers`, configura locale/timezone como padrão do sistema e passa a logar o zsh-setup em `/tmp/zsh-setup.log` dentro do rootfs.
- `distro/user.sh`, `distro/csharp.sh` e `distro/update-system.sh` exportam `DEBIAN_FRONTEND=noninteractive` e criam `/usr/sbin/policy-rc.d` retornando `101` para impedir que `postinst` inicie serviços no PRoot.
- `distro/nodejs.sh`, `distro/angular.sh`, `distro/csharp.sh` e `distro/user.sh` executam `apt-get autoremove -y --purge` antes de `apt-get clean`.
- `distro/tools.sh` reestruturado para **modo minimal por padrão** (`MINIMAL=true`, flags `-y`/`--yes`, `-m`/`--minimal`, `-f`/`--full`); `gui.sh` chama `tools.sh --minimal` para "Kali Linux Tools".
- `distro/gui.sh` ajustado para ambiente `noninteractive`: preseed de `wireshark-common`, `install_devin_cli()` instala o binário sem exigir login; `install_vscode()`/`install_sublime()`/`install_opencode()` usam `dpkg --print-architecture` e pulam ARM 32-bit.
- `install_devin_desktop()` segue a ordem da documentação oficial: `wget/gpg`, repositório `windsurf-stable`, `apt-transport-https`, update e install.
- `downloader()` em `setup.sh` e `gui.sh` não usa mais `--insecure`.
- `sound_fix()` é idempotente e não duplica `export` em `/etc/profile`.
- `remove.sh` trata `~/.sound` ausente e usa `$HOME`.
- Wrapper `firefox` em `/usr/local/bin` exporta `MOZ_DISABLE_CONTENT_SANDBOX`/`MOZ_DISABLE_GMP_SANDBOX`/`MOZ_FAKE_NO_SANDBOX` (o sandbox exige namespaces que o PRoot não emula).
- `distro/setup_xtradeb.sh` usa helper `apt_retry` (até 5 tentativas) nos comandos `apt-get`, tolerando locks transitórios e rede instável no Termux.
- CI (`termux-test.yml`) executa `pkg` com retry, roda `setup.sh` não-interativo com `MODDED_USER`/`MODDED_PASS` e verifica o usuário criado dentro do proot; `bash-syntax.yml` falha (em vez de apenas avisar) quando um script de entrypoint não é executável.

### Fixed
- Syntax error (extra closing brace) in `distro/gui.sh` after `install_opencode()`.
- Broken 32-bit ARM exclusion logic in `distro/gui.sh`.
- Missing IDE installation logic in `distro/gui.sh`; IDE selection now triggers `install_sublime`, `install_vscode` or `install_opencode`.
- ShellCheck warnings in `distro/gui.sh`, `distro/tools.sh` and `remove.sh`.
- VNC startup crash (`error: expected absolute path: "--shm-helper"`) via `proot-distro --no-sysvipc` + `-extension MIT-SHM` no `vncserver`.
- `distro/csharp.sh` usa `dotnet-install.sh` como fallback quando `dotnet-sdk-10.0` não está nos repositórios.
- Detecção de arquitetura consistente (`dpkg --print-architecture` com fallback `uname -m`) em `gui.sh` e `nodejs.sh`, sem confundir `arm64` com ARM 32-bit.
- `install_opencode()` detecta `opencode`, `opencode2` ou `lildax` no diretório ativo do Node.js e cria o symlink `/usr/local/bin/opencode`.
- `distro/vncstop` usa `${HOME}` em vez de caminho hardcoded.
- `distro/angular.sh` `ensure_nodejs()` não reinstala o Node.js quando já disponível.

### Removed
- `distro/systemd/modded-ubuntu-vnc.service` e a função `update_systemd_vnc_service`: o PRoot não executa systemd, então a unit nunca era ativada (código morto).
- Do `distro/tools.sh` (modo minimal): `Vulnerability Analysis Tools`, `Penetration Testing Tools`, `Password Cracking Tools`, `Exploitation Tools`, `Miscellaneous Tools`, `Additional Tools` e `Metasploit Framework`.
- Instalação do Node.js via NVM e via tarball manual: substituída pelo repositório NodeSource `.deb` (ADR-010).

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
