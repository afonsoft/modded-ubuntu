#!/usr/bin/env bash
set -u

# Configura zsh + Oh My Zsh + Powerlevel10k otimizado para telas pequenas.
# Uso:
#   zsh-setup.sh                 # usuario atual (Termux ou Ubuntu)
#   zsh-setup.sh --termux        # forca modo Termux
#   zsh-setup.sh --user USUARIO  # configura um usuario no Ubuntu (proot)
#   zsh-setup.sh --all           # root + todos os usuarios regulares do Ubuntu

OMZ_INSTALL_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
P10K_REPO="https://github.com/romkatv/powerlevel10k.git"
FONT_URL="https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"

log() {
    echo "[zsh-setup] $*" >&2
}

is_termux() {
    [ -n "${TERMUX_VERSION:-}" ] || [ -d "/data/data/com.termux/files/usr" ]
}

run_as_target() {
    local user="$1"
    shift
    if [ "$(id -un)" = "$user" ]; then
        "$@"
    elif command -v su >/dev/null 2>&1; then
        su -s /bin/bash -c "$*" "$user"
    else
        log "su nao disponivel; executando como root para $user"
        HOME="$(getent passwd "$user" 2>/dev/null | cut -d: -f6)" "$@"
    fi
}

install_packages() {
    local marker
    marker="${TMPDIR:-/tmp}/.modded_zsh_packages_installed"
    if [ -f "$marker" ]; then
        return 0
    fi

    log "Instalando dependencias para o zsh..."

    if is_termux; then
        if command -v pkg >/dev/null 2>&1; then
            # Termux: pacotes essenciais para oh-my-zsh e powerlevel10k
            pkg install -y zsh git curl unzip ttf-nerd-fonts-symbols 2>/dev/null || true
        fi
        touch "$marker"
        return 0
    fi

    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -yq >/dev/null 2>&1 || true
        apt-get install -y --no-install-recommends zsh git curl ca-certificates unzip fontconfig 2>/dev/null || true
    fi

    touch "$marker"
}

ensure_zsh_in_shells() {
    # No Ubuntu proot, garante que o zsh seja um shell valido para usermod/chsh.
    is_termux && return 0
    [ "$(id -u)" -eq 0 ] || return 0

    local zsh_path
    zsh_path="$(command -v zsh 2>/dev/null || true)"
    [ -n "$zsh_path" ] || return 0

    if [ -f /etc/shells ] && ! grep -qxF "$zsh_path" /etc/shells 2>/dev/null; then
        echo "$zsh_path" >> /etc/shells
    fi
}

change_shell_to_zsh() {
    local user="$1"
    is_termux && return 0
    [ "$(id -u)" -eq 0 ] || return 0

    local zsh_path
    zsh_path="$(command -v zsh 2>/dev/null || true)"
    [ -n "$zsh_path" ] || return 0

    local current_shell
    current_shell="$(getent passwd "$user" 2>/dev/null | cut -d: -f7)"
    if [ "$current_shell" != "$zsh_path" ]; then
        usermod -s "$zsh_path" "$user" 2>/dev/null || true
    fi
}

install_oh_my_zsh() {
    local home="$1"
    local user="$2"
    local omz_dir="$home/.oh-my-zsh"

    if [ -f "$omz_dir/oh-my-zsh.sh" ]; then
        log "Oh My Zsh ja instalado para $user"
        return 0
    fi

    log "Instalando Oh My Zsh para $user..."
    (
        export RUNZSH=no
        export CHSH=no
        export HOME="$home"
        export ZSH="$omz_dir"
        if command -v curl >/dev/null 2>&1; then
            sh -c "$(curl -fsSL --retry 3 --retry-delay 2 "$OMZ_INSTALL_URL")" "" --unattended 2>/dev/null || true
        fi
    )

    if [ -d "$omz_dir" ]; then
        chown -R "$user:" "$omz_dir" 2>/dev/null || true
    fi
}

