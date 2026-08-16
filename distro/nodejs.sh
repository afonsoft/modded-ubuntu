#!/usr/bin/env bash
# Node.js para o modded-ubuntu
# Instala o Node.js LTS a partir do repositório Ubuntu (apt),
# evitando downloads manuais do nodejs.org dentro do PRoot.
# Pode ser executado standalone ou chamado por distro/gui.sh

R="$(printf '\033[1;31m')"
Y="$(printf '\033[1;33m')"
C="$(printf '\033[1;36m')"
W="$(printf '\033[1;37m')"

log()  { echo -e "${C}[nodejs]${W} $1"; }
warn() { echo -e "${Y}[nodejs]${W} $1"; }
err()  { echo -e "${R}[nodejs]${W} $1"; }

detect_user() {
	local user_name=""
	if [ -n "${SUDO_USER:-}" ] && getent passwd "$SUDO_USER" >/dev/null 2>&1; then
		user_name="$SUDO_USER"
	elif command -v logname >/dev/null 2>&1; then
		user_name=$(logname 2>/dev/null) || true
	fi
	if [ -z "$user_name" ] || [ "$user_name" = "root" ]; then
		user_name=$(awk -F: '$3 >= 1000 && $6 ~ /^\/home\// {print $1; exit}' /etc/passwd)
	fi
	if [ -z "$user_name" ]; then
		user_name="root"
	fi
	echo "$user_name"
}

user_home() {
	local user="$1"
	local home_dir=""
	home_dir=$(getent passwd "$user" 2>/dev/null | cut -d: -f6)
	if [ -z "$home_dir" ]; then
		home_dir="$HOME"
	fi
	echo "$home_dir"
}

enable_universe_repo() {
	local suite=""
	if [ -f /etc/os-release ]; then
		suite=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
	fi
	if [ -z "$suite" ]; then
		suite="resolute"
	fi

	if ! grep -rEq "^deb .* ${suite}( .*|) universe" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null; then
		warn "Habilitando repositório universe para o suite ${suite}..."
		echo "deb http://ports.ubuntu.com/ubuntu-ports ${suite} universe" > /etc/apt/sources.list.d/modded-ubuntu-universe.list
	fi
}

remove_previous_node() {
	local target_user
	target_user=$(detect_user)
	local home_dir
	home_dir=$(user_home "$target_user")

	# Remove instalação anterior do NVM, se existir
	if [ -d "$home_dir/.nvm" ]; then
		warn "Removendo instalação anterior do NVM em $home_dir/.nvm..."
		rm -rf "$home_dir/.nvm"
	fi

	if [ -f "$home_dir/.bashrc" ]; then
		sed -i '/# Ativar a versão padrão do Node\.js gerenciada pelo nvm/d' "$home_dir/.bashrc" 2>/dev/null || true
		sed -i '/export NVM_DIR=/d' "$home_dir/.bashrc" 2>/dev/null || true
		sed -i '/\[ -s "\$NVM_DIR\/nvm\.sh" \] && \\\.*\$NVM_DIR\/nvm\.sh"/d' "$home_dir/.bashrc" 2>/dev/null || true
		sed -i '/nvm use default/d' "$home_dir/.bashrc" 2>/dev/null || true
		sed -i '/# Node.js instalado manualmente/d' "$home_dir/.bashrc" 2>/dev/null || true
		sed -i '\|/usr/local/lib/nodejs/bin|d' "$home_dir/.bashrc" 2>/dev/null || true
	fi

	# Remove instalação manual anterior do Node.js, se existir
	if [ -d /usr/local/lib/nodejs ]; then
		warn "Removendo instalação manual anterior do Node.js em /usr/local/lib/nodejs..."
		rm -rf /usr/local/lib/nodejs
	fi

	for bin in node npm npx corepack ng; do
		if [ -e "/usr/local/bin/$bin" ]; then
			rm -f "/usr/local/bin/$bin"
		fi
	done

	if [ -f /etc/profile.d/nodejs.sh ]; then
		rm -f /etc/profile.d/nodejs.sh
	fi
}

install_prerequisites() {
	log "Atualizando repositórios e instalando dependências do Node.js..."
	enable_universe_repo
	apt-get update -yq
	apt-get install -yq --no-install-recommends \
		ca-certificates curl || true
	log "Dependências do Node.js instaladas."
}

install_node() {
	local target_user
	target_user=$(detect_user)
	local home_dir
	home_dir=$(user_home "$target_user")

	log "Instalando Node.js LTS via apt (repositório Ubuntu)..."

	remove_previous_node

	if ! apt-get install -yq --no-install-recommends nodejs npm; then
		err "Falha ao instalar nodejs/npm via apt."
		return 1
	fi

	# Atualiza o PATH imediatamente
	hash -r 2>/dev/null || true

	log "Node.js instalado via apt."
}

print_versions() {
	hash -r 2>/dev/null || true
	if command -v node >/dev/null 2>&1; then
		log "Node.js disponível: $(node --version)"
	else
		warn "node não está disponível no PATH imediatamente."
	fi
	if command -v npm >/dev/null 2>&1; then
		log "npm disponível: $(npm --version)"
	else
		warn "npm não está disponível no PATH imediatamente."
	fi
}

cleanup() {
	log "Limpando arquivos temporários e caches..."
	rm -rf /tmp/node-install-cache
	rm -f /tmp/nvm-install.sh
	apt-get autoremove -y --purge 2>/dev/null || true
	apt-get clean 2>/dev/null || true
	if command -v npm >/dev/null 2>&1; then
		npm cache clean --force 2>/dev/null || true
	fi
	if command -v pip >/dev/null 2>&1; then
		pip cache purge 2>/dev/null || true
	fi
}

main() {
	install_prerequisites
	install_node
	print_versions
	cleanup
	log "Node.js configurado."
}

main "$@"
