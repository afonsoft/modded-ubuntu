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

	echo "[*] Instalando/verificando temas, ícones e fontes..."
	apt-get update -y >/dev/null 2>&1 || true

	# Temas e ícones principais
	apt-get install -y --no-install-recommends greybird-gtk-theme papirus-icon-theme breeze-cursor-theme fonts-noto-color-emoji 2>/dev/null || true

	# Fonte Hack: o nome do pacote mudou em versões mais recentes do Ubuntu
	apt-get install -y --no-install-recommends fonts-hack-ttf 2>/dev/null || apt-get install -y --no-install-recommends fonts-hack 2>/dev/null || true
}

install_global_files() {
	# Papel de parede global
	local wp_dir="/usr/share/backgrounds/xfce"
	mkdir -p "$wp_dir"
	if [ -f "$XFCE_CONFIG_SRC/wallpaper/modded-ubuntu-tech.jpg" ]; then
		cp -f "$XFCE_CONFIG_SRC/wallpaper/modded-ubuntu-tech.jpg" "$wp_dir/"
		chmod 644 "$wp_dir/modded-ubuntu-tech.jpg"
	fi

	local script_dir
	script_dir=$(cd "$(dirname "$0")" && pwd)
	if [ -f "$script_dir/set-wallpaper.sh" ]; then
		cp -f "$script_dir/set-wallpaper.sh" /usr/local/bin/set-wallpaper
		chmod +x /usr/local/bin/set-wallpaper
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

	# Mantém uma cópia local do papel de parede e atualiza o caminho para usuários comuns
	mkdir -p "$xfce_dir/wallpaper"
	cp -f "$XFCE_CONFIG_SRC/wallpaper/modded-ubuntu-tech.jpg" "$xfce_dir/wallpaper/" 2>/dev/null || true
	if ! is_root; then
		sed -i "s|/usr/share/backgrounds/xfce/modded-ubuntu-tech.jpg|$xfce_dir/wallpaper/modded-ubuntu-tech.jpg|g" \
			"$xfce_dir/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" 2>/dev/null || true
	fi

	# Garante permissões corretas
	chown -R "$user:" "$xfce_dir" "$home_dir/.local" 2>/dev/null || true
	chmod -R u+rwX "$xfce_dir" 2>/dev/null || true

	# Atalhos .desktop por usuário
	local user_app_dir="$home_dir/.local/share/applications"
	mkdir -p "$user_app_dir"
	if [ -d "$XFCE_CONFIG_SRC/desktop" ]; then
		cp -f "$XFCE_CONFIG_SRC/desktop/"*.desktop "$user_app_dir/" 2>/dev/null || true
		chmod 644 "$user_app_dir/"*.desktop 2>/dev/null || true
	fi
	if command -v update-desktop-database >/dev/null 2>&1; then
		update-desktop-database "$user_app_dir" 2>/dev/null || true
	fi

	install_desktop_icons "$user" "$home_dir"
	local autostart_dir="$home_dir/.config/autostart"
	mkdir -p "$autostart_dir"
	cat > "$autostart_dir/modded-ubuntu-wallpaper.desktop" <<'EOF'
[Desktop Entry]
Exec=/bin/bash -c 'sleep 3; /usr/local/bin/set-wallpaper'
Type=Application
X-GNOME-Autostart-enabled=true
Name=Papel de parede modded-ubuntu
EOF
	chown "$user:" "$autostart_dir/modded-ubuntu-wallpaper.desktop" 2>/dev/null || true

	echo "[*] Configuração XFCE aplicada para $user"
	if [ "$user" = "$(id -un)" ] && [ -n "${DISPLAY:-}" ]; then
		/usr/local/bin/set-wallpaper 2>/dev/null || true
	fi
}

install_desktop_icons() {
	local user="$1"
	local home_dir="$2"
	local desktop_dir="$home_dir/Desktop"
	local xdg_dirs="$home_dir/.config/user-dirs.dirs"
	if [ -f "$xdg_dirs" ]; then
		local configured_dir
		configured_dir=$(sed -n 's/^XDG_DESKTOP_DIR="\([^"]*\)"/\1/p' "$xdg_dirs" | head -n 1)
		if [ -n "$configured_dir" ]; then
			desktop_dir="${configured_dir/\$HOME/$home_dir}"
		fi
	fi
	mkdir -p "$desktop_dir"

	local entries=(
		xfce4-terminal.desktop
		thunar.desktop
		code.desktop
		claude-desktop.desktop
		opencode-desktop.desktop
		firefox.desktop
		chromium.desktop
	)
	local entry source try_exec exec_line binary
	for entry in "${entries[@]}"; do
		source=""
		for candidate in "$XFCE_CONFIG_SRC/desktop/$entry" \
			"/usr/local/share/applications/$entry" \
			"/usr/share/applications/$entry"; do
			if [ -f "$candidate" ]; then
				source="$candidate"
				break
			fi
		done
		[ -n "$source" ] || continue

		try_exec=$(sed -n 's/^TryExec=//p' "$source" | head -n 1)
		exec_line=$(sed -n 's/^Exec=//p' "$source" | head -n 1)
		binary="${try_exec:-$exec_line}"
		binary="${binary%% *}"
		binary="${binary#\"}"
		binary="${binary%\"}"
		if [[ "$binary" = /* ]]; then
			[ -x "$binary" ] || continue
		elif ! command -v "$binary" >/dev/null 2>&1; then
			continue
		fi

		cp -f "$source" "$desktop_dir/$entry"
		chmod +x "$desktop_dir/$entry"
		chown "$user:" "$desktop_dir/$entry" 2>/dev/null || true
	done
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
