#!/usr/bin/env bash
# Node.js para o modded-ubuntu
# Instala o Node.js LTS a partir do repositório NodeSource (.deb),
# evitando downloads manuais do nodejs.org dentro do PRoot.
# Pode ser executado standalone ou chamado por distro/gui.sh

export DEBIAN_FRONTEND=noninteractive

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
		sed -i '/\[ -s "\$NVM_DIR\/nvm\.sh" \] && \\.*\$NVM_DIR\/nvm\.sh"/d' "$home_dir/.bashrc" 2>/dev/null || true
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

	# Remove pacotes antigos do apt para evitar conflitos com o NodeSource
	if dpkg -l 2>/dev/null | grep -qE '^(ii|iU|rc) (nodejs|npm) '; then
		warn "Removendo pacotes nodejs/npm anteriores dos repositórios Ubuntu..."
		apt-get purge -yq nodejs npm >/dev/null 2>&1 || true
		dpkg --remove --force-remove-reinstreq npm >/dev/null 2>&1 || true
		dpkg --remove --force-remove-reinstreq nodejs >/dev/null 2>&1 || true
		dpkg --purge nodejs npm >/dev/null 2>&1 || true
		apt-get autoremove -yq >/dev/null 2>&1 || true
	fi
}

install_prerequisites() {
	log "Atualizando repositórios e instalando dependências do Node.js..."
	apt-get update -yq
	apt-get install -yq --no-install-recommends ca-certificates curl gnupg
	log "Dependências do Node.js instaladas."
}

install_nodesource() {
	local deb_arch
	deb_arch=$(dpkg --print-architecture 2>/dev/null || uname -m)
	case "$deb_arch" in
		arm64|aarch64) deb_arch="arm64" ;;
		x86_64|amd64)  deb_arch="amd64" ;;
		armhf|armv7l)  deb_arch="armhf" ;;
	esac

	log "Configurando repositório NodeSource para ${deb_arch}..."

	mkdir -p /etc/apt/keyrings
	if [ ! -f /etc/apt/keyrings/nodesource.gpg ]; then
		if curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg 2>/dev/null; then
			log "Chave GPG do NodeSource importada."
		else
			warn "Não foi possível importar a chave GPG do NodeSource; continuando sem verificação."
		fi
	fi

	echo "deb [arch=${deb_arch} signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" > /etc/apt/sources.list.d/nodesource.list
	apt-get update -yq
}

install_node() {
	local target_user
	target_user=$(detect_user)
	local home_dir
	home_dir=$(user_home "$target_user")

	log "Instalando Node.js LTS via NodeSource (repositório .deb)..."

	remove_previous_node
	install_nodesource

	if ! apt-get install -yq nodejs; then
		err "Falha ao instalar nodejs do NodeSource."
		return 1
	fi

	hash -r 2>/dev/null || true

	log "Node.js instalado via NodeSource."
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
