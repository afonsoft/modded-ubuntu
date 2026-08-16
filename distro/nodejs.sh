#!/usr/bin/env bash
# Node.js para o modded-ubuntu
# Instala o Node.js LTS diretamente a partir dos tarballs oficiais,
# sem usar o NVM (que travava dentro do PRoot).
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

# Usa dpkg --print-architecture quando disponível (mais confiável dentro do PRoot)
# e cai para uname -m caso contrário.
arch=$(dpkg --print-architecture 2>/dev/null || uname -m)
case "$arch" in
	arm64|aarch64) arch="arm64" ;;
	armhf|armv7l|armv6l) arch="arm" ;;
esac

install_prerequisites() {
	log "Atualizando repositórios e instalando dependências do Node.js..."
	apt-get update -yq
	apt-get install -yq --no-install-recommends \
		coreutils curl ca-certificates xz-utils || true
	log "Dependências do Node.js instaladas."
}

node_arch() {
	case "$arch" in
		arm64) echo "arm64" ;;
		arm) echo "armv7l" ;;
		amd64|x86_64) echo "x64" ;;
		*) echo "$arch" ;;
	esac
}

resolve_latest_lts() {
	local fallback="v22.23.2"

	local resolved=""
	if command -v timeout >/dev/null 2>&1; then
		resolved=$(timeout 15s curl -fsSL --connect-timeout 10 --max-time 15 \
			"https://nodejs.org/dist/index.tab" 2>/dev/null \
			| awk -F'\t' '$10 != "-" {print $1}' \
			| sort -V \
			| tail -1)
	else
		resolved=$(curl -fsSL --connect-timeout 10 --max-time 15 \
			"https://nodejs.org/dist/index.tab" 2>/dev/null \
			| awk -F'\t' '$10 != "-" {print $1}' \
			| sort -V \
			| tail -1)
	fi

	if [ -n "$resolved" ]; then
		echo "$resolved"
	else
		warn "Não foi possível consultar a versão LTS mais recente. Usando fallback $fallback."
		echo "$fallback"
	fi
}

remove_nvm() {
	local target_user
	target_user=$(detect_user)
	local home_dir
	home_dir=$(user_home "$target_user")

	if [ -d "$home_dir/.nvm" ]; then
		warn "Removendo instalação anterior do NVM em $home_dir/.nvm..."
		rm -rf "$home_dir/.nvm"
	fi

	if [ -f "$home_dir/.bashrc" ]; then
		# Remove as linhas relacionadas ao NVM sem sobrescrever o arquivo por completo.
		sed -i '/# Ativar a versão padrão do Node\.js gerenciada pelo nvm/d' "$home_dir/.bashrc" 2>/dev/null || true
		sed -i '/export NVM_DIR=/d' "$home_dir/.bashrc" 2>/dev/null || true
		sed -i '/\[ -s "\$NVM_DIR\/nvm\.sh" \] && \\\. "\$NVM_DIR\/nvm\.sh"/d' "$home_dir/.bashrc" 2>/dev/null || true
		sed -i '/nvm use default/d' "$home_dir/.bashrc" 2>/dev/null || true
	fi
}

install_node() {
	local target_user
	target_user=$(detect_user)
	local home_dir
	home_dir=$(user_home "$target_user")
	local node_arch_name
	node_arch_name=$(node_arch)

	log "Arquitetura detectada: $arch (tarball: $node_arch_name)"

	local node_version
	node_version=$(resolve_latest_lts)
	local slug="node-${node_version}-linux-${node_arch_name}"
	local tarball_url="https://nodejs.org/dist/${node_version}/${slug}.tar.xz"
	local install_dir="/usr/local/lib/nodejs"
	local cache_dir="/tmp/node-install-cache"

	log "Instalando Node.js $node_version diretamente em $install_dir..."

	remove_nvm

	# Remove instalação anterior do Node.js se existir
	if [ -d "$install_dir" ]; then
		warn "Removendo instalação anterior do Node.js em $install_dir..."
		rm -rf "$install_dir"
	fi

	mkdir -p "$install_dir"
	mkdir -p "$cache_dir"

	local tarball="$cache_dir/${slug}.tar.xz"

	log "Baixando $tarball_url..."
	if command -v timeout >/dev/null 2>&1; then
		if ! timeout --kill-after=30 900 curl -fSL --connect-timeout 30 --max-time 600 --retry 2 --retry-delay 5 \
			--progress-bar -o "$tarball" "$tarball_url"; then
			err "Falha ao baixar o tarball do Node.js."
			return 1
		fi
	else
		if ! curl -fSL --connect-timeout 30 --max-time 600 --retry 2 --retry-delay 5 \
			--progress-bar -o "$tarball" "$tarball_url"; then
			err "Falha ao baixar o tarball do Node.js."
			return 1
		fi
	fi

	# Verifica checksum quando possível
	local shasums="$cache_dir/SHASUMS256.txt"
	local shasums_url="https://nodejs.org/dist/${node_version}/SHASUMS256.txt"
	if command -v timeout >/dev/null 2>&1; then
		if timeout --kill-after=5 30 curl -fsSL --connect-timeout 10 --max-time 30 -o "$shasums" "$shasums_url" 2>/dev/null; then
			if grep -F "${slug}.tar.xz" "$shasums" | sha256sum -c - >/dev/null 2>&1; then
				log "Checksum OK."
			else
				err "Checksum do tarball não confere. Abortando instalação."
				rm -f "$tarball" "$shasums"
				return 1
			fi
		else
			warn "Não foi possível baixar SHASUMS256; continuando sem verificação."
		fi
	else
		if curl -fsSL --connect-timeout 10 --max-time 30 -o "$shasums" "$shasums_url" 2>/dev/null; then
			if grep -F "${slug}.tar.xz" "$shasums" | sha256sum -c - >/dev/null 2>&1; then
				log "Checksum OK."
			else
				err "Checksum do tarball não confere. Abortando instalação."
				rm -f "$tarball" "$shasums"
				return 1
			fi
		else
			warn "Não foi possível baixar SHASUMS256; continuando sem verificação."
		fi
	fi

	log "Extraindo $tarball para $install_dir..."
	if ! tar -xJf "$tarball" -C "$install_dir" --strip-components=1; then
		err "Falha ao extrair o tarball do Node.js."
		return 1
	fi

	log "Criando symlinks em /usr/local/bin..."
	for bin in node npm npx corepack; do
		if [ -x "$install_dir/bin/$bin" ]; then
			ln -sf "$install_dir/bin/$bin" "/usr/local/bin/$bin"
		fi
	done

	# Garante que o diretório bin do Node.js esteja no PATH
	if [ ! -f /etc/profile.d/nodejs.sh ]; then
		cat > /etc/profile.d/nodejs.sh <<'EOF'
# Adiciona o Node.js instalado manualmente ao PATH
export PATH="/usr/local/lib/nodejs/bin:$PATH"
EOF
		chmod +x /etc/profile.d/nodejs.sh
	fi

	# Também adiciona ao .bashrc do usuário alvo
	if ! grep -q '/usr/local/lib/nodejs/bin' "$home_dir/.bashrc" 2>/dev/null; then
		sudo -u "$target_user" -H bash -c 'cat >> "$HOME/.bashrc"' <<'EOF'

# Node.js instalado manualmente
export PATH="/usr/local/lib/nodejs/bin:$PATH"
EOF
	fi

	hash -r 2>/dev/null || true
	log "Node.js $node_version instalado em $install_dir."
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
