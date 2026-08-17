#!/usr/bin/env bash
set -u

# Instala o Firefox a partir do tarball oficial da Mozilla.
# Funciona dentro do proot quando o pacote .deb e apenas um "snap transitional".

log() {
    echo "[firefox-install] $*" >&2
}

detect_arch() {
    local arch
    if command -v dpkg >/dev/null 2>&1; then
        arch=$(dpkg --print-architecture 2>/dev/null || true)
    fi
    if [ -z "$arch" ]; then
        arch=$(uname -m)
    fi
    case "$arch" in
        amd64|x86_64) echo "linux64" ;;
        arm64|aarch64) echo "linux64-aarch64" ;;
        *) echo "" ;;
    esac
}

install_firefox() {
    local os url tmpdir
    os=$(detect_arch)
    if [ -z "$os" ]; then
        log "Arquitetura nao suportada para o instalador oficial do Firefox."
        exit 1
    fi

    log "Garantindo dependencias de audio..."
    apt-get update -y >/dev/null 2>&1 || true
    apt-get install -y --no-install-recommends libasound2t64 2>/dev/null || \
        apt-get install -y --no-install-recommends libasound2 2>/dev/null || true

    url="https://download.mozilla.org/?product=firefox-latest-ssl&os=${os}&lang=en-US"
    tmpdir=$(mktemp -d)

    log "Baixando Firefox para ${os}..."
    if ! curl -fsSL -o "$tmpdir/firefox.tar.xz" "$url"; then
        rm -rf "$tmpdir"
        log "Falha ao baixar o Firefox de ${url}"
        exit 1
    fi

    log "Extraindo para /opt/firefox..."
    rm -rf /opt/firefox
    mkdir -p /opt
    tar -xf "$tmpdir/firefox.tar.xz" -C /opt
    rm -rf "$tmpdir"

    if [ ! -x /opt/firefox/firefox ]; then
        log "Binario /opt/firefox/firefox nao encontrado apos extracao."
        exit 1
    fi

    # Garante que nao sobrescrevemos um symlink apontando para /opt/firefox/firefox.
    rm -f /usr/local/bin/firefox
    cat > /usr/local/bin/firefox <<'EOF'
#!/bin/sh
unset LD_PRELOAD 2>/dev/null || true
export LD_LIBRARY_PATH=/opt/firefox${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
exec /opt/firefox/firefox "$@"
EOF
    chmod +x /usr/local/bin/firefox

    # Remove o stub de snap, se houver, para dar prioridade ao /opt
    if dpkg -l firefox >/dev/null 2>&1; then
        apt-get purge -y firefox 2>/dev/null || true
    fi

    # Icone
    if [ -f /opt/firefox/browser/icons/mozicon128.png ]; then
        mkdir -p /usr/local/share/icons/hicolor/128x128/apps
        cp -f /opt/firefox/browser/icons/mozicon128.png /usr/local/share/icons/hicolor/128x128/apps/firefox.png
        gtk-update-icon-cache -f /usr/local/share/icons/hicolor 2>/dev/null || true
    fi

    # .desktop global
    mkdir -p /usr/local/share/applications
    cat > /usr/local/share/applications/firefox.desktop <<'EOF'
[Desktop Entry]
Name=Firefox
Comment=Browse the World Wide Web
Exec=firefox %u
Type=Application
Terminal=false
Icon=firefox
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/vnd.mozilla.xul+xml;text/mml;x-scheme-handler/http;x-scheme-handler/https;
TryExec=firefox
EOF

    update-desktop-database /usr/local/share/applications 2>/dev/null || true
    log "Firefox instalado com sucesso: $(firefox --version 2>/dev/null || echo ok)"
}

install_firefox
