#!/bin/bash

R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
W="$(printf '\033[1;37m')"
C="$(printf '\033[1;36m')"

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
    apt install wget apt-utils locales-all dialog tzdata -y || { log "Failed to install additional packages"; exit 1; }
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
        if ! [[ "$user" =~ ^[a-z]+$ ]]; then
            echo -e "${R}MODDED_USER must be lowercase and contain no special characters.${W}" >&2
            exit 1
        fi
    else
        while true; do
            read -p $' \e[1;31m[\e[0m\e[1;77m~\e[0m\e[1;31m]\e[0m\e[1;92m Input Username [Lowercase] : \e[0m\e[1;96m' user
            if [[ "$user" =~ ^[a-z]+$ ]]; then
                break
            else
                echo -e "${R}Username must be lowercase and contain no special characters.${W}"
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

    # Evita duplicar a linha no sudoers se o script for executado mais de uma vez.
    if ! grep -q "^${user} ALL=(ALL:ALL) NOPASSWD:ALL" /etc/sudoers; then
        echo "$user ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers || { log "Failed to update sudoers file"; exit 1; }
    fi

    # Create the ubuntu command for proot-distro
    local termux_prefix
    termux_prefix="${PREFIX:-/data/data/com.termux/files/usr}"
    echo "proot-distro login --user $user --no-sysvipc ubuntu --bind /dev/null:/proc/sys/kernel/cap_last_last --shared-tmp --fix-low-ports" > "$termux_prefix/bin/ubuntu"
    chmod +x "$termux_prefix/bin/ubuntu" || { log "Failed to set permissions for ubuntu command"; exit 1; }

    # Download and set up the GUI script
    if [[ -e '/data/data/com.termux/files/home/modded-ubuntu/distro/gui.sh' ]]; then
        cp /data/data/com.termux/files/home/modded-ubuntu/distro/gui.sh "/home/$user/gui.sh"
        chmod +x "/home/$user/gui.sh" || { log "Failed to set permissions for gui.sh"; exit 1; }
        cp /data/data/com.termux/files/home/modded-ubuntu/distro/vncstart-fhd /usr/local/bin/vncstart-fhd 2>/dev/null || true
        cp /data/data/com.termux/files/home/modded-ubuntu/distro/vncstart-qhd /usr/local/bin/vncstart-qhd 2>/dev/null || true
        cp /data/data/com.termux/files/home/modded-ubuntu/distro/s26-optimize.sh /usr/local/bin/s26-optimize 2>/dev/null || true
        cp /data/data/com.termux/files/home/modded-ubuntu/distro/csharp.sh /usr/local/bin/csharp-setup 2>/dev/null || true
        cp /data/data/com.termux/files/home/modded-ubuntu/distro/nodejs.sh /usr/local/bin/node-setup 2>/dev/null || true
        cp /data/data/com.termux/files/home/modded-ubuntu/distro/angular.sh /usr/local/bin/angular-setup 2>/dev/null || true
    else
        wget -q --show-progress "https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/distro/gui.sh" -O "/home/$user/gui.sh"
        chmod +x "/home/$user/gui.sh" || { log "Failed to set permissions for gui.sh"; exit 1; }
    fi
    chmod +x /usr/local/bin/vncstart-fhd /usr/local/bin/vncstart-qhd /usr/local/bin/s26-optimize /usr/local/bin/csharp-setup /usr/local/bin/node-setup /usr/local/bin/angular-setup 2>/dev/null || true

    log "User login setup completed for user: $user"
    cleanup
    clear
    echo
    echo -e "\n${R} [${W}-${R}]${G} Restart your Termux & Type ${C}ubuntu${W}"
    echo -e "\n${R} [${W}-${R}]${G} Skip to graphical Interface with ${C}sudo bash gui.sh${W}"
    echo
}

cleanup() {
    log "Limpando caches do sistema..."
    apt-get clean 2>/dev/null || true
    if command -v pip >/dev/null 2>&1; then
        pip cache purge 2>/dev/null || true
    fi
    # Remove logs antigos deste script
    find "${PREFIX:-/data/data/com.termux/files/usr}/tmp" -name "user-script.log.*" -mtime +7 -delete 2>/dev/null || true
}

# Main script execution
banner
install_sudo
configure_locale_timezone
login