install_powerlevel10k() {
    local home="$1"
    local user="$2"
    local p10k_dir="$home/.oh-my-zsh/custom/themes/powerlevel10k"

    if [ -d "$p10k_dir/.git" ]; then
        log "Atualizando Powerlevel10k para $user..."
        git -C "$p10k_dir" pull --ff-only 2>/dev/null || true
        return 0
    fi

    log "Instalando Powerlevel10k para $user..."
    mkdir -p "$home/.oh-my-zsh/custom/themes"
    git clone --depth=1 -- "$P10K_REPO" "$p10k_dir" 2>/dev/null || true

    if [ -d "$p10k_dir" ]; then
        chown -R "$user:" "$p10k_dir" 2>/dev/null || true
    fi
}

write_zshrc() {
    local home="$1"
    local user="$2"
    local zshrc="$home/.zshrc"

    log "Escrevendo .zshrc para $user..."
    cat > "$zshrc" <<'EOF'
# Modded Ubuntu - zsh + Oh My Zsh + Powerlevel10k
# Otimizado para tela pequena (Termux / Ubuntu proot)

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"
DISABLE_UPDATE_PROMPT=true
DISABLE_AUTO_UPDATE=true
DISABLE_MAGIC_FUNCTIONS=true
DISABLE_AUTO_TITLE=true
COMPLETION_WAITING_DOTS="true"
CASE_SENSITIVE="false"
HYPHEN_INSENSITIVE="true"
HIST_STAMPS="yyyy-mm-dd"

plugins=(git)

# Locale: mantem o existente ou usa C.UTF-8 como fallback seguro
export LANG="${LANG:-C.UTF-8}"
export LC_ALL="${LC_ALL:-$LANG}"
export LANGUAGE="${LANGUAGE:-en_US:en}"
export TERM=xterm-256color

# Evita erros se o Oh My Zsh ainda nao estiver totalmente instalado
[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# Carrega a configuracao do Powerlevel10k
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
EOF

    chown "$user:" "$zshrc" 2>/dev/null || true
    chmod 644 "$zshrc" 2>/dev/null || true
}

write_p10k() {
    local home="$1"
    local user="$2"
    local p10k="$home/.p10k.zsh"

    log "Escrevendo .p10k.zsh para $user..."
    cat > "$p10k" <<'EOF'
# Modded Ubuntu - Powerlevel10k otimizado para tela pequena
# Dois prompts: dir + git na primeira linha, caractere na segunda;
# hora curta do lado direito; sem linha em branco; transient prompt.

[[ ! -o aliases ]] || setopt no_aliases
[[ ! -o sh_glob ]] || setopt no_sh_glob
unset -m "(POWERLEVEL9K_*)~POWERLEVEL9K_GITSTATUS_DIR"

# Modo Nerd Font v3 (instalamos MesloLGS NF)
typeset -g POWERLEVEL9K_MODE=nerdfont-v3

# Layout em duas linhas
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs newline prompt_char)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(time)

# Ocupa menos espaco
typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=false
typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=40
typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=always

# Desliga instant prompt para evitar warnings em PRoot/Termux sem TTY completo
typeset -g POWERLEVEL9K_INSTANT_PROMPT=off

# Horario curto no canto direito
typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M}'
typeset -g POWERLEVEL9K_TIME_UPDATE_ON_COMMAND=true

# Diretorio truncado para caber melhor em telas pequenas
typeset -g POWERLEVEL9K_DIR_HYPERLINK=false
typeset -g POWERLEVEL9K_DIR_SHOW_WRITABLE=true

# Remove os separadores powerline para economizar espaco horizontal
typeset -g POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR=''
typeset -g POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR=''
typeset -g POWERLEVEL9K_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''
typeset -g POWERLEVEL9K_RIGHT_PROMPT_FIRST_SEGMENT_START_SYMBOL=''

# Restringe o VCS apenas ao git e limita icones extras
typeset -g POWERLEVEL9K_VCS_BACKENDS=(git)
EOF

    chown "$user:" "$p10k" 2>/dev/null || true
    chmod 644 "$p10k" 2>/dev/null || true
}

