#!/bin/bash

R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
W="$(printf '\033[1;37m')"
C="$(printf '\033[1;36m')"

export DEBIAN_FRONTEND=noninteractive

# Evita que pacotes tentem iniciar serviços dentro do PRoot
if [ ! -f /usr/sbin/policy-rc.d ]; then
    printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d
    chmod 755 /usr/sbin/policy-rc.d
fi

# Logging function
log() {
    local LOG_FILE="${PREFIX:-/data/data/com.termux/files/usr}/tmp/user-script.log"
    local LOG_DIR
    LOG_DIR=$(dirname "$LOG_FILE")
    
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR" || { echo "Failed to create log directory"; exit 1; }
    fi
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE" || { echo "Failed to write to log file"; exit 1; }
}

banner() {
    clear
    printf "\033[33m    _  _ ___  _  _ _  _ ___ _  _    _  _ ____ ___  \033[0m\n"
    printf "\033[36m    |  | |__] |  | |\ |  |  |  |    |\/| |  | |  \ \033[0m\n"
    printf "\033[32m    |__| |__] |__| | \|  |  |__|    |  | |__| |__/ \033[0m\n"
    printf "\033[0m\n"
    printf "     \033[32mA modded GUI version of Ubuntu for Termux\033[0m\n"
    printf "\033[0m\n"
}

install_sudo() {
    log "Installing Sudo..."
    echo -e "\n${R} [${W}-${R}]${C} Installing Sudo...${W}"
    apt update -y || { log "Failed to update apt"; exit 1; }
    apt install sudo -y || { log "Failed to install sudo"; exit 1; }
    apt install wget apt-utils locales-all dialog tzdata zsh git curl ca-certificates unzip fontconfig -y || { log "Failed to install additional packages"; exit 1; }
    log "Sudo installation completed."
    echo -e "\n${R} [${W}-${R}]${G} Sudo Successfully Installed!${W}"
}

configure_locale_timezone() {
    log "Configurando locale padrão (en_US.UTF-8) e timezone (America/Sao_Paulo)..."
    echo -e "\n${R} [${W}-${R}]${C} Configurando locale e fuso horário...${W}"

    # Locale americano (inglês) como padrão do sistema
    if command -v update-locale >/dev/null 2>&1; then
        update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL= 2>/dev/null || true
    else
        echo 'LANG=en_US.UTF-8
LANGUAGE=en_US:en' > /etc/default/locale
    fi

    # Fuso horário de São Paulo (Brasil)
    ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
    echo "America/Sao_Paulo" > /etc/timezone

    if command -v dpkg-reconfigure >/dev/null 2>&1; then
        dpkg-reconfigure -f noninteractive tzdata 2>/dev/null || true
    fi

    # Aplica locale para a sessão atual e garante que .bashrc carregue o padrão
    export LANG=en_US.UTF-8
    export LANGUAGE=en_US:en

    # Ajusta o .bashrc do root para manter o locale americano por padrão
    if ! grep -q "^export LANG=" /root/.bashrc 2>/dev/null; then
        echo 'export LANG=en_US.UTF-8
export LANGUAGE=en_US:en' >> /root/.bashrc
    fi

    log "Locale e timezone configurados: LANG=en_US.UTF-8, TZ=America/Sao_Paulo"
    echo -e "\n${R} [${W}-${R}]${G} Locale e fuso horário configurados.${W}"
}

read_credentials() {
    if [ -n "${MODDED_USER:-}" ]; then
        user="$MODDED_USER"
        if ! [[ "$user" =~ ^[a-z][a-z0-9_-]*$ ]]; then
            echo -e "${R}MODDED_USER deve comecar com letra e conter apenas letras minusculas, numeros, '_' ou '-'.${W}" >&2
            exit 1
        fi
    else
        while true; do
            read -p $' \e[1;31m[\e[0m\e[1;77m~\e[0m\e[1;31m]\e[0m\e[1;92m Input Username [Lowercase] : \e[0m\e[1;96m' user
            if [[ "$user" =~ ^[a-z][a-z0-9_-]*$ ]]; then
                break
            else
                echo -e "${R}Username deve comecar com letra e conter apenas letras minusculas, numeros, '_' ou '-'.${W}"
            fi
        done
    fi
    echo -e "${W}"

    if [ -n "${MODDED_PASS:-}" ]; then
        pass="$MODDED_PASS"
        if [ -z "$pass" ]; then
            echo -e "${R}MODDED_PASS cannot be empty.${W}" >&2
            exit 1
        fi
    else
        while true; do
            read -sp $' \e[1;31m[\e[0m\e[1;77m~\e[0m\e[1;31m]\e[0m\e[1;92m Input Password : \e[0m\e[1;96m' pass
            if [ -n "$pass" ]; then
                break
            else
                echo -e "${R}Password cannot be empty.${W}"
            fi
        done
    fi
    echo -e "${W}"
}

