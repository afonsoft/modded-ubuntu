#!/usr/bin/env bash
# Script de instalação facilitado para o modded-ubuntu
# Uso: curl -fsSL https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/install.sh | bash
#
# No Termux, mantém a tela ligada durante a instalação e verifica espaço antes
# de começar o download do rootfs.

set -e

LOG_FILE="${HOME}/modded-ubuntu-install.log"
: > "${LOG_FILE}"

log() {
    local msg
    msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    printf '%s\n' "${msg}"
    printf '%s\n' "${msg}" >> "${LOG_FILE}"
}

# Mantém o dispositivo acordado durante instalações longas no Termux.
WAKE_LOCKED=false
acquire_wake_lock() {
    if command -v termux-wake-lock >/dev/null 2>&1; then
        if termux-wake-lock >/dev/null 2>&1; then
            WAKE_LOCKED=true
            log "[+] Tela mantida acesa (termux-wake-lock)"
        fi
    fi
}

release_wake_lock() {
    if [ "${WAKE_LOCKED}" = "true" ] && command -v termux-wake-unlock >/dev/null 2>&1; then
        if termux-wake-unlock >/dev/null 2>&1; then
            log "[+] Tela liberada (termux-wake-unlock)"
        fi
    fi
}

cleanup_install() {
    # Limpa caches do Termux e arquivos temporários sem remover o clone do repo
    if command -v pkg >/dev/null 2>&1; then
        pkg clean 2>/dev/null || true
    fi
    if command -v apt-get >/dev/null 2>&1; then
        apt-get clean 2>/dev/null || true
    fi
    rm -f /tmp/modded-ubuntu-*.sh 2>/dev/null || true
}

cleanup() {
    cleanup_install
    release_wake_lock
}
trap cleanup EXIT

REPO_URL="https://github.com/afonsoft/modded-ubuntu.git"
INSTALL_DIR="${HOME}/modded-ubuntu"

# Recomendação do README: pelo menos 5 GB livres.
REQUIRED_KB=$((5 * 1024 * 1024))

check_storage() {
    local avail_kb
    if command -v df >/dev/null 2>&1; then
        avail_kb=$(df -P "$HOME" 2>/dev/null | awk 'NR==2 {print $4}')
    fi

    if [ -n "$avail_kb" ] && [ "$avail_kb" -lt "$REQUIRED_KB" ]; then
        log "[!] Pouco espaço livre em $HOME: ${avail_kb} KB. É recomendado pelo menos 5 GB."
        log "[!] Libere espaço ou use um cartão de memória antes de continuar."
        exit 1
    fi
}

log "[+] Iniciando instalador modded-ubuntu"
log "[+] Log: ${LOG_FILE}"
log "[+] Diretório de instalação: ${INSTALL_DIR}"

acquire_wake_lock

check_storage

# Garante que o Termux esteja atualizado e com as dependências básicas.
if command -v pkg >/dev/null 2>&1; then
    log "[+] Atualizando lista de pacotes (pkg update -y)..."
    pkg update -y

    log "[+] Instalando dependências (git, curl, wget, proot-distro, pulseaudio, termux-am)..."
    pkg install -y git curl wget proot-distro pulseaudio termux-am
else
    log "[!] Gerenciador de pacotes 'pkg' não encontrado. Pulando instalação de dependências." >&2
fi

# Se o diretório de instalação já existir, faz backup ao invés de perguntar.
if [ -d "${INSTALL_DIR}" ]; then
    BACKUP_DIR="${INSTALL_DIR}.bak.$(date +%Y%m%d%H%M%S)"
    log "[!] Diretório ${INSTALL_DIR} já existe. Fazendo backup para ${BACKUP_DIR}"
    mv "${INSTALL_DIR}" "${BACKUP_DIR}"
fi

log "[+] Clonando repositório..."
git clone --depth=1 "${REPO_URL}" "${INSTALL_DIR}"

cd "${INSTALL_DIR}" || {
    log "[!] Falha ao entrar no diretório ${INSTALL_DIR}" >&2
    exit 1
}

log "[+] Executando setup.sh..."
bash setup.sh

log "[+] Instalação concluída."
log "[+] Reinicie o Termux e execute: ubuntu"
log "[+] Depois execute: bash user.sh"
