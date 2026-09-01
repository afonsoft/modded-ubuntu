#!/usr/bin/env bash
# Angular tooling para o modded-ubuntu
# Instala o Angular CLI e as extensões do VS Code para desenvolvimento Angular
# Pode ser executado standalone ou chamado por distro/gui.sh

R="$(printf '\033[1;31m')"
Y="$(printf '\033[1;33m')"
C="$(printf '\033[1;36m')"
W="$(printf '\033[1;37m')"

log()  { echo -e "${C}[angular]${W} $1"; }
warn() { echo -e "${Y}[angular]${W} $1"; }
err()  { echo -e "${R}[angular]${W} $1"; }

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

run_with_node() {
	bash -c "$*"
}

ensure_nodejs() {
	# Se node e npm existem, não reinstala
	if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
		log "Node.js e npm já estão disponíveis."
		return 0
	fi

	warn "Node.js não encontrado. Instalando..."
	if [ -f /usr/local/bin/node-setup ]; then
		bash /usr/local/bin/node-setup
	elif [ -f /data/data/com.termux/files/home/modded-ubuntu/distro/nodejs.sh ]; then
		bash /data/data/com.termux/files/home/modded-ubuntu/distro/nodejs.sh
	else
		local node_script
		node_script=$(mktemp)
		curl -fsSL https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/distro/nodejs.sh -o "$node_script"
		bash "$node_script"
		rm -f "$node_script"
	fi
}

install_angular_cli() {
	log "Instalando Angular CLI..."

	# Tenta a versão mais recente; se falhar, usa o pacote sem sufixo de versão
	if npm install -g @angular/cli@latest; then
		log "Angular CLI mais recente instalado."
	else
		warn "Não foi possível instalar @angular/cli@latest; usando o fallback."
		npm install -g @angular/cli || warn "Não foi possível instalar o Angular CLI"
	fi

	# Garante que o comando ng esteja no PATH global
	local ng_path
	ng_path=$(command -v ng 2>/dev/null) || true
	if [ -x "$ng_path" ] && [ ! -e /usr/local/bin/ng ]; then
		ln -sf "$ng_path" /usr/local/bin/ng 2>/dev/null || true
	elif [ -x /usr/local/lib/nodejs/bin/ng ] && [ ! -e /usr/local/bin/ng ]; then
		ln -sf /usr/local/lib/nodejs/bin/ng /usr/local/bin/ng 2>/dev/null || true
	fi

	if command -v ng >/dev/null 2>&1; then
		log "Angular CLI disponível: $(ng version 2>/dev/null | head -n 1 || true)"
	else
		warn "Angular CLI pode não estar no PATH. Reinicie o shell."
	fi
}

install_vscode_angular_extensions() {
	local extensions=(
		"Angular.ng-template"
		"johnpapa.Angular2"
		"dbaeumer.vscode-eslint"
		"esbenp.prettier-vscode"
		"EditorConfig.EditorConfig"
		"christian-kohler.path-intellisense"
		"formulahendry.auto-rename-tag"
		"PKief.material-icon-theme"
	)
	local helper=""
	local downloaded=0
	if [ -f /usr/local/bin/vscode-ext ]; then
		helper=/usr/local/bin/vscode-ext
	elif [ -f "$(dirname "$0")/vscode-ext.sh" ]; then
		helper="$(dirname "$0")/vscode-ext.sh"
	elif [ -f /data/data/com.termux/files/home/modded-ubuntu/distro/vscode-ext.sh ]; then
		helper=/data/data/com.termux/files/home/modded-ubuntu/distro/vscode-ext.sh
	else
		helper=$(mktemp)
		downloaded=1
		curl -fsSL https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/distro/vscode-ext.sh -o "$helper" || {
			warn "Não foi possível obter o helper de extensões do VS Code."
			rm -f "$helper"
			return 0
		}
		chmod +x "$helper"
	fi
	bash "$helper" "${extensions[@]}" || true
	if [ "$downloaded" -eq 1 ]; then
		rm -f "$helper"
	fi
}

cleanup() {
	log "Limpando caches e arquivos temporários do Angular..."
	rm -f /tmp/angular-script-* 2>/dev/null || true
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
	ensure_nodejs
	install_angular_cli
	install_vscode_angular_extensions
	cleanup
	log "Stack Angular (CLI mais recente) configurado."
}

main "$@"
