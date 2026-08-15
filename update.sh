#!/usr/bin/env bash
# Atualiza uma instalação existente do modded-ubuntu.
# Uso (no Termux):
#   cd ~/modded-ubuntu && bash update.sh
# ou
#   curl -fsSL https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/update.sh | bash

set -e

REPO_URL="https://github.com/afonsoft/modded-ubuntu.git"
INSTALL_DIR="${HOME}/modded-ubuntu"

LOG_FILE="${HOME}/modded-ubuntu-update.log"
: > "${LOG_FILE}"

log() {
    local msg
    msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    printf '%s\n' "${msg}"
    printf '%s\n' "${msg}" >> "${LOG_FILE}"
}

if [ ! -d "${INSTALL_DIR}/.git" ]; then
    log "Clonando repositório em ${INSTALL_DIR}..."
    git clone --depth=1 "${REPO_URL}" "${INSTALL_DIR}"
else
    log "Atualizando repositório em ${INSTALL_DIR}..."
    git -C "${INSTALL_DIR}" pull
fi

cd "${INSTALL_DIR}" || {
    log "[!] Não foi possível entrar em ${INSTALL_DIR}" >&2
    exit 1
}

log "[+] Executando setup.sh para atualizar scripts/helpers..."
bash setup.sh

log "[+] Atualizando pacotes e configurações dentro do Ubuntu..."
if ! proot-distro login --no-sysvipc ubuntu -- bash /usr/local/bin/update-system; then
    log "[!] update-system retornou erro. Verifique o log dentro do proot em /tmp/update-system.log" >&2
    exit 1
fi

log "[+] Atualização concluída. Reinicie o Termux se desejar."