login() {
    banner
    log "Starting user login setup."
    read_credentials

    if id "$user" >/dev/null 2>&1; then
        log "User '$user' already exists; skipping useradd."
    else
        useradd -m -s "$(command -v bash)" "$user" || { log "Failed to add user"; exit 1; }
    fi
    usermod -aG sudo "$user" || { log "Failed to add user to sudo group"; exit 1; }
    echo "${user}:${pass}" | chpasswd || { log "Failed to set password"; exit 1; }

    # Configura zsh + Oh My Zsh + Powerlevel10k para root e para o usuario criado
    local zsh_setup_log="${PREFIX:-/data/data/com.termux/files/usr}/tmp/zsh-setup.log"
    if [[ -e '/usr/local/bin/zsh-setup' ]]; then
        log "Configurando zsh para root (log em $zsh_setup_log)..."
        bash /usr/local/bin/zsh-setup --user root 2>&1 | tee -a "$zsh_setup_log" || true
        log "Configurando zsh para $user (log em $zsh_setup_log)..."
        bash /usr/local/bin/zsh-setup --user "$user" 2>&1 | tee -a "$zsh_setup_log" || true
    elif [[ -e '/data/data/com.termux/files/home/modded-ubuntu/distro/zsh-setup.sh' ]]; then
        log "Configurando zsh para root (log em $zsh_setup_log)..."
        bash /data/data/com.termux/files/home/modded-ubuntu/distro/zsh-setup.sh --user root 2>&1 | tee -a "$zsh_setup_log" || true
        log "Configurando zsh para $user (log em $zsh_setup_log)..."
        bash /data/data/com.termux/files/home/modded-ubuntu/distro/zsh-setup.sh --user "$user" 2>&1 | tee -a "$zsh_setup_log" || true
    fi

    # Evita duplicar a linha no sudoers se o script for executado mais de uma vez.
    if ! grep -q "^${user} ALL=(ALL:ALL) NOPASSWD:ALL" /etc/sudoers; then
        echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers || { log "Failed to update sudoers file"; exit 1; }
    fi

    # Create the ubuntu command for proot-distro
    local termux_prefix
    termux_prefix="${PREFIX:-/data/data/com.termux/files/usr}"
    cat > "$termux_prefix/bin/ubuntu" <<EOF
#!/data/data/com.termux/files/usr/bin/env bash
# Inicia o PulseAudio no Termux antes de acessar o Ubuntu como $user.
bash ~/.sound 2>/dev/null || true
exec proot-distro login --user $user --no-sysvipc ubuntu --bind /dev/null:/proc/sys/kernel/cap_last_last --shared-tmp --fix-low-ports
EOF
    chmod +x "$termux_prefix/bin/ubuntu" || { log "Failed to set permissions for ubuntu command"; exit 1; }

    # Download and set up the GUI script
    if [[ -e '/usr/local/bin/gui.sh' ]]; then
        # Prefere a versão já instalada pelo setup.sh (atualizada pelo update.sh)
        cp -f /usr/local/bin/gui.sh "/home/$user/gui.sh"
        chmod +x "/home/$user/gui.sh" || { log "Failed to set permissions for gui.sh"; exit 1; }
    elif [[ -e '/data/data/com.termux/files/home/modded-ubuntu/distro/gui.sh' ]]; then
        cp -f /data/data/com.termux/files/home/modded-ubuntu/distro/gui.sh "/home/$user/gui.sh"
        chmod +x "/home/$user/gui.sh" || { log "Failed to set permissions for gui.sh"; exit 1; }
    else
        wget -q --show-progress "https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/distro/gui.sh" -O "/home/$user/gui.sh"
        chmod +x "/home/$user/gui.sh" || { log "Failed to set permissions for gui.sh"; exit 1; }
    fi

    # Copia/atualiza os helpers no /usr/local/bin (preferindo a versão local do repo, se existir)
    local repo_dir='/data/data/com.termux/files/home/modded-ubuntu/distro'
    if [[ -d "$repo_dir" ]]; then
        cp -f "$repo_dir/vncstart-fhd" /usr/local/bin/vncstart-fhd 2>/dev/null || true
        cp -f "$repo_dir/vncstart-qhd" /usr/local/bin/vncstart-qhd 2>/dev/null || true
        cp -f "$repo_dir/s26-optimize.sh" /usr/local/bin/s26-optimize 2>/dev/null || true
        cp -f "$repo_dir/csharp.sh" /usr/local/bin/csharp-setup 2>/dev/null || true
        cp -f "$repo_dir/nodejs.sh" /usr/local/bin/node-setup 2>/dev/null || true
        cp -f "$repo_dir/angular.sh" /usr/local/bin/angular-setup 2>/dev/null || true
        cp -f "$repo_dir/update-system.sh" /usr/local/bin/update-system 2>/dev/null || true
    fi
    chmod +x /usr/local/bin/vncstart-fhd /usr/local/bin/vncstart-qhd /usr/local/bin/s26-optimize /usr/local/bin/csharp-setup /usr/local/bin/node-setup /usr/local/bin/angular-setup /usr/local/bin/update-system 2>/dev/null || true

    log "User login setup completed for user: $user"
    cleanup
    echo
    echo -e "\n${R} [${W}-${R}]${G} Restart your Termux & Type ${C}ubuntu${W}"
    echo -e "\n${R} [${W}-${R}]${G} Skip to graphical Interface with ${C}sudo bash gui.sh${W}"
    echo
}

cleanup() {
    log "Limpando caches e pacotes desnecessários do sistema..."
    apt-get autoremove -y --purge 2>/dev/null || true
    apt-get clean 2>/dev/null || true
    if command -v pip >/dev/null 2>&1; then
        pip cache purge 2>/dev/null || true
    fi
    # Remove logs antigos deste script
    find "${PREFIX:-/data/data/com.termux/files/usr}/tmp" -name "user-script.log.*" -mtime +7 -delete 2>/dev/null || true
    clear
}

# Main script execution
banner
install_sudo
configure_locale_timezone
login
