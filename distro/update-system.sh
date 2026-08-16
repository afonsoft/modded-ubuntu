#!/usr/bin/env bash
# Script de atualização para modded-ubuntu já instalado.
# Deve ser executado como root dentro do PRoot (ubuntu).

G="\033[1;32m"
C="\033[1;36m"
Y="\033[1;33m"
W="\033[0m"

export DEBIAN_FRONTEND=noninteractive

# Evita que pacotes tentem iniciar serviços dentro do PRoot
if [ ! -f /usr/sbin/policy-rc.d ]; then
    printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d
    chmod 755 /usr/sbin/policy-rc.d
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a /tmp/update-system.log
}

warn() {
    echo -e "${Y}$*${W}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $*" | tee -a /tmp/update-system.log
}

configure_locale_timezone() {
    log "Configurando locale en_US.UTF-8 e timezone America/Sao_Paulo..."
    echo -e "${C} [*] Aplicando locale en_US.UTF-8 e timezone America/Sao_Paulo...${W}"

    if command -v update-locale >/dev/null 2>&1; then
        update-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL= 2>/dev/null || true
    else
        printf 'LANG=en_US.UTF-8\nLANGUAGE=en_US:en\n' > /etc/default/locale
    fi

    ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
    echo "America/Sao_Paulo" > /etc/timezone

    if command -v dpkg-reconfigure >/dev/null 2>&1; then
        dpkg-reconfigure -f noninteractive tzdata 2>/dev/null || true
    fi

    export LANG=en_US.UTF-8
    export LANGUAGE=en_US:en

    # Reforça locale no .bashrc do root
    if ! grep -q "^export LANG=" /root/.bashrc 2>/dev/null; then
        printf 'export LANG=en_US.UTF-8\nexport LANGUAGE=en_US:en\n' >> /root/.bashrc
    fi

    # Reforça locale nos .bashrc dos usuários comuns
    awk -F: '$3 >= 1000 && $3 < 65534 {print $1, $6}' /etc/passwd 2>/dev/null | while read -r username home_dir; do
        if [ -f "$home_dir/.bashrc" ] && ! grep -q "^export LANG=" "$home_dir/.bashrc" 2>/dev/null; then
            printf 'export LANG=en_US.UTF-8\nexport LANGUAGE=en_US:en\n' >> "$home_dir/.bashrc"
            log "Locale aplicado no .bashrc de $username"
        fi
    done

    log "Locale e timezone configurados."
}

cleanup_unwanted_apt_sources() {
    log "Removendo repositórios indesejados (ex.: Metasploit)..."
    echo -e "${C} [*] Removendo repositórios indesejados...${W}"

    # Remove entradas do sources.list principal
    if grep -qE 'metasploit|rapid7' /etc/apt/sources.list 2>/dev/null; then
        sed -i '/metasploit/d; /rapid7/d' /etc/apt/sources.list
        log "Removidas entradas indesejadas do /etc/apt/sources.list"
    fi

    # Remove arquivos de repositório suspeitos
    find /etc/apt/sources.list.d -type f -print0 2>/dev/null | \
        xargs -0 grep -lE 'metasploit|rapid7' 2>/dev/null | \
        while IFS= read -r f; do
            rm -f "$f"
            log "Removido repositório indesejado: $f"
        done

    # Impede instalação/atualização do metasploit-framework
    mkdir -p /etc/apt/preferences.d
    if [ ! -f /etc/apt/preferences.d/modded-ubuntu-no-metasploit ]; then
        cat > /etc/apt/preferences.d/modded-ubuntu-no-metasploit <<'EOF'
Package: metasploit-framework
Pin: origin downloads.metasploit.com
Pin-Priority: -1
EOF
        log "Adicionado pinning para bloquear metasploit-framework"
    fi

    # Segura o pacote caso já esteja instalado
    if dpkg -l metasploit-framework 2>/dev/null | grep -q '^ii'; then
        apt-mark hold metasploit-framework >/dev/null 2>&1 || true
        log "metasploit-framework detectado e marcado como hold."
    fi
}

fix_sound() {
    log "Corrigindo configuração de áudio..."
    echo -e "${C} [*] Corrigindo configuração de áudio...${W}"

    local sound_file
    sound_file="/data/data/com.termux/files/home/.sound"

    for f in "$sound_file" "$HOME/.sound"; do
        [ -e "$f" ] || continue
        cat > "$f" <<'EOF'
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
        log "Arquivo de som atualizado: $f"
    done
}

update_apt() {
    log "Atualizando pacotes do sistema..."
    echo -e "${C} [*] Atualizando pacotes...${W}"
    apt-get update -yq || true
    apt-get upgrade -yq || true
    apt-get dist-upgrade -yq 2>/dev/null || true
}

update_vnc_scripts() {
    log "Atualizando scripts VNC..."
    echo -e "${C} [*] Atualizando scripts VNC...${W}"

    if ! command -v curl >/dev/null 2>&1; then
        warn "curl não encontrado. Pulando atualização dos scripts VNC."
        return 0
    fi

    local base_url="https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/distro"
    local scripts=("vncstart" "vncstop" "vncstart-fhd" "vncstart-qhd")
    local tmp_dir
    tmp_dir="$(mktemp -d)"

    local script
    for script in "${scripts[@]}"; do
        local tmp_file="${tmp_dir}/${script}"
        local dest="/usr/local/bin/${script}"
        if curl --fail --retry 3 --retry-delay 2 --location --output "$tmp_file" "${base_url}/${script}" >/dev/null 2>&1; then
            cp -f "$tmp_file" "$dest"
            chmod +x "$dest"
            log "${script} atualizado em ${dest}"
        else
            warn "Falha ao baixar ${script}. Versão atual mantida."
        fi
    done

    rm -rf "$tmp_dir"
}

update_gui_scripts() {
    log "Atualizando gui.sh nos diretórios dos usuários..."
    echo -e "${C} [*] Atualizando gui.sh...${W}"

    if [ ! -f /usr/local/bin/gui.sh ]; then
        warn "/usr/local/bin/gui.sh não encontrado. Pulando atualização do gui.sh."
        return 0
    fi

    awk -F: '$3 >= 1000 && $3 < 65534 {print $1, $6}' /etc/passwd 2>/dev/null | while read -r username home_dir; do
        if [ -d "$home_dir" ]; then
            cp -f /usr/local/bin/gui.sh "$home_dir/gui.sh"
            chown "$username:" "$home_dir/gui.sh" 2>/dev/null || true
            log "gui.sh atualizado em $home_dir/gui.sh"
        fi
    done
}

cleanup() {
    log "Limpando pacotes e caches..."
    echo -e "${C} [*] Limpando caches...${W}"
    apt-get autoremove -y --purge 2>/dev/null || true
    apt-get clean 2>/dev/null || true
    if command -v npm >/dev/null 2>&1; then
        npm cache clean --force 2>/dev/null || true
    fi
    if command -v pip >/dev/null 2>&1; then
        pip cache purge 2>/dev/null || true
    fi
    rm -f /tmp/update-system.log.* 2>/dev/null || true
}

main() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${Y} [!] Execute como root dentro do ubuntu (ex.: sudo update-system)${W}"
        exit 1
    fi

    echo -e "${G} [+] Iniciando atualização do modded-ubuntu...${W}"
    log "Iniciando atualização"

    cleanup_unwanted_apt_sources
    update_apt
    configure_locale_timezone
    fix_sound
    update_vnc_scripts
    update_gui_scripts
    cleanup

    echo -e "${G} [+] Atualização concluída!${W}"
    log "Atualização concluída"
}

main "$@"
