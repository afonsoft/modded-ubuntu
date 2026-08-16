#!/bin/bash

R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
C="$(printf '\033[1;36m')"
W="$(printf '\033[1;37m')"

CURR_DIR=$(realpath "$(dirname "${BASH_SOURCE[0]}")")

resolve_ubuntu_dir() {
    if [ -d "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu" ]; then
        printf '%s' "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"
    elif [ -d "$PREFIX/var/lib/proot-distro/containers/ubuntu/rootfs" ]; then
        printf '%s' "$PREFIX/var/lib/proot-distro/containers/ubuntu/rootfs"
    else
        printf '%s' "$PREFIX/var/lib/proot-distro/installed-rootfs/ubuntu"
    fi
}

UBUNTU_DIR=$(resolve_ubuntu_dir)

# Logging function
log() {
    local LOG_FILE="${PREFIX:-/data/data/com.termux/files/usr}/tmp/script.log"
    local LOG_DIR
    LOG_DIR=$(dirname "$LOG_FILE")
    
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR" || {
            echo "Failed to create log directory: $LOG_DIR" >&2
            exit 1
        }
    fi
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Mantém o dispositivo acordado durante instalações longas no Termux.
WAKE_LOCKED=false
acquire_wake_lock() {
    if command -v termux-wake-lock >/dev/null 2>&1; then
        termux-wake-lock
        WAKE_LOCKED=true
    fi
}

release_wake_lock() {
    if [ "${WAKE_LOCKED}" = "true" ] && command -v termux-wake-unlock >/dev/null 2>&1; then
        termux-wake-unlock
    fi
}

