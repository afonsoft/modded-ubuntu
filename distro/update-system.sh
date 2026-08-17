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

# Preferencia pelo repositorio local do Termux (atualizado pelo update.sh).
# Fall back para download direto do master quando o local nao estiver disponivel.
get_repo_dir() {
    local local_repo="/data/data/com.termux/files/home/modded-ubuntu"
    if [ -d "${local_repo}/distro" ]; then
        echo "$local_repo"
    fi
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

    local base_url="https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/distro"
    local scripts=("vncstart" "vncstop" "vncstart-fhd" "vncstart-qhd")
    local repo_dir
    repo_dir=$(get_repo_dir)
    local tmp_dir
    tmp_dir="$(mktemp -d)"

    local script
    for script in "${scripts[@]}"; do
        local src_file=""
        local dest="/usr/local/bin/${script}"

        if [ -n "$repo_dir" ] && [ -f "${repo_dir}/distro/${script}" ]; then
            src_file="${repo_dir}/distro/${script}"
        elif command -v curl >/dev/null 2>&1 && \
             curl --fail --retry 3 --retry-delay 2 --location --output "${tmp_dir}/${script}" "${base_url}/${script}" >/dev/null 2>&1; then
            src_file="${tmp_dir}/${script}"
        fi

        if [ -n "$src_file" ]; then
            cp -f "$src_file" "$dest"
            chmod +x "$dest"
            log "${script} atualizado em ${dest}"
        else
            warn "Falha ao atualizar ${script}. Versão atual mantida."
        fi
    done

    rm -rf "$tmp_dir"
}

