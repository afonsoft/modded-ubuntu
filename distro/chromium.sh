#!/usr/bin/env bash
set -u

log() {
    echo "[chromium-install] $*" >&2
}

chromium_bin=""
if [ -f /usr/bin/chromium ]; then
    chromium_bin=/usr/bin/chromium
elif [ -f /usr/bin/chromium-browser ]; then
    chromium_bin=/usr/bin/chromium-browser
fi

if [ -z "$chromium_bin" ]; then
    setup_script=""
    downloaded=0
    if [ -f /usr/local/bin/setup_xtradeb.sh ]; then
        setup_script=/usr/local/bin/setup_xtradeb.sh
    elif [ -f "$(dirname "$0")/setup_xtradeb.sh" ]; then
        setup_script="$(dirname "$0")/setup_xtradeb.sh"
    elif [ -f /data/data/com.termux/files/home/modded-ubuntu/distro/setup_xtradeb.sh ]; then
        setup_script=/data/data/com.termux/files/home/modded-ubuntu/distro/setup_xtradeb.sh
    else
        setup_script=$(mktemp)
        downloaded=1
        if ! curl -fsSL \
            "https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/distro/setup_xtradeb.sh" \
            -o "$setup_script"; then
            rm -f "$setup_script"
            log "Repositorio XtraDeb indisponivel; Chromium nao sera instalado."
            exit 0
        fi
        chmod +x "$setup_script"
    fi

    if ! bash "$setup_script"; then
        [ "$downloaded" -eq 1 ] && rm -f "$setup_script"
        log "Repositorio XtraDeb indisponivel; Chromium nao sera instalado."
        exit 0
    fi

    if ! apt-get install -y --no-install-recommends chromium >/dev/null 2>&1; then
        apt-get install -y --no-install-recommends chromium-browser >/dev/null 2>&1 || true
    fi

    if [ -f /usr/bin/chromium ]; then
        chromium_bin=/usr/bin/chromium
    elif [ -f /usr/bin/chromium-browser ]; then
        chromium_bin=/usr/bin/chromium-browser
    fi
fi

if [ "$downloaded" -eq 1 ]; then
    rm -f "$setup_script"
fi

if [ -z "$chromium_bin" ]; then
    log "Nao foi possivel instalar o Chromium pelo XtraDeb."
    exit 0
fi

cat > /usr/local/bin/chromium <<-EOF
#!/bin/sh
exec $chromium_bin --no-sandbox --disable-gpu "\$@"
EOF
chmod +x /usr/local/bin/chromium

for desktop_file in /usr/share/applications/chromium.desktop \
    /usr/share/applications/chromium-browser.desktop; do
    [ -f "$desktop_file" ] || continue
    sed -i \
        -e '/^Exec=/ { s|^Exec=/usr/bin/chromium-browser|Exec=/usr/local/bin/chromium|; s|^Exec=/usr/bin/chromium|Exec=/usr/local/bin/chromium|; s|^Exec=chromium-browser|Exec=/usr/local/bin/chromium|; s|^Exec=chromium|Exec=/usr/local/bin/chromium|; s/ --no-sandbox//g; }' \
        -e '/^TryExec=/ { s|^TryExec=/usr/bin/chromium-browser$|TryExec=/usr/local/bin/chromium|; s|^TryExec=/usr/bin/chromium$|TryExec=/usr/local/bin/chromium|; s|^TryExec=chromium-browser$|TryExec=/usr/local/bin/chromium|; s|^TryExec=chromium$|TryExec=/usr/local/bin/chromium|; }' \
        "$desktop_file"
done

log "Chromium configurado com o shim /usr/local/bin/chromium."
exit 0