cleanup_install() {
    # Limpa cache de downloads do Termux/proot-distro quando aplicável
    if command -v pkg >/dev/null 2>&1; then
        pkg clean 2>/dev/null || true
    fi
    if command -v apt-get >/dev/null 2>&1; then
        apt-get clean 2>/dev/null || true
    fi
    local proot_cache
    proot_cache="${PREFIX:-/data/data/com.termux/files/usr}/var/lib/proot-distro/dlcache"
    if [ -d "$proot_cache" ]; then
        rm -rf "${proot_cache:?}"/* 2>/dev/null || true
    fi
    rm -f "$CURR_DIR/vncstart" "$CURR_DIR/vncstop" "$CURR_DIR/user.sh" 2>/dev/null || true
}

cleanup_setup() {
    cleanup_install
    release_wake_lock
}
trap cleanup_setup EXIT

banner() {
    clear
    printf "\033[33m    _  _ ___  _  _ _  _ ___ _  _    _  _ ____ ___  \033[0m\n"
    printf "\033[36m    |  | |__] |  | |\ |  |  |  |    |\/| |  | |  \ \033[0m\n"
    printf "\033[32m    |__| |__] |__| | \|  |  |__|    |  | |__| |__/ \033[0m\n"
    printf "\033[0m\n"
    printf "     \033[32mA modded GUI version of Ubuntu for Termux\033[0m\n"
    printf "\033[0m\n"
}

package() {
    banner
    log "Checking required packages..."
    echo -e "${R} [${W}-${R}]${C} Checking required packages...${W}"
    
    if [ ! -d '/data/data/com.termux/files/home/storage' ]; then
        log "Setting up storage..."
        echo -e "${R} [${W}-${R}]${C} Setting up Storage...${W}"
        termux-setup-storage
    fi

    if [[ $(command -v pulseaudio) && $(command -v proot-distro) ]]; then
        log "Packages already installed."
        echo -e "\n${R} [${W}-${R}]${G} Packages already installed.${W}"
    else
        if ! command -v pkg &> /dev/null; then
            echo "Package manager 'pkg' is not installed. Please install Termux properly." >&2
            exit 1
        fi

        pkg upgrade -y
        packs=(pulseaudio proot-distro)
        for x in "${packs[@]}"; do
            if ! pkg install -y "$x"; then
                log "Failed to install package: $x"
                echo -e "\n${R} [${W}-${R}]${G} Failed to install package: ${Y}$x${C}${W}"
                exit 1
            fi
        done
    fi
}

distro() {
    echo -e "\n${R} [${W}-${R}]${C} Checking for Distro...${W}"
    termux-reload-settings
    
    UBUNTU_DIR=$(resolve_ubuntu_dir)

    if [[ -d "$UBUNTU_DIR" ]]; then
        echo -e "\n${R} [${W}-${R}]${G} Distro already installed.${W}"
        return 0
    else
        if ! proot-distro install ubuntu; then
            echo -e "\n${R} [${W}-${R}]${G} Error Installing Distro !\n${W}"
            exit 1
        fi
        termux-reload-settings
    fi

    UBUNTU_DIR=$(resolve_ubuntu_dir)

    if [[ -d "$UBUNTU_DIR" ]]; then
        echo -e "\n${R} [${W}-${R}]${G} Installed Successfully !!${W}"
    else
        echo -e "\n${R} [${W}-${R}]${G} Error Installing Distro !\n${W}"
        exit 1
    fi
}

sound() {
    echo -e "\n${R} [${W}-${R}]${C} Fixing Sound Problem...${W}"

    cat > "$HOME/.sound" <<'EOF'
#!/usr/bin/env bash
# Sound fix for modded-ubuntu
if command -v pulseaudio >/dev/null 2>&1; then
    pulseaudio --start --exit-idle-time=-1 >/dev/null 2>&1
    # Aguarda o daemon do PulseAudio iniciar
    for _ in {1..20}; do
        pulseaudio --check 2>/dev/null && break
        sleep 0.25
    done
fi

module_loaded() {
    command -v pactl >/dev/null 2>&1 && pactl list modules short 2>/dev/null | grep -q "$1"
}

if ! module_loaded "module-aaudio-sink"; then
    pacmd load-module module-aaudio-sink >/dev/null 2>&1 || true
fi
if ! module_loaded "module-aaudio-source"; then
    pacmd load-module module-aaudio-source >/dev/null 2>&1 || true
fi
if ! module_loaded "module-native-protocol-tcp"; then
    pacmd load-module module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1 >/dev/null 2>&1 || true
fi
EOF
}

downloader() {
    path="$1"
    [ -e "$path" ] && rm -rf "$path"
    echo "Downloading $(basename "$1")..."
    
    if ! command -v curl &> /dev/null; then
        echo "curl is not installed. Please install curl." >&2
        exit 1
    fi

    if ! curl --progress-bar --fail --retry-connrefused --retry 3 --retry-delay 2 --location --output "${path}" "$2"; then
        echo -e "\n${R} [${W}-${R}]${G} Failed to download $(basename "$1")!${W}"
        exit 1
    fi
    echo
}

setup_vnc() {
    if [[ -d "$CURR_DIR/distro" ]] && [[ -e "$CURR_DIR/distro/vncstart" ]]; then
        cp -f "$CURR_DIR/distro/vncstart" "$UBUNTU_DIR/usr/local/bin/vncstart"
        cp -f "$CURR_DIR/distro/vncstop" "$UBUNTU_DIR/usr/local/bin/vncstop"
        cp -f "$CURR_DIR/distro/vncstart-fhd" "$UBUNTU_DIR/usr/local/bin/vncstart-fhd" 2>/dev/null || true
        cp -f "$CURR_DIR/distro/vncstart-qhd" "$UBUNTU_DIR/usr/local/bin/vncstart-qhd" 2>/dev/null || true
    else
        downloader "$CURR_DIR/vncstart" "https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/distro/vncstart"
        mv -f "$CURR_DIR/vncstart" "$UBUNTU_DIR/usr/local/bin/vncstart"
        downloader "$CURR_DIR/vncstop" "https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/distro/vncstop"
        mv -f "$CURR_DIR/vncstop" "$UBUNTU_DIR/usr/local/bin/vncstop"
    fi
    chmod +x "$UBUNTU_DIR/usr/local/bin/vncstart"
    chmod +x "$UBUNTU_DIR/usr/local/bin/vncstop"
    if [[ -e "$UBUNTU_DIR/usr/local/bin/vncstart-fhd" ]]; then
        chmod +x "$UBUNTU_DIR/usr/local/bin/vncstart-fhd"
    fi
    if [[ -e "$UBUNTU_DIR/usr/local/bin/vncstart-qhd" ]]; then
        chmod +x "$UBUNTU_DIR/usr/local/bin/vncstart-qhd"
    fi
}

permission() {
    banner
    echo -e "${R} [${W}-${R}]${C} Setting up Environment...${W}"

    # Setup user.sh
    if [[ -d "$CURR_DIR/distro" ]] && [[ -e "$CURR_DIR/distro/user.sh" ]]; then
        cp -f "$CURR_DIR/distro/user.sh" "$UBUNTU_DIR/root/user.sh"
    else
        downloader "$CURR_DIR/user.sh" "https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/distro/user.sh"
        mv -f "$CURR_DIR/user.sh" "$UBUNTU_DIR/root/user.sh"
    fi
    chmod +x "$UBUNTU_DIR/root/user.sh"

    UBUNTU_DIR=$(resolve_ubuntu_dir)

    setup_vnc

    if [[ -e "$CURR_DIR/distro/s26-optimize.sh" ]]; then
        cp -f "$CURR_DIR/distro/s26-optimize.sh" "$UBUNTU_DIR/usr/local/bin/s26-optimize"
        chmod +x "$UBUNTU_DIR/usr/local/bin/s26-optimize"
    fi

    if [[ -e "$CURR_DIR/distro/csharp.sh" ]]; then
        cp -f "$CURR_DIR/distro/csharp.sh" "$UBUNTU_DIR/usr/local/bin/csharp-setup"
        chmod +x "$UBUNTU_DIR/usr/local/bin/csharp-setup"
    fi

    if [[ -e "$CURR_DIR/distro/nodejs.sh" ]]; then
        cp -f "$CURR_DIR/distro/nodejs.sh" "$UBUNTU_DIR/usr/local/bin/node-setup"
        chmod +x "$UBUNTU_DIR/usr/local/bin/node-setup"
    fi

    if [[ -e "$CURR_DIR/distro/angular.sh" ]]; then
        cp -f "$CURR_DIR/distro/angular.sh" "$UBUNTU_DIR/usr/local/bin/angular-setup"
        chmod +x "$UBUNTU_DIR/usr/local/bin/angular-setup"
    fi

    if [[ -e "$CURR_DIR/distro/update-system.sh" ]]; then
        cp -f "$CURR_DIR/distro/update-system.sh" "$UBUNTU_DIR/usr/local/bin/update-system"
        chmod +x "$UBUNTU_DIR/usr/local/bin/update-system"
    fi

    if [[ -e "$CURR_DIR/distro/gui.sh" ]]; then
        cp -f "$CURR_DIR/distro/gui.sh" "$UBUNTU_DIR/usr/local/bin/gui.sh"
        chmod +x "$UBUNTU_DIR/usr/local/bin/gui.sh"
    fi

    # Optional Termux performance tweaks for Samsung S26 / high-end devices
    if [[ -n "${TERMUX_VERSION:-}" ]]; then
        mkdir -p "$HOME/.termux"
        if [[ ! -f "$HOME/.termux/termux.properties" ]]; then
            cp -f "$CURR_DIR/distro/termux-s26.properties" "$HOME/.termux/termux.properties" 2>/dev/null || true
        fi
    fi

    local timezone termux_prefix
    timezone=$(getprop persist.sys.timezone 2>/dev/null || true)
    [ -z "$timezone" ] && timezone="${TZ:-America/Sao_Paulo}"
    echo "$timezone" > "$UBUNTU_DIR/etc/timezone"

    # Locale padrão em inglês americano; user.sh reforça a configuração
    if [ ! -f "$UBUNTU_DIR/etc/default/locale" ]; then
        mkdir -p "$UBUNTU_DIR/etc/default"
        printf 'LANG=en_US.UTF-8\nLANGUAGE=en_US:en\n' > "$UBUNTU_DIR/etc/default/locale"
    fi

    termux_prefix="${PREFIX:-/data/data/com.termux/files/usr}"
    if [ ! -f "$termux_prefix/bin/ubuntu" ]; then
        echo "proot-distro login --no-sysvipc ubuntu" > "$termux_prefix/bin/ubuntu"
    fi
    chmod +x "$termux_prefix/bin/ubuntu"
    termux-reload-settings

    if [[ -e "$PREFIX/bin/ubuntu" ]]; then
        banner
        cat <<- EOF
			${R} [${W}-${R}]${G} Ubuntu-26.04 (CLI) is now Installed on your Termux
			${R} [${W}-${R}]${G} Restart your Termux to Prevent Some Issues.
			${R} [${W}-${R}]${G} Type ${C}ubuntu${G} to run Ubuntu CLI.
			${R} [${W}-${R}]${G} If you Want to Use UBUNTU in GUI MODE then ,
			${R} [${W}-${R}]${G} Run ${C}ubuntu${G} first & then type ${C}bash user.sh${W}
		EOF
        { echo; sleep 2; exit 0; }
    else
        echo -e "\n${R} [${W}-${R}]${G} Error Installing Distro !${W}"
        exit 1
    fi
}

acquire_wake_lock
package
distro
sound
permission
