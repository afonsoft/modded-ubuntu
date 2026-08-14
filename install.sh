#!/usr/bin/env bash
# Script de instalação facilitado para o modded-ubuntu
# Uso: curl -fsSL https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/install.sh | bash

set -e

LOG_FILE="${HOME}/modded-ubuntu-install.log"
: > "${LOG_FILE}"

log() {
    local msg
    msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    printf '%s\n' "${msg}"
    printf '%s\n' "${msg}" >> "${LOG_FILE}"
}

REPO_URL="https://github.com/afonsoft/modded-ubuntu.git"
INSTALL_DIR="${HOME}/modded-ubuntu"

log "[+] Iniciando instalador modded-ubuntu"
log "[+] Log: ${LOG_FILE}"
log "[+] Diretório de instalação: ${INSTALL_DIR}"

# Garante que o Termux esteja atualizado e com as dependências básicas.
if command -v pkg >/dev/null 2>&1; then
    log "[+] Atualizando lista de pacotes (pkg update -y)..."
    pkg update -y

    log "[+] Instalando dependências (git, curl, wget, proot-distro, pulseaudio)..."
    pkg install -y git curl wget proot-distro pulseaudio
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
