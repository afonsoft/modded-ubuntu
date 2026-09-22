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

# Garante que a barra superior emita struts para que janelas maximizadas não
# fiquem com a titlebar sob o painel. Struts só são emitidos com o snap numa
# borda válida para painel horizontal: p=11 é SNAP_POSITION_N (p=1 é a borda
# direita, que nunca emite struts). enable-struts é o nome em xfce4-panel
# >=4.19; disable-struts=false cobre as versões anteriores.
ensure_panel_struts() {
	[ -n "${DISPLAY:-}" ] || return 0
	command -v xfconf-query >/dev/null 2>&1 || return 0
	xfconf-query -c xfce4-panel -p /panels/panel-1/position --create -t string -s "p=11;x=0;y=0" 2>/dev/null || true
	xfconf-query -c xfce4-panel -p /panels/panel-1/enable-struts --create -t bool -s true 2>/dev/null || true
	xfconf-query -c xfce4-panel -p /panels/panel-1/disable-struts --create -t bool -s false 2>/dev/null || true
}

reload_panel() {
	command -v xfce4-panel >/dev/null 2>&1 || return 0
	[ -n "${DISPLAY:-}" ] || return 0
	ensure_panel_struts
	if pgrep -x xfce4-panel >/dev/null 2>&1; then
		# O restart embutido re-executa a própria instância — sem vazar janelas
		# nem deixar <defunct>. Mas quando a chamada falha (ex.: barramento de
		# sessão inalcançável) ele abre um diálogo GTK e bloqueia; por isso a
		# espera é limitada e, em timeout, cai para quit forçado + respawn
		# (somente quando o barramento permite reerguer o painel).
		timeout 5 xfce4-panel -r >/dev/null 2>&1
		if [ "$?" -eq 124 ] && xfconf-query -l >/dev/null 2>&1; then
			# Sem barramento de sessão utilizável o respawn morre no xfconf_init
			# e a área fica sem painéis — melhor deixar o painel atual vivo;
			# a config nova já está no arquivo e vale no próximo login.
			pkill -x xfce4-panel 2>/dev/null || true
			for _ in $(seq 20); do
				pgrep -x xfce4-panel >/dev/null 2>&1 || break
				sleep 0.5
			done
			pkill -9 -x xfce4-panel 2>/dev/null || true
			sleep 1
			(setsid xfce4-panel >/dev/null 2>&1 &)
		fi
	else
		xfconf-query -l >/dev/null 2>&1 && (setsid xfce4-panel >/dev/null 2>&1 &)
	fi
}

# xfconfd regrava o canal ativo sobre os XMLs ao encerrar a sessão; para que a
# configuração publicada realmente valha, ele precisa ser encerrado antes da cópia.
stop_xfconfd() {
	local user="$1"
	command -v pkill >/dev/null 2>&1 || return 0
	pkill -x -u "$user" xfconfd 2>/dev/null || true
	sleep 1
}

reload_desktop() {
	command -v xfdesktop >/dev/null 2>&1 || return 0
	[ -n "${DISPLAY:-}" ] || return 0
	xfdesktop --reload 2>/dev/null || true
}

install_packages() {
	if ! command -v apt-get >/dev/null 2>&1; then
		return 0
	fi

	echo "[*] Instalando/verificando temas, ícones e fontes..."
	apt-get update -y >/dev/null 2>&1 || true

	# Temas e ícones principais
	apt-get install -y --no-install-recommends xfce4-whiskermenu-plugin greybird-gtk-theme papirus-icon-theme breeze-cursor-theme fonts-noto-color-emoji 2>/dev/null || true

	# Fonte Hack: o nome do pacote mudou em versões mais recentes do Ubuntu
	apt-get install -y --no-install-recommends fonts-hack-ttf 2>/dev/null || apt-get install -y --no-install-recommends fonts-hack 2>/dev/null || true
}

install_global_files() {
	# Papel de parede global
	local wp_dir="/usr/share/backgrounds/xfce"
	mkdir -p "$wp_dir"
	local wallpaper
	for wallpaper in "$XFCE_CONFIG_SRC/wallpaper/"*.jpg; do
		[ -f "$wallpaper" ] || continue
		cp -f "$wallpaper" "$wp_dir/"
		chmod 644 "$wp_dir/$(basename "$wallpaper")"
	done

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
	local wallpaper
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
		cp -f "$xfce_dir/xfconf/xfce-perchannel-xml/xfwm4.xml" "$backup_dir/" 2>/dev/null || true
		ls -1dt "$xfce_dir"/backup-* 2>/dev/null | tail -n +4 | while read -r old_backup; do
			[ -d "$old_backup" ] && rm -rf "$old_backup"
		done
	fi

	stop_xfconfd "$user"

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
	for wallpaper in "$XFCE_CONFIG_SRC/wallpaper/"*.jpg; do
		[ -f "$wallpaper" ] || continue
		cp -f "$wallpaper" "$xfce_dir/wallpaper/" 2>/dev/null || true
		chmod 644 "$xfce_dir/wallpaper/$(basename "$wallpaper")" 2>/dev/null || true
	done
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
	cat > "$autostart_dir/modded-ubuntu-display.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Ajustes de tela modded-ubuntu
Exec=/bin/bash -c 'sleep 2; xset s off; xset s noblank; xset -dpms'
X-GNOME-Autostart-enabled=true
EOF
	chown "$user:" "$autostart_dir/modded-ubuntu-display.desktop" 2>/dev/null || true

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
		apply_user root
	fi

	awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd 2>/dev/null | while IFS= read -r user; do
		apply_user "$user"
	done

	# Recarrega o painel se houver uma sessão XFCE ativa
	reload_panel
	reload_desktop
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
			if [ "$(id -un)" = "$2" ]; then
				reload_panel
				reload_desktop
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
