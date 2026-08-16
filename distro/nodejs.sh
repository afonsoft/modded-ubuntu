#!/usr/bin/env bash
# Node.js / NVM para o modded-ubuntu
# Instala o nvm e as versões LTS 20, 22 e 24 (quando disponível) do Node.js
# Pode ser executado standalone ou chamado por distro/gui.sh

R="$(printf '\033[1;31m')"
Y="$(printf '\033[1;33m')"
C="$(printf '\033[1;36m')"
W="$(printf '\033[1;37m')"
# Usa dpkg --print-architecture quando disponível (mais confiável dentro do PRoot)
# e cai para uname -m caso contrário.
arch=$(dpkg --print-architecture 2>/dev/null || uname -m)
case "$arch" in
	arm64|aarch64) arch="arm64" ;;
	armhf|armv7l|armv6l) arch="arm" ;;
esac

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
		coreutils curl ca-certificates git xz-utils || true
	log "Dependências do Node.js instaladas."
}

install_nvm() {
	local target_user
	target_user=$(detect_user)
	local home_dir
	home_dir=$(user_home "$target_user")
	local nvm_dir="$home_dir/.nvm"
	local nvm_version="v0.40.0"

	log "Instalando NVM $nvm_version para o usuário: $target_user (home=$home_dir)"

	if [ -s "$nvm_dir/nvm.sh" ]; then
		warn "NVM já instalado em $nvm_dir. Pulando nova instalação."
		return 0
	fi

	# Se o diretório existe mas está incompleto, remove para recomeçar
	if [ -d "$nvm_dir" ]; then
		warn "Diretório $nvm_dir existe mas parece incompleto; removendo..."
		rm -rf "$nvm_dir" || {
			err "Não foi possível remover $nvm_dir."
			return 1
		}
	fi

	# Clona diretamente o repositório como o usuário alvo, evitando o script
	# oficial que pode travar em PRoot ao executar 'npm list -g' ou compilação.
	log "Clonando NVM de https://github.com/nvm-sh/nvm.git (branch $nvm_version)..."
	if ! sudo -u "$target_user" -H git clone --depth=1 --branch "$nvm_version" \
		https://github.com/nvm-sh/nvm.git "$nvm_dir" 2>&1; then
		err "Falha ao clonar o NVM via git. Verifique a conexão."
		return 1
	fi

	log "NVM clonado em $nvm_dir."

	# Configura o .bashrc do usuário para carregar o nvm
	persist_nvm_default
}

persist_nvm_default() {
	local target_user
	target_user=$(detect_user)
	local home_dir
	home_dir=$(user_home "$target_user")

	log "Configurando carregamento do NVM em $home_dir/.bashrc..."

	# Escreve como o usuário alvo para manter a propriedade correta do arquivo
	if ! sudo -u "$target_user" -H grep -q "nvm use default" "$home_dir/.bashrc" >/dev/null 2>&1; then
		sudo -u "$target_user" -H bash -c 'cat >> "$HOME/.bashrc"' <<'EOF'

# Ativar a versão padrão do Node.js gerenciada pelo nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && nvm use default >/dev/null 2>&1
EOF
		log "Carregamento do NVM adicionado ao .bashrc."
	else
		log ".bashrc já possui configuração do NVM."
	fi
}

resolve_node_version() {
	local major="$1"
	local fallback
	case "$major" in
		20) fallback="v20.20.2" ;;
		22) fallback="v22.23.2" ;;
		24) fallback="v24.19.0" ;;
		*) fallback="v${major}.0.0" ;;
	esac

	local resolved
	resolved=$(curl -fsSL --connect-timeout 30 --max-time 60 \
		"https://nodejs.org/dist/index.tab" 2>/dev/null \
		| awk -F'\t' -v maj="$major" '$1 ~ "^v"maj"\\." {print $1}' \
		| sort -V \
		| tail -1)

	if [ -n "$resolved" ]; then
		echo "$resolved"
	else
		warn "Não foi possível consultar a versão mais recente do Node $major. Usando fallback $fallback."
		echo "$fallback"
	fi
}