update_gui_scripts() {
    log "Atualizando gui.sh e firefox.sh..."
    echo -e "${C} [*] Atualizando gui.sh...${W}"

    local base_url="https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/distro"
    local scripts=("gui.sh" "firefox.sh")
    local repo_dir
    repo_dir=$(get_repo_dir)
    local tmp_dir
    tmp_dir="$(mktemp -d)"

    local script
    for script in "${scripts[@]}"; do
        local src_file=""
        local dest="/usr/local/bin/${script}"

        if [ -n "$repo_dir" ] && [ -f "${repo_dir}/distro/${script}" ]; then
            src_file="${repo_dir}/distro/${script}"
        elif command -v curl >/dev/null 2>&1 && \
             curl --fail --retry 3 --retry-delay 2 --location --output "${tmp_dir}/${script}" "${base_url}/${script}" >/dev/null 2>&1; then
            src_file="${tmp_dir}/${script}"
        fi

        if [ -n "$src_file" ]; then
            cp -f "$src_file" "$dest"
            chmod +x "$dest"
            log "${script} atualizado em ${dest}"
        else
            warn "Falha ao atualizar ${script}. Versão atual mantida."
        fi
    done
    rm -rf "$tmp_dir"

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

update_desktop_files() {
    log "Atualizando atalhos .desktop do menu..."
    echo -e "${C} [*] Atualizando atalhos .desktop...${W}"

    local repo_dir="${1:-}"
    local desktop_src="/usr/local/share/modded-ubuntu/xfce-config/desktop"

    if [ -n "$repo_dir" ] && [ -d "${repo_dir}/distro/xfce-config/desktop" ]; then
        desktop_src="${repo_dir}/distro/xfce-config/desktop"
    fi

    # Instala/atualiza os .desktop globais do modded-ubuntu
    local global_app_dir="/usr/local/share/applications"
    mkdir -p "$global_app_dir"
    if [ -d "$desktop_src" ]; then
        cp -f "$desktop_src/"*.desktop "$global_app_dir/" 2>/dev/null || true
        chmod 644 "$global_app_dir/"*.desktop 2>/dev/null || true
    fi

    # Aplica o patch do VS Code: sem sandbox dentro do PRoot
    local code_patch="/usr/local/share/modded-ubuntu/patches/code.desktop"
    if [ -n "$repo_dir" ] && [ -f "${repo_dir}/patches/code.desktop" ]; then
        code_patch="${repo_dir}/patches/code.desktop"
    fi
    if [ -f "$code_patch" ]; then
        cp -f "$code_patch" "$global_app_dir/code.desktop" 2>/dev/null || true
        chmod 644 "$global_app_dir/code.desktop" 2>/dev/null || true
        cp -f "$code_patch" "/usr/share/applications/code.desktop" 2>/dev/null || true
        chmod 644 "/usr/share/applications/code.desktop" 2>/dev/null || true
    fi

    # Corrige o .desktop do Chromium caso ainda venha sem --no-sandbox
    if [ -f "/usr/share/applications/chromium.desktop" ]; then
        sed -i 's/chromium %U/chromium --no-sandbox %U/g' "/usr/share/applications/chromium.desktop" 2>/dev/null || true
    fi
    if [ -f "$global_app_dir/chromium.desktop" ]; then
        sed -i 's/chromium %U/chromium --no-sandbox %U/g' "$global_app_dir/chromium.desktop" 2>/dev/null || true
    fi

    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$global_app_dir" 2>/dev/null || true
        update-desktop-database "/usr/share/applications" 2>/dev/null || true
    fi

    # Atualiza os atalhos por usuário
    awk -F: '$3 >= 1000 && $3 < 65534 {print $1, $6}' /etc/passwd 2>/dev/null | while IFS=' ' read -r username home_dir; do
        if [ ! -d "$home_dir" ]; then
            continue
        fi
        user_app_dir="$home_dir/.local/share/applications"
        mkdir -p "$user_app_dir"
        if [ -d "$desktop_src" ]; then
            cp -f "$desktop_src/"*.desktop "$user_app_dir/" 2>/dev/null || true
            chmod 644 "$user_app_dir/"*.desktop 2>/dev/null || true
        fi
        if [ -f "$code_patch" ]; then
            cp -f "$code_patch" "$user_app_dir/code.desktop" 2>/dev/null || true
            chmod 644 "$user_app_dir/code.desktop" 2>/dev/null || true
        fi
        chown -R "$username:" "$home_dir/.local" 2>/dev/null || true
        if command -v update-desktop-database >/dev/null 2>&1; then
            update-desktop-database "$user_app_dir" 2>/dev/null || true
        fi
    done
}

update_systemd_vnc_service() {
    log "Atualizando configuração systemd do VNC..."
    echo -e "${C} [*] Atualizando configuração systemd do VNC...${W}"

    local repo_dir="${1:-}"
    local service_src="/usr/local/share/modded-ubuntu/systemd/modded-ubuntu-vnc.service"
    local service_dest="/etc/systemd/user/modded-ubuntu-vnc.service"

    if [ -n "$repo_dir" ] && [ -f "${repo_dir}/distro/systemd/modded-ubuntu-vnc.service" ]; then
        service_src="${repo_dir}/distro/systemd/modded-ubuntu-vnc.service"
    fi

    if [ ! -f "$service_src" ]; then
        warn "Arquivo de serviço systemd não encontrado. Pulando."
        return 0
    fi

    mkdir -p "/etc/systemd/user"
    cp -f "$service_src" "$service_dest"
    chmod 644 "$service_dest"
    log "Serviço systemd do VNC atualizado em $service_dest"

    if command -v systemctl >/dev/null 2>&1; then
        systemctl daemon-reload 2>/dev/null || true
        awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd 2>/dev/null | while IFS=' ' read -r username; do
            user_id=$(id -u "$username" 2>/dev/null || echo "")
            if [ -n "$user_id" ]; then
                XDG_RUNTIME_DIR="/run/user/$user_id" su -s /bin/bash -c "systemctl --user daemon-reload 2>/dev/null || true" "$username" 2>/dev/null || true
            fi
        done
    fi
}

update_zsh_config() {
    log "Atualizando configuração do zsh..."
    echo -e "${C} [*] Atualizando zsh + Oh My Zsh + Powerlevel10k...${W}"

    local zsh_script="/usr/local/bin/zsh-setup"
    local repo_dir
    repo_dir=$(get_repo_dir)

    if [ -n "$repo_dir" ] && [ -f "${repo_dir}/distro/zsh-setup.sh" ]; then
        cp -f "${repo_dir}/distro/zsh-setup.sh" "$zsh_script"
    elif command -v curl >/dev/null 2>&1; then
        curl -fsSL --retry 3 --retry-delay 2 \
            "https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/distro/zsh-setup.sh" \
            -o "$zsh_script" 2>/dev/null || true
    fi
    chmod +x "$zsh_script" 2>/dev/null || true

    if [ -x "$zsh_script" ]; then
        bash "$zsh_script" --all 2>/dev/null || true
    fi
}

update_xfce_config() {
    log "Atualizando configurações XFCE, .desktop e systemd..."
    echo -e "${C} [*] Atualizando configurações XFCE, .desktop e systemd...${W}"

    local repo_dir
    repo_dir=$(get_repo_dir)
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    local download_ok=0

    # Prefere o repositorio local do Termux; caso nao exista, baixa o master.
    if [ -z "$repo_dir" ]; then
        local base_url="https://github.com/afonsoft/modded-ubuntu/archive/refs/heads/master.tar.gz"
        if command -v curl >/dev/null 2>&1 && \
           curl --fail --retry 3 --retry-delay 2 --location --output "${tmp_dir}/repo.tar.gz" "$base_url" >/dev/null 2>&1; then
            if tar -xzf "${tmp_dir}/repo.tar.gz" -C "$tmp_dir" >/dev/null 2>&1; then
                repo_dir=$(find "$tmp_dir" -maxdepth 1 -type d -name "modded-ubuntu-*" | head -n 1)
                if [ -n "$repo_dir" ]; then
                    download_ok=1
                fi
            fi
        fi
    else
        download_ok=1
    fi

    if [ "$download_ok" -eq 1 ] && [ -n "$repo_dir" ] && [ -f "${repo_dir}/distro/xfce-apply.sh" ]; then
        cp -f "${repo_dir}/distro/xfce-apply.sh" /usr/local/bin/xfce-apply
        chmod +x /usr/local/bin/xfce-apply
        rm -rf /usr/local/share/modded-ubuntu/xfce-config
        rm -rf /usr/local/share/modded-ubuntu/systemd
        rm -rf /usr/local/share/modded-ubuntu/patches
        mkdir -p /usr/local/share/modded-ubuntu
        cp -r "${repo_dir}/distro/xfce-config" /usr/local/share/modded-ubuntu/
        if [ -d "${repo_dir}/distro/systemd" ]; then
            cp -r "${repo_dir}/distro/systemd" /usr/local/share/modded-ubuntu/
        fi
        if [ -d "${repo_dir}/patches" ]; then
            cp -r "${repo_dir}/patches" /usr/local/share/modded-ubuntu/
        fi
        log "xfce-apply, xfce-config, systemd e patches atualizados."
    else
        warn "Falha ao obter atualização do repositório. Usando versão local."
    fi

    if [ -x /usr/local/bin/xfce-apply ]; then
        /usr/local/bin/xfce-apply --all
    fi

    update_desktop_files "$repo_dir"
    update_systemd_vnc_service "$repo_dir"

    rm -rf "$tmp_dir"
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
    update_zsh_config
    update_xfce_config
    cleanup

    echo -e "${G} [+] Atualização concluída!${W}"
    log "Atualização concluída"
}

main "$@"
