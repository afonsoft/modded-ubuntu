#!/usr/bin/env bash
set -u

# Aplica as customizações XFCE (painel, tema, ícones, papel de parede e menu)
# no usuário especificado ou em todos os usuários do sistema.

usage() {
	echo "Uso: $0 --user USUARIO"
	echo "     $0 --all"
}

resolve_config_src() {
	if [ -d "/usr/local/share/modded-ubuntu/xfce-config" ]; then
		XFCE_CONFIG_SRC="/usr/local/share/modded-ubuntu/xfce-config"
	else
		local script_dir
		script_dir=$(cd "$(dirname "$0")" && pwd)
		if [ -d "$script_dir/xfce-config" ]; then
			XFCE_CONFIG_SRC="$script_dir/xfce-config"
		else
			echo "Erro: diretório xfce-config não encontrado." >&2
			exit 1
		fi
	fi
}

is_root() {
	[ "$(id -u)" -eq 0 ]
}

install_packages() {
	if ! command -v apt-get >/dev/null 2>&1; then
		return 0
	fi

	local pkgs=(
		greybird-gtk-theme
		papirus-icon-theme
		breeze-cursor-theme
		fonts-hack-ttf
		fonts-noto-color-emoji
	)

	echo "[*] Instalando/verificando temas, ícones e fontes..."
	apt-get update -y >/dev/null 2>&1 || true
	apt-get install -y --no-install-recommends "${pkgs[@]}" 2>/dev/null || true
}

install_global_files() {
	# Papel de parede global
	local wp_dir="/usr/share/backgrounds/xfce"
	mkdir -p "$wp_dir"
	if [ -f "$XFCE_CONFIG_SRC/wallpaper/modded-ubuntu-tech.jpg" ]; then
		cp -f "$XFCE_CONFIG_SRC/wallpaper/modded-ubuntu-tech.jpg" "$wp_dir/"
		chmod 644 "$wp_dir/modded-ubuntu-tech.jpg"
	fi

	# Atalhos .desktop globais
	local app_dir="/usr/local/share/applications"
	mkdir -p "$app_dir"
	if [ -d "$XFCE_CONFIG_SRC/desktop" ]; then
		cp -f "$XFCE_CONFIG_SRC/desktop/"*.desktop "$app_dir/" 2>/dev/null || true
		chmod 644 "$app_dir/"*.desktop 2>/dev/null || true
	fi

	if command -v update-desktop-database >/dev/null 2>&1; then
		update-desktop-database "$app_dir" 2>/dev/null || true
	fi
}

apply_user() {
	local user="$1"
	local home_dir
	home_dir=$(getent passwd "$user" 2>/dev/null | cut -d: -f6)

	if [ -z "$home_dir" ] || [ ! -d "$home_dir" ]; then
		return 0
	fi

	local xfce_dir="$home_dir/.config/xfce4"
	mkdir -p "$xfce_dir/xfconf/xfce-perchannel-xml"
	mkdir -p "$xfce_dir/panel"

	# Backup das configurações atuais
	if [ -d "$xfce_dir/xfconf/xfce-perchannel-xml" ]; then
		local backup_dir
		backup_dir="$xfce_dir/backup-$(date +%Y%m%d%H%M%S)"
		mkdir -p "$backup_dir"
		cp -f "$xfce_dir/xfconf/xfce-perchannel-xml/xfce4-panel.xml" "$backup_dir/" 2>/dev/null || true
		cp -f "$xfce_dir/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" "$backup_dir/" 2>/dev/null || true
		cp -f "$xfce_dir/xfconf/xfce-perchannel-xml/xsettings.xml" "$backup_dir/" 2>/dev/null || true
	fi

	# Aplica os arquivos de configuração
	if [ -d "$XFCE_CONFIG_SRC/xfconf" ]; then
		cp -f "$XFCE_CONFIG_SRC/xfconf/"*.xml "$xfce_dir/xfconf/xfce-perchannel-xml/"
	fi

	if [ -d "$XFCE_CONFIG_SRC/panel" ] && [ -n "$(ls -A "$XFCE_CONFIG_SRC/panel" 2>/dev/null)" ]; then
		cp -r "$XFCE_CONFIG_SRC/panel/"* "$xfce_dir/panel/" 2>/dev/null || true
	fi

	if [ -f "$XFCE_CONFIG_SRC/helpers.rc" ]; then
		cp -f "$XFCE_CONFIG_SRC/helpers.rc" "$xfce_dir/helpers.rc"
	fi

	# Se não for root, mantém uma cópia local do papel de parede e atualiza o caminho
	if ! is_root; then
		mkdir -p "$xfce_dir/wallpaper"
		cp -f "$XFCE_CONFIG_SRC/wallpaper/modded-ubuntu-tech.jpg" "$xfce_dir/wallpaper/" 2>/dev/null || true
		sed -i "s|/usr/share/backgrounds/xfce/modded-ubuntu-tech.jpg|$xfce_dir/wallpaper/modded-ubuntu-tech.jpg|g" \
			"$xfce_dir/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" 2>/dev/null || true
	fi

	# Garante permissões corretas
	chown -R "$user:" "$xfce_dir" 2>/dev/null || true
	chmod -R u+rwX "$xfce_dir" 2>/dev/null || true

	# Atalhos .desktop por usuário (fallback quando não é root)
	if ! is_root; then
		mkdir -p "$home_dir/.local/share/applications"
		if [ -d "$XFCE_CONFIG_SRC/desktop" ]; then
			cp -f "$XFCE_CONFIG_SRC/desktop/"*.desktop "$home_dir/.local/share/applications/" 2>/dev/null || true
		fi
		if command -v update-desktop-database >/dev/null 2>&1; then
			update-desktop-database "$home_dir/.local/share/applications" 2>/dev/null || true
		fi
	fi

	echo "[*] Configuração XFCE aplicada para $user"
}

apply_all() {
	if is_root; then
		install_packages
		install_global_files
	fi

	awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd 2>/dev/null | while IFS= read -r user; do
		apply_user "$user"
	done

	# Recarrega o painel se houver uma sessão XFCE ativa
	if command -v xfce4-panel >/dev/null 2>&1; then
		xfce4-panel -r 2>/dev/null || true
	fi
}

main() {
	resolve_config_src

	case "${1:-}" in
		--user)
			if [ -z "${2:-}" ]; then
				usage
				exit 1
			fi
			if is_root; then
				install_packages
				install_global_files
			fi
			apply_user "$2"
			if command -v xfce4-panel >/dev/null 2>&1 && [ "$(id -un)" = "$2" ]; then
				xfce4-panel -r 2>/dev/null || true
			fi
			;;
		--all)
			apply_all
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			usage
			exit 1
			;;
	esac
}

main "$@"