install_node_versions() {
	local target_user
	target_user=$(detect_user)
	local home_dir
	home_dir=$(user_home "$target_user")
	local nvm_dir="$home_dir/.nvm"

	log "Verificando instalação do NVM em $nvm_dir..."
	if [ ! -s "$nvm_dir/nvm.sh" ]; then
		err "NVM não encontrado em $nvm_dir. Pulando instalação do Node.js."
		return 1
	fi

	log "Arquitetura detectada: $arch"
	log "Instalando Node.js (versões: 20, 22 e 24 quando disponível) via download direto..."

	local nvm_env="export NVM_DIR=\"$nvm_dir\"; [ -s \"$nvm_dir/nvm.sh\" ] && \\. \"$nvm_dir/nvm.sh\""

	local node_arch
	case "$arch" in
		arm64) node_arch="arm64" ;;
		arm) node_arch="armv7l" ;;
		amd64|x86_64) node_arch="x64" ;;
		*) node_arch="$arch" ;;
	esac

	local node_majors=(20 22)
	if [[ "$arch" != arm ]]; then
		node_majors+=(24)
	else
		warn "Arquitetura $arch detectada. Pulando Node.js 24 (binários geralmente indisponíveis para ARM 32-bit)."
	fi

	local timeout_prefix=()
	if command -v timeout >/dev/null 2>&1; then
		# 15 minutos para download; força SIGKILL 60s após o prazo
		timeout_prefix=(timeout --kill-after=60 900)
		log "Timeout de 900s (com SIGKILL após 60s) será usado para cada download."
	else
		warn "Comando 'timeout' não encontrado; download pode demorar sem limite."
	fi

	local default_version=""

	local major
	for major in "${node_majors[@]}"; do
		local full_version
		full_version=$(resolve_node_version "$major")
		log "[Node $major] Versão resolvida: $full_version"

		local slug="node-${full_version}-linux-${node_arch}"
		local tarball_url="https://nodejs.org/dist/${full_version}/${slug}.tar.xz"
		local cache_dir="$nvm_dir/.cache/bin/$slug"
		local tarball="$cache_dir/${slug}.tar.xz"
		local version_dir="$nvm_dir/versions/node/$full_version"

		if [ -x "$version_dir/bin/node" ]; then
			log "[Node $major] Já instalado em $version_dir. Pulando."
			if [ "$major" = "22" ]; then
				default_version="$full_version"
			fi
			continue
		fi

		log "[Node $major] Baixando $tarball_url..."
		mkdir -p "$cache_dir"
		local download_cmd=(curl -fSL --connect-timeout 30 --max-time 600 --retry 2 --retry-delay 5 --progress-bar -o "$tarball" "$tarball_url")
		if ! "${timeout_prefix[@]}" "${download_cmd[@]}"; then
			warn "[Node $major] Falha no download do tarball. Pulando."
			rm -f "$tarball"
			continue
		fi

		# Verifica checksum quando possível
		local shasums="$cache_dir/SHASUMS256.txt"
		local shasums_url="https://nodejs.org/dist/${full_version}/SHASUMS256.txt"
		if curl -fsSL --connect-timeout 30 --max-time 120 -o "$shasums" "$shasums_url" 2>/dev/null; then
			if grep -F "${slug}.tar.xz" "$shasums" | sha256sum -c - >/dev/null 2>&1; then
				log "[Node $major] Checksum OK."
			else
				warn "[Node $major] Checksum não confere. Pulando extração."
				rm -f "$tarball" "$shasums"
				continue
			fi
		else
			warn "[Node $major] Não foi possível baixar SHASUMS256; continuando sem verificação."
		fi

		log "[Node $major] Extraindo para $version_dir..."
		rm -rf "$version_dir"
		sudo -u "$target_user" -H mkdir -p "$version_dir"
		if sudo -u "$target_user" -H tar -xJf "$tarball" -C "$version_dir" --strip-components=1; then
			log "[Node $major] Instalado em $version_dir."
			if [ "$major" = "22" ]; then
				default_version="$full_version"
			fi
		else
			warn "[Node $major] Falha ao extrair o tarball."
			rm -rf "$version_dir"
		fi
	done

	# Define Node 22 como padrão (LTS estável e compatível com Angular 20)
	if [ -n "$default_version" ]; then
		log "Definindo alias padrão do NVM para $default_version..."
		sudo -u "$target_user" -H bash -c "$nvm_env; nvm alias default \"$default_version\"" >/dev/null 2>&1 || warn "Não foi possível definir o alias padrão do nvm"
	else
		warn "Não foi possível determinar a versão padrão do Node.js."
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
	log "Localizando binários do Node.js para symlinks..."
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
			log "Symlink criado: /usr/local/bin/$bin -> $node_bin/$bin"
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
	apt-get autoremove -y --purge 2>/dev/null || true
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
