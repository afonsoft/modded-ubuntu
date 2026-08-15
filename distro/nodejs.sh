#!/usr/bin/env bash
# Node.js / NVM para o modded-ubuntu
# Instala o nvm e as versões LTS 20, 22 e 24 (quando disponível) do Node.js
# Pode ser executado standalone ou chamado por distro/gui.sh

R="$(printf '\033[1;31m')"
Y="$(printf '\033[1;33m')"
C="$(printf '\033[1;36m')"
W="$(printf '\033[1;37m')"
arch=$(uname -m)

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

install_prerequisites() {
	log "Atualizando repositórios e instalando dependências do Node.js..."
	apt-get update -yq
	apt-get install -yq --no-install-recommends \
		curl ca-certificates git || true
}

install_nvm() {
	local target_user
	target_user=$(detect_user)
	local home_dir
	home_dir=$(user_home "$target_user")
	local nvm_dir="$home_dir/.nvm"
	local nvm_version="v0.40.0"

	log "Instalando NVM $nvm_version para o usuário: $target_user"

	if [ -d "$nvm_dir" ]; then
		warn "NVM já instalado em $nvm_dir. Pulando nova instalação."
		return 0
	fi

	curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$nvm_version/install.sh" -o /tmp/nvm-install.sh
	chmod +x /tmp/nvm-install.sh

	# Executa o instalador como o usuário alvo para que .bashrc e $HOME estejam corretos
	if ! sudo -u "$target_user" -H bash /tmp/nvm-install.sh; then
		warn "Falha ao instalar o NVM com sudo; tentando como root..."
		bash /tmp/nvm-install.sh
	fi

}

persist_nvm_default() {
	local target_user
	target_user=$(detect_user)
	local home_dir
	home_dir=$(user_home "$target_user")

	if [ -f "$home_dir/.bashrc" ] && ! grep -q "nvm use default" "$home_dir/.bashrc"; then
		{
			echo ''
			echo '# Ativar a versão padrão do Node.js gerenciada pelo nvm'
			echo 'export NVM_DIR="$HOME/.nvm"'
			echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm use default >/dev/null 2>&1'
		} >> "$home_dir/.bashrc"
	fi
}

install_node_versions() {
	local target_user
	target_user=$(detect_user)
	local home_dir
	home_dir=$(user_home "$target_user")
	local nvm_dir="$home_dir/.nvm"

	if [ ! -s "$nvm_dir/nvm.sh" ]; then
		err "NVM não encontrado em $nvm_dir. Pulando instalação do Node.js."
		return 1
	fi

	log "Instalando Node.js 20, 22 e 24 (se disponível) via NVM..."

	local nvm_env="export NVM_DIR=\"$nvm_dir\"; [ -s \"$nvm_dir/nvm.sh\" ] && \\. \"$nvm_dir/nvm.sh\" && nvm use default >/dev/null 2>&1"

	# Evita compilação from-source em ARM 32-bit, onde binários recentes podem não existir
	local node_versions=(20 22)
	if [[ "$arch" != armv7l && "$arch" != armhf ]]; then
		node_versions+=(24)
	else
		warn "Arquitetura $arch detectada. Pulando Node.js 24 (binários geralmente indisponíveis)."
	fi

	# Tenta instalar cada versão usando binários pré-compilados (-b) para evitar
	# compilação from-source que pode travar em ARM 32-bit. Mostra progresso.
	local version
	for version in "${node_versions[@]}"; do
		if sudo -u "$target_user" -H bash -c "$nvm_env; nvm install -b $version"; then
			log "Node.js $version instalado."
		else
			warn "Não foi possível instalar Node.js $version (binário pode estar indisponível)."
		fi
	done

	# Define Node 22 como padrão (LTS estável e compatível com Angular 20)
	if sudo -u "$target_user" -H bash -c "$nvm_env; nvm alias default 22" 2>/dev/null; then
		log "Versão padrão do Node.js definida como 22."
	else
		# Fallback: usa a última versão instalada
		sudo -u "$target_user" -H bash -c "$nvm_env; nvm alias default node" 2>/dev/null || warn "Não foi possível definir o alias padrão do nvm"
	fi
}

symlink_nvm_binaries() {
	local target_user
	target_user=$(detect_user)
	local home_dir
	home_dir=$(user_home "$target_user")
	local nvm_dir="$home_dir/.nvm"

	# Ativa a versão padrão para descobrir o caminho dos binários
	local nvm_env="export NVM_DIR=\"$nvm_dir\"; [ -s \"$nvm_dir/nvm.sh\" ] && \\. \"$nvm_dir/nvm.sh\" && nvm use default >/dev/null 2>&1"
	local node_bin
	node_bin=$(sudo -u "$target_user" -H bash -c "$nvm_env; dirname \"\$(command -v node)\"")

	if [ -z "$node_bin" ] || [ ! -d "$node_bin" ]; then
		warn "Não foi possível localizar os binários do Node.js para criar symlinks."
		return 0
	fi

	log "Criando symlinks em /usr/local/bin para Node.js ativo ($node_bin)..."
	for bin in node npm npx corepack; do
		if [ -x "$node_bin/$bin" ]; then
			ln -sf "$node_bin/$bin" "/usr/local/bin/$bin" 2>/dev/null || true
		fi
	done
}

print_versions() {
	if command -v node >/dev/null 2>&1; then
		log "Node.js disponível: $(node --version)"
		log "npm disponível: $(npm --version)"
	else
		warn "node não está disponível no PATH imediatamente. Reinicie o shell para carregar o nvm."
	fi
}

cleanup() {
	log "Limpando arquivos temporários e caches..."
	rm -f /tmp/nvm-install.sh
	apt-get clean 2>/dev/null || true
	if command -v npm >/dev/null 2>&1; then
		npm cache clean --force 2>/dev/null || true
	fi
	if command -v pip >/dev/null 2>&1; then
		pip cache purge 2>/dev/null || true
	fi
	# Limpa possíveis caches de download do nvm
	rm -rf "$nvm_dir/.cache" 2>/dev/null || true
}

main() {
	local nvm_dir
	install_prerequisites
	install_nvm
	nvm_dir=$(user_home "$(detect_user)")/.nvm
	install_node_versions
	persist_nvm_default
	symlink_nvm_binaries
	print_versions
	cleanup
	log "Node.js / NVM configurado."
}

main "$@"
