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

update_apt() {
    log "Atualizando pacotes do sistema..."
    echo -e "${C} [*] Atualizando pacotes...${W}"
    apt-get update -yq || true
    apt-get upgrade -yq || true
    apt-get dist-upgrade -yq 2>/dev/null || true
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

    update_apt
    configure_locale_timezone
    update_gui_scripts
    cleanup

    echo -e "${G} [+] Atualização concluída!${W}"
    log "Atualização concluída"
}

main "$@"
