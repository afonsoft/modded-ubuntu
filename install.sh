#!/usr/bin/env bash
# Script de instalação facilitado para o modded-ubuntu
# Uso: curl -fsSL https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/install.sh | bash

set -e

# Redireciona o stdin para o terminal quando o script é executado via pipe,
# permitindo que prompts do Termux/proot-distro funcionem corretamente.
if [ -r /dev/tty ]; then
    exec 0</dev/tty
fi

REPO_URL="https://github.com/afonsoft/modded-ubuntu.git"
INSTALL_DIR="${HOME}/modded-ubuntu"

echo "[+] Instalador modded-ubuntu"
echo "[+] Diretório de instalação: ${INSTALL_DIR}"

if [ -d "${INSTALL_DIR}" ]; then
    echo "[!] Diretório ${INSTALL_DIR} já existe."
    read -r -p "Deseja remover e clonar novamente? [s/N] " confirm
    if [[ "${confirm}" =~ ^[Ss]$ ]]; then
        rm -rf "${INSTALL_DIR}"
    else
        echo "[+] Cancelado."
        exit 0
    fi
fi

if ! command -v git >/dev/null 2>&1; then
    echo "[+] Git não encontrado. Instalando..."
    if command -v pkg >/dev/null 2>&1; then
        pkg update -y || true
        pkg install -y git || {
            echo "[!] Falha ao instalar git via pkg." >&2
            exit 1
        }
    else
        echo "[!] Gerenciador de pacotes 'pkg' não encontrado. Instale o git manualmente." >&2
        exit 1
    fi
fi

echo "[+] Clonando repositório..."
git clone --depth=1 "${REPO_URL}" "${INSTALL_DIR}"

cd "${INSTALL_DIR}" || {
    echo "[!] Falha ao entrar no diretório ${INSTALL_DIR}" >&2
    exit 1
}

echo "[+] Executando setup.sh..."
bash setup.sh

echo "[+] Instalação concluída."
echo "[+] Reinicie o Termux e execute: ubuntu"
echo "[+] Depois execute: bash user.sh"
