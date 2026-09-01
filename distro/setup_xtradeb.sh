#!/usr/bin/env bash
set -u

log() {
    echo "[xtradeb] $*" >&2
}

if [ -f /etc/apt/sources.list.d/xtradeb.sources ] &&
    [ -s /etc/apt/keyrings/xtradeb.gpg ]; then
    apt-get update -y >/dev/null 2>&1 || log "Aviso: apt-get update falhou."
    exit 0
fi

apt-get install -y --no-install-recommends curl gnupg ca-certificates >/dev/null 2>&1 || true
mkdir -p /root/.gnupg /etc/apt/keyrings
chmod 700 /root/.gnupg

if ! curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x82BB6851C64F6880" |
    gpg --dearmor --yes -o /etc/apt/keyrings/xtradeb.gpg ||
    [ ! -s /etc/apt/keyrings/xtradeb.gpg ]; then
    log "Nao foi possivel obter a chave GPG do XtraDeb."
    exit 1
fi

version_codename=""
if [ -f /etc/os-release ]; then
    version_codename=$(sed -n 's/^VERSION_CODENAME=//p' /etc/os-release | head -n 1)
fi
version_codename="${version_codename%\"}"
version_codename="${version_codename#\"}"

candidates=()
for candidate in "$version_codename" resolute noble; do
    [ -n "$candidate" ] || continue
    already_added=0
    for existing in "${candidates[@]}"; do
        if [ "$existing" = "$candidate" ]; then
            already_added=1
            break
        fi
    done
    [ "$already_added" -eq 0 ] && candidates+=("$candidate")
done

suite=""
for candidate in "${candidates[@]}"; do
    http_code=$(curl -fsIL --max-time 20 -o /dev/null -w '%{http_code}' \
        "https://ppa.launchpadcontent.net/xtradeb/apps/ubuntu/dists/$candidate/Release" 2>/dev/null || true)
    if [ "$http_code" = "200" ]; then
        suite="$candidate"
        break
    fi
done

if [ -z "$suite" ]; then
    log "Nao foi encontrada uma suite XtraDeb compativel."
    exit 1
fi

cat > /etc/apt/sources.list.d/xtradeb.sources <<-EOF
Types: deb
URIs: https://ppa.launchpadcontent.net/xtradeb/apps/ubuntu
Suites: $suite
Components: main
Signed-By: /etc/apt/keyrings/xtradeb.gpg

Types: deb
URIs: https://ppa.launchpadcontent.net/xtradeb/play/ubuntu
Suites: $suite
Components: main
Signed-By: /etc/apt/keyrings/xtradeb.gpg
EOF

if ! apt-get update -y >/dev/null 2>&1; then
    log "Aviso: apt-get update retornou erro."
fi
log "Repositorio XtraDeb configurado (suite: $suite)."
exit 0