install_font() {
    local home="$1"
    local user="$2"

    if is_termux; then
        local termux_dir="$home/.termux"
        mkdir -p "$termux_dir"

        if [ -f "$termux_dir/font.ttf" ] && [ ! -f "$termux_dir/font.ttf.bak" ]; then
            mv "$termux_dir/font.ttf" "$termux_dir/font.ttf.bak.$(date +%s)"
        fi

        if command -v curl >/dev/null 2>&1; then
            if curl -fL --retry 3 --retry-delay 2 -o "$termux_dir/font.ttf" "$FONT_URL" 2>/dev/null; then
                log "Fonte MesloLGS NF instalada em $termux_dir/font.ttf"
            else
                log "Aviso: nao foi possivel baixar a fonte MesloLGS NF para Termux"
            fi
        fi

        if command -v termux-reload-settings >/dev/null 2>&1; then
            termux-reload-settings 2>/dev/null || true
        fi
        return 0
    fi

    # Ubuntu: instala a fonte em escopo global para todos os usuarios
    local font_dir="/usr/local/share/fonts/modded-ubuntu"
    mkdir -p "$font_dir"

    if [ -f "$font_dir/MesloLGS-NF-Regular.ttf" ]; then
        log "Fonte MesloLGS NF ja instalada no sistema"
        return 0
    fi

    if command -v curl >/dev/null 2>&1; then
        if curl -fL --retry 3 --retry-delay 2 -o "$font_dir/MesloLGS-NF-Regular.ttf" "$FONT_URL" 2>/dev/null; then
            log "Fonte MesloLGS NF instalada em $font_dir"
        else
            log "Aviso: nao foi possivel baixar a fonte MesloLGS NF"
            return 0
        fi
    fi

    if command -v fc-cache >/dev/null 2>&1; then
        fc-cache -f "$font_dir" 2>/dev/null || fc-cache -f 2>/dev/null || true
    fi
}

configure_termux_bashrc() {
    local home="$1"
    local bashrc="$home/.bashrc"
    [ -f "$bashrc" ] || touch "$bashrc"

    if ! grep -q "Inicia zsh automaticamente" "$bashrc" 2>/dev/null; then
        log "Configurando .bashrc para iniciar zsh no Termux..."
        cat >> "$bashrc" <<'EOF'

# Inicia zsh automaticamente (modded-ubuntu)
if [ -x "${PREFIX:-/data/data/com.termux/files/usr}/bin/zsh" ] && [ -z "${ZSH_VERSION:-}" ]; then
    SHELL="${PREFIX:-/data/data/com.termux/files/usr}/bin/zsh" exec zsh
fi
EOF
    fi
}

setup_user() {
    local user="$1"
    local home="$2"

    [ -d "$home" ] || mkdir -p "$home"

    install_oh_my_zsh "$home" "$user"
    install_powerlevel10k "$home" "$user"
    write_zshrc "$home" "$user"
    write_p10k "$home" "$user"

    # Fonte no Termux e em Ubuntu (global); idempotente
    install_font "$home" "$user"
}

setup_current_user() {
    local user
    user="$(id -un 2>/dev/null || echo "${USER:-user}")"
    local home
    home="$HOME"

    install_packages
    setup_user "$user" "$home"

    if is_termux; then
        configure_termux_bashrc "$home"
    fi
}

setup_proot_user() {
    local user="$1"
    local home
    home="$(getent passwd "$user" 2>/dev/null | cut -d: -f6)"
    [ -n "$home" ] || home="/home/$user"
    [ "$user" = "root" ] && home="/root"

    if [ ! -d "$home" ]; then
        log "Home directory nao encontrado para $user; pulando."
        return 0
    fi

    install_packages
    ensure_zsh_in_shells
    change_shell_to_zsh "$user"
    setup_user "$user" "$home"
}

setup_all_proot() {
    is_termux && return 0
    [ "$(id -u)" -eq 0 ] || {
        log "--all requer execucao como root dentro do proot."
        return 0
    }

    # root
    setup_proot_user "root"

    # usuarios regulares
    awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd 2>/dev/null | while IFS= read -r user; do
        [ -n "$user" ] && setup_proot_user "$user"
    done
}

usage() {
    echo "Uso: $0 [--termux | --user USUARIO | --all]" >&2
}

main() {
    case "${1:-}" in
        --termux)
            setup_current_user
            ;;
        --user)
            [ -n "${2:-}" ] || { usage; exit 1; }
            setup_proot_user "$2"
            ;;
        --all)
            setup_all_proot
            ;;
        "")
            if is_termux; then
                setup_current_user
            else
                setup_current_user
            fi
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
}

main "$@"
