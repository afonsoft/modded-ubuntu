#!/bin/bash

R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
W="$(printf '\033[1;37m')"
C="$(printf '\033[1;36m')"
# Usa dpkg --print-architecture quando disponível (mais confiável dentro do PRoot)
# e cai para uname -m caso contrário.
arch=$(dpkg --print-architecture 2>/dev/null || uname -m)
case "$arch" in
	arm64|aarch64) arch="arm64" ;;
	armhf|armv7l|armv6l) arch="arm" ;;
esac

export DEBIAN_FRONTEND=noninteractive

# Adiciona chaves GPG de forma compatível com Ubuntu antigo e novo.
# O apt-key foi removido em versões recentes; usamos gpg como fallback.
add_apt_key() {
	local key_id="$1"
	if command -v apt-key >/dev/null 2>&1; then
		apt-key adv --keyserver keyserver.ubuntu.com --recv-keys "$key_id" 2>/dev/null || true
		return 0
	fi
	if command -v gpg >/dev/null 2>&1; then
		mkdir -p /etc/apt/trusted.gpg.d
		rm -f /tmp/modded-keyring.gpg
		gpg --no-default-keyring --keyring /tmp/modded-keyring.gpg --keyserver keyserver.ubuntu.com --recv-keys "$key_id" >/dev/null 2>&1 || true
		gpg --no-default-keyring --keyring /tmp/modded-keyring.gpg --export "$key_id" 2>/dev/null | gpg --dearmor > "/etc/apt/trusted.gpg.d/modded-${key_id}.gpg" 2>/dev/null || true
		rm -f /tmp/modded-keyring.gpg
	fi
}

# Evita que pacotes tentem iniciar serviços dentro do PRoot
if [ ! -f /usr/sbin/policy-rc.d ]; then
	printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d
	chmod 755 /usr/sbin/policy-rc.d
fi

# Detect the target non-root user even when running under sudo.
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
		user_name="ubuntu"
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

check_root(){
	if [ "$(id -u)" -ne 0 ]; then
		echo -ne " ${R}Run this program as root!\n\n"${W}
		exit 1
	fi
}

banner() {
	clear
	cat <<- EOF
		${Y}    _  _ ___  _  _ _  _ ___ _  _    _  _ ____ ___  
		${C}    |  | |__] |  | |\ |  |  |  |    |\/| |  | |  \ 
		${G}    |__| |__] |__| | \|  |  |__|    |  | |__| |__/

	EOF
	echo -e "${G}     A modded gui version of ubuntu for Termux\n"
}

note() {
	banner
	echo -e " ${G} [-] Successfully Installed !\n"${W}
	sleep 1
	cat <<- EOF
		 ${G}[-] Type ${C}vncstart${G} to run Vncserver.
		 ${G}[-] Type ${C}vncstop${G} to stop Vncserver.

		 ${C}Install VNC VIEWER Apk on your Device.

		 ${C}Open VNC VIEWER & Click on + Button.

		 ${C}Enter the Address localhost:1 & Name anything you like.

		 ${C}Set the Picture Quality to High for better Quality.

		 ${C}Click on Connect & Input the Password.

		 ${C}Enjoy :D${W}
	EOF
}

package() {
	banner
	echo -e "${R} [${W}-${R}]${C} Checking required packages..."${W}
	apt-get update -y
	apt install udisks2 -y
	if [ -f /var/lib/dpkg/info/udisks2.postinst ]; then
		rm /var/lib/dpkg/info/udisks2.postinst
		echo "" > /var/lib/dpkg/info/udisks2.postinst
		dpkg --configure -a
		apt-mark hold udisks2
	fi

	packs=(sudo gnupg2 curl nano git xz-utils python3 at-spi2-core xfce4 xfce4-goodies xfce4-terminal mousepad librsvg2-common menu inetutils-tools dialog exo-utils tigervnc-standalone-server tigervnc-common tigervnc-tools dbus-x11 fonts-beng fonts-beng-extra gtk2-engines-murrine gtk2-engines-pixbuf apt-transport-https x11-xserver-utils fonts-dejavu-core fonts-liberation fonts-noto-color-emoji greybird-gtk-theme papirus-icon-theme)
	for hulu in "${packs[@]}"; do
		type -p "$hulu" &>/dev/null || {
			echo -e "\n${R} [${W}-${R}]${G} Installing package : ${Y}$hulu${W}"
			apt-get install "$hulu" -y --no-install-recommends
		}
	done

	apt-get update -y
	apt-get upgrade -y
}

install_ghost_framework() {
    echo -e "${G}Installing ${Y}Ghost Framework${W}"
    curl -fsSL https://raw.githubusercontent.com/Midohajhouj/Ghost-Framework/refs/heads/main/setup.sh -o /tmp/install_ghost.sh
    chmod +x /tmp/install_ghost.sh
    bash /tmp/install_ghost.sh
    echo -e "${G} Ghost Framework Installed Successfully\n${W}"
}

install_wireshark() {
    [[ $(command -v wireshark) ]] && echo "${Y}Wireshark is already Installed!${W}\n" || {
        echo -e "${G}Installing ${Y}Wireshark${W}"
        if ! command -v debconf-set-selections >/dev/null 2>&1; then
            apt-get install -yq debconf-utils >/dev/null 2>&1 || true
        fi
        echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections 2>/dev/null || true
        apt-get install -yq wireshark
        echo -e "${G} Wireshark Installed Successfully\n${W}"
    }
}

install_gimp() {
    [[ $(command -v gimp) ]] && echo "${Y}GIMP is already Installed!${W}\n" || {
        echo -e "${G}Installing ${Y}GIMP${W}"
        apt-get install -yq gimp
        echo -e "${G} GIMP Installed Successfully\n${W}"
    }
}

install_htop() {
    [[ $(command -v htop) ]] && echo "${Y}htop is already Installed!${W}\n" || {
        echo -e "${G}Installing ${Y}htop${W}"
        apt-get install -yq htop
        echo -e "${G} htop Installed Successfully\n${W}"
    }
}

install_obsidian() {
	if command -v obsidian >/dev/null 2>&1; then
		echo -e "${Y}Obsidian is already Installed!${W}"
		return 0
	fi
	if [[ "$arch" == arm ]]; then
		echo -e "${Y} [!] Obsidian is not supported on 32-bit ARM (armhf/armv7) in this setup. Skipping.${W}"
		return 0
	fi
	echo -e "${G}Installing ${Y}Obsidian${W}"
	apt-get update -y
	apt-get install -y --no-install-recommends curl

	local deb_arch obsidian_url obsidian_deb
	deb_arch=$(dpkg --print-architecture)
	obsidian_url=$(curl -fsSL --retry 3 --retry-delay 2 "https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest" | grep "browser_download_url" | grep "${deb_arch}.deb" | head -n1 | sed -E 's/.*"([^"]+)".*/\1/')

	if [ -z "$obsidian_url" ]; then
		echo -e "${Y} Obsidian .deb not found for architecture ${deb_arch}. Skipping.${W}"
		return 1
	fi

	obsidian_deb=$(mktemp --suffix=.deb)
	if curl -fsSL --retry 3 --retry-delay 2 -o "$obsidian_deb" "$obsidian_url"; then
		dpkg -i "$obsidian_deb" 2>/dev/null || apt-get install -f -y
	else
		echo -e "${Y} Failed to download Obsidian. Skipping.${W}"
	fi
	rm -f "$obsidian_deb"

	# Sobrescreve o .desktop padrão para garantir --no-sandbox no PRoot.
	if [ -f /data/data/com.termux/files/home/modded-ubuntu/distro/xfce-config/desktop/obsidian.desktop ]; then
		cp -f /data/data/com.termux/files/home/modded-ubuntu/distro/xfce-config/desktop/obsidian.desktop /usr/local/share/applications/obsidian.desktop 2>/dev/null || true
		cp -f /data/data/com.termux/files/home/modded-ubuntu/distro/xfce-config/desktop/obsidian.desktop /usr/share/applications/obsidian.desktop 2>/dev/null || true
	fi

	if command -v update-desktop-database >/dev/null 2>&1; then
		update-desktop-database /usr/share/applications 2>/dev/null || true
		update-desktop-database /usr/local/share/applications 2>/dev/null || true
	fi

	echo -e "${C} Obsidian Installed Successfully\n${W}"
}

install_kali_tools() {
    echo -e "${G}Installing ${Y}Kali Linux Tools${W}"
    if [[ -e '/data/data/com.termux/files/home/modded-ubuntu/distro/tools.sh' ]]; then
        echo -e "${G}Using local tools.sh for installation...${W}"
        chmod +x /data/data/com.termux/files/home/modded-ubuntu/distro/tools.sh
        bash /data/data/com.termux/files/home/modded-ubuntu/distro/tools.sh -y --minimal
    else
        echo -e "${G}Downloading tools.sh from remote...${W}"
        wget -q --show-progress "https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/distro/tools.sh" -O /tmp/tools.sh
        chmod +x /tmp/tools.sh
        bash /tmp/tools.sh -y --minimal
    fi
    echo -e "${G} Kali Linux Tools Installed Successfully\n${W}"
}

install_apt() {
	for apt in "$@"; do
		[[ $(command -v "$apt") ]] && echo "${Y}${apt} is already Installed!${W}" || {
			echo -e "${G}Installing ${Y}${apt}${W}"
			apt install -y "${apt}"
		}
	done
}

install_vscode() {
	if [[ "$arch" == arm ]]; then
		echo -e "${Y} [!] VSCode is not supported on 32-bit ARM (armhf/armv7) in this setup. Skipping.${W}"
		return 0
	fi
	[[ $(command -v code) ]] && echo "${Y}VSCode is already Installed!${W}" || {
		echo -e "${G}Installing ${Y}VSCode${W}"
		apt update -y
		apt install -y gpg curl
		curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/packages.microsoft.gpg
		local deb_arch
		deb_arch=$(dpkg --print-architecture)
		echo "deb [arch=${deb_arch} signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
		apt update -y
		apt install code -y
		curl -fsSL https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/patches/code.desktop > /usr/share/applications/code.desktop
		echo -e "${C} Visual Studio Code Installed Successfully\n${W}"
	}
}

install_opencode() {
	if command -v opencode >/dev/null 2>&1; then
		echo "${Y}OpenCode is already Installed!${W}"
		return 0
	fi
	echo -e "${G}Installing ${Y}Node.js and OpenCode CLI${W}"
	install_node
	hash -r 2>/dev/null || true
	if ! npm install -g opencode-ai; then
		echo -e "${Y} Falha ao instalar o OpenCode CLI via npm; usando o instalador oficial.${W}"
		curl -fsSL https://opencode.ai/install | bash
	fi
	hash -r 2>/dev/null || true

	# O pacote pode expor o binário como opencode, lildax ou opencode2.
	# Procuramos o binário no diretório ativo do Node.js.
	local node_bin
	node_bin=$(dirname "$(readlink -f "$(command -v node)" 2>/dev/null)" 2>/dev/null) || true
	if [ -z "$node_bin" ] || [ ! -d "$node_bin" ]; then
		node_bin=""
	fi

	local opencode_bin=""
	for bin_name in opencode opencode2 lildax; do
		if command -v "$bin_name" >/dev/null 2>&1; then
			opencode_bin=$(command -v "$bin_name")
			break
		elif [ -n "$node_bin" ] && [ -x "$node_bin/$bin_name" ]; then
			opencode_bin="$node_bin/$bin_name"
			break
		fi
	done

	if [ -n "$opencode_bin" ] && [ ! -e /usr/local/bin/opencode ]; then
		ln -sf "$opencode_bin" /usr/local/bin/opencode 2>/dev/null || true
		hash -r 2>/dev/null || true
	fi

	if command -v opencode >/dev/null 2>&1; then
		echo -e "${C} OpenCode Installed Successfully\n${W}"
	else
		echo -e "${Y} OpenCode CLI binary not found after install. Binary detected: ${opencode_bin:-none}\n${W}"
	fi
}

install_sublime() {
	if [[ "$arch" == arm ]]; then
		echo -e "${Y} [!] Sublime Text is only available for arm64/aarch64 and x64 in this setup. Skipping.${W}"
		return 0
	fi
	[[ $(command -v subl) ]] && echo "${Y}Sublime is already Installed!${W}" || {
		apt install gnupg2 software-properties-common --no-install-recommends -y
		echo "deb https://download.sublimetext.com/ apt/stable/" | tee /etc/apt/sources.list.d/sublime-text.list
		curl -fsSL https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor > /etc/apt/trusted.gpg.d/sublime.gpg 2> /dev/null
		apt update -y
		apt install sublime-text -y
		echo -e "${C} Sublime Text Editor Installed Successfully\n${W}"
	}
}

install_chromium() {
	echo -e "${G}Installing ${Y}Chromium via XtraDeb${W}"
	if [ -x /usr/local/bin/chromium.sh ]; then
		bash /usr/local/bin/chromium.sh
	else
		bash <(curl -fsSL "https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/distro/chromium.sh")
	fi
}

install_firefox() {
	echo -e "${G}Installing ${Y}Firefox${W}"
	if [ -x /usr/local/bin/firefox.sh ]; then
		bash /usr/local/bin/firefox.sh
	else
		bash <(curl -fsSL "https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/distro/firefox.sh")
	fi
	echo -e "${G} Firefox Installed Successfully\n${W}"
}

install_git_gh() {
	if [[ $(command -v git) && $(command -v gh) ]]; then
		echo -e "${Y}Git and GitHub CLI (gh) are already Installed!${W}"
		return 0
	fi
	echo -e "${G}Installing ${Y}Git and GitHub CLI (gh)${W}"
	apt update -y
	apt install -y git curl
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
	chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list
	apt update -y
	apt install gh -y
	echo -e "${C} Git and GitHub CLI (gh) Installed Successfully\n${W}"
}

install_devtools() {
	echo -e "${G}Installing ${Y}Essential Development Tools${W}"
	apt update -y
	apt install -y build-essential python3-pip python3-venv python3-dev nodejs npm cmake make gcc g++ git curl wget nano vim
	echo -e "${C} Essential Development Tools Installed Successfully\n${W}"
}

install_csharp_tools() {
	echo -e "${G}Installing ${Y}.NET / C# Development Stack${W}"
	if [ -f /usr/local/bin/csharp-setup ]; then
		bash /usr/local/bin/csharp-setup
	elif [ -f /data/data/com.termux/files/home/modded-ubuntu/distro/csharp.sh ]; then
		bash /data/data/com.termux/files/home/modded-ubuntu/distro/csharp.sh
	else
		local csharp_script
		csharp_script=$(mktemp)
		curl -fsSL https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/distro/csharp.sh -o "$csharp_script"
		bash "$csharp_script"
		rm -f "$csharp_script"
	fi
	echo -e "${C} .NET / C# Development Stack finished\n${W}"
}

install_node() {
	echo -e "${G}Installing ${Y}Node.js LTS (apt)${W}"
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
	echo -e "${C} Node.js LTS (direct) finished\n${W}"
}

install_angular_tooling() {
	echo -e "${G}Installing ${Y}Angular (CLI mais recente) + extensões do VS Code${W}"
	if [ -f /usr/local/bin/angular-setup ]; then
		bash /usr/local/bin/angular-setup
	elif [ -f /data/data/com.termux/files/home/modded-ubuntu/distro/angular.sh ]; then
		bash /data/data/com.termux/files/home/modded-ubuntu/distro/angular.sh
	else
		local angular_script
		angular_script=$(mktemp)
		curl -fsSL https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/distro/angular.sh -o "$angular_script"
		bash "$angular_script"
		rm -f "$angular_script"
	fi
	echo -e "${C} Ferramentas Angular (CLI mais recente) concluídas\n${W}"
}

install_fullstack() {
	echo -e "${G}Installing ${Y}Full-Stack C# + Angular${W}"
	install_csharp_tools
	install_node
	install_angular_tooling
	echo -e "${C} Full-Stack C# + Angular finished\n${W}"
}

install_claude_code() {
	if command -v claude >/dev/null 2>&1; then
		echo -e "${Y}Claude Code CLI is already Installed!${W}"
		return 0
	fi
	echo -e "${G}Installing ${Y}Claude Code CLI${W}"
	install_node
	hash -r 2>/dev/null || true
	npm install -g --prefix /usr/local @anthropic-ai/claude-code
	hash -r 2>/dev/null || true
	if command -v claude >/dev/null 2>&1; then
		echo -e "${C} Claude Code CLI Installed Successfully\n${W}"
	else
		echo -e "${Y} Claude Code CLI binary not found after install.\n${W}"
	fi
}

install_antigravity() {
	if command -v agy >/dev/null 2>&1 && [ "${1:-}" != "--update" ]; then
		echo -e "${Y}Antigravity CLI is already Installed!${W}"
		return 0
	fi
	echo -e "${G}Installing ${Y}Antigravity CLI${W}"
	if ! command -v curl >/dev/null 2>&1; then
		apt update -y
		apt install -y curl
	fi
	curl -fsSL https://antigravity.google/cli/install.sh | bash -s -- --dir /usr/local/bin
	hash -r 2>/dev/null || true
	if [ -x /usr/local/bin/agy ]; then
		echo -e "${C} Antigravity CLI Installed Successfully\n${W}"
	else
		echo -e "${Y} Antigravity CLI binary not found after install.\n${W}"
	fi
}

install_libreoffice() {
	echo -e "${G}Installing ${Y}LibreOffice Basic${W}"
	apt-get update -y
	apt-get install -y --no-install-recommends libreoffice-writer libreoffice-calc libreoffice-impress libreoffice-gtk3
	echo -e "${C} LibreOffice Basic Installed Successfully\n${W}"
}

install_devin_cli() {
	if command -v devin >/dev/null 2>&1 && [ "${1:-}" != "--update" ]; then
		echo -e "${Y}Devin CLI is already Installed!${W}"
		return 0
	fi
	echo -e "${G}Installing ${Y}Devin CLI${W}"
	local target_user
	target_user=$(detect_user)

	# Baixa o instalador, remove a última linha (devin setup) e executa,
	# evitando a tela de login do Devin CLI nesta etapa.
	local install_script
	install_script=$(mktemp)
	if ! curl -fsSL https://cli.devin.ai/install.sh -o "$install_script"; then
		err "Não foi possível baixar o instalador do Devin CLI."
		rm -f "$install_script"
		return 1
	fi
	sed -i '$d' "$install_script"
	if [ -n "$target_user" ] && [ "$target_user" != "root" ]; then
		chown "$target_user:" "$install_script" 2>/dev/null || true
		sudo -u "$target_user" -H bash "$install_script"
	else
		bash "$install_script"
	fi
	rm -f "$install_script"

	hash -r 2>/dev/null || true
	local devin_local_bin
	devin_local_bin="$(user_home "$target_user")/.local/bin/devin"
	if [ -x "$devin_local_bin" ] && [ ! -e /usr/local/bin/devin ]; then
		ln -sf "$devin_local_bin" /usr/local/bin/devin
		hash -r 2>/dev/null || true
	fi
	if command -v devin >/dev/null 2>&1; then
		echo -e "${C} Devin CLI Installed Successfully\n${W}"
	else
		echo -e "${Y} Devin CLI binary not found after install.\n${W}"
	fi
}

install_devin_desktop() {
	if [ -f /usr/share/applications/devin-desktop.desktop ]; then
		sed -i '/^Exec=/ { /--no-sandbox/! s|$| --no-sandbox|; }' /usr/share/applications/devin-desktop.desktop
	fi
	if command -v devin-desktop >/dev/null 2>&1; then
		echo -e "${Y}Devin Desktop is already Installed!${W}"
		return 0
	fi
	echo -e "${G}Installing ${Y}Devin Desktop${W}"
	apt-get update -y
	apt-get install -y wget gpg

	local deb_arch
	deb_arch=$(dpkg --print-architecture)
	mkdir -p /etc/apt/keyrings
	wget -qO- "https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/windsurf.gpg" | gpg --dearmor > /etc/apt/keyrings/windsurf-stable.gpg
	chmod 644 /etc/apt/keyrings/windsurf-stable.gpg
	echo "deb [arch=${deb_arch} signed-by=/etc/apt/keyrings/windsurf-stable.gpg] https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/apt stable main" > /etc/apt/sources.list.d/windsurf.list

	apt-get install -y apt-transport-https
	apt-get update -y
	if apt-get install -y devin-desktop; then
		if [ -f /usr/share/applications/devin-desktop.desktop ]; then
			sed -i '/^Exec=/ { /--no-sandbox/! s|$| --no-sandbox|; }' /usr/share/applications/devin-desktop.desktop
		fi
		echo -e "${C} Devin Desktop Installed Successfully\n${W}"
	else
		echo -e "${Y} Devin Desktop install failed (package may be unavailable for this architecture or repository unreachable).\n${W}"
	fi
}

install_opencode_desktop() {
	local force="${1:-}"
	local deb_arch
	case "$arch" in
		amd64) deb_arch=amd64 ;;
		arm64) deb_arch=arm64 ;;
		arm)
			echo -e "${Y} OpenCode Desktop não está disponível para ARM 32-bit. Pulando.${W}"
			return 0
			;;
		*)
			echo -e "${Y} OpenCode Desktop não é compatível com a arquitetura ${arch}. Pulando.${W}"
			return 0
			;;
	esac
	if [ -e /opt/OpenCode/ai.opencode.desktop ] && [ "$force" != "--update" ]; then
		echo -e "${Y}OpenCode Desktop já está instalado.${W}"
		return 0
	fi

	echo -e "${G}Instalando ${Y}OpenCode Desktop${W}"
	local deb_file
	deb_file=$(mktemp --suffix=.deb)
	local url="https://github.com/anomalyco/opencode/releases/latest/download/opencode-desktop-linux-${deb_arch}.deb"
	local install_ok=0
	if curl -fL --retry 3 "$url" -o "$deb_file"; then
		if apt-get install -y "$deb_file"; then
			install_ok=1
		else
			dpkg -i "$deb_file" >/dev/null 2>&1 || true
			apt-get -f install -y >/dev/null 2>&1 || true
			if dpkg-query -W -f='${Status}' opencode 2>/dev/null | grep -q 'install ok installed'; then
				install_ok=1
			fi
		fi
	else
		echo -e "${Y} Não foi possível baixar o OpenCode Desktop.${W}"
	fi
	rm -f "$deb_file"

	if [ "$install_ok" -eq 1 ]; then
		if [ -f /usr/share/applications/opencode-desktop.desktop ]; then
			sed -i '/^Exec=/ { /--no-sandbox/! s|$| --no-sandbox|; }' /usr/share/applications/opencode-desktop.desktop
		fi
		echo -e "${C} OpenCode Desktop instalado com sucesso.${W}"
	else
		echo -e "${Y} Falha ao instalar o OpenCode Desktop; continuando.${W}"
	fi
}

install_claude_desktop() {
	case "$arch" in
		arm)
			echo -e "${Y} Claude Desktop não está disponível para ARM 32-bit. Pulando.${W}"
			return 0
			;;
	esac
	if command -v claude-desktop >/dev/null 2>&1; then
		echo -e "${Y}Claude Desktop já está instalado.${W}"
		if [ -f /usr/share/applications/claude-desktop.desktop ]; then
			sed -i '/^Exec=/ { /--no-sandbox/! s|$| --no-sandbox|; }' /usr/share/applications/claude-desktop.desktop
		fi
		return 0
	fi

	echo -e "${G}Instalando ${Y}Claude Desktop${W}"
	apt-get update -y
	apt-get install -y curl ca-certificates
	mkdir -p /usr/share/keyrings
	if ! curl -fsSLo /usr/share/keyrings/claude-desktop-archive-keyring.asc \
		https://downloads.claude.ai/claude-desktop/key.asc; then
		echo -e "${Y} Não foi possível baixar a chave do Claude Desktop.${W}"
		return 0
	fi
	echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/claude-desktop-archive-keyring.asc] https://downloads.claude.ai/claude-desktop/apt/stable stable main" \
		> /etc/apt/sources.list.d/claude-desktop.list
	apt-get update -y
	if apt-get install -y --no-install-recommends claude-desktop; then
		if [ -f /usr/share/applications/claude-desktop.desktop ]; then
			sed -i '/^Exec=/ { /--no-sandbox/! s|$| --no-sandbox|; }' /usr/share/applications/claude-desktop.desktop
		fi
		echo -e "${C} Claude Desktop instalado com sucesso.${W}"
	else
		echo -e "${Y} Falha ao instalar o Claude Desktop; continuando.${W}"
	fi
}

resolve_vscode_ext_helper() {
	if [ -x /usr/local/bin/vscode-ext ]; then
		printf '%s\n' /usr/local/bin/vscode-ext
	elif [ -x "$(dirname "$0")/vscode-ext.sh" ]; then
		printf '%s\n' "$(dirname "$0")/vscode-ext.sh"
	elif [ -x /data/data/com.termux/files/home/modded-ubuntu/distro/vscode-ext.sh ]; then
		printf '%s\n' /data/data/com.termux/files/home/modded-ubuntu/distro/vscode-ext.sh
	else
		return 1
	fi
}

refresh_vscode_extensions() {
	if ! command -v code >/dev/null 2>&1; then
		return 0
	fi
	local helper
	local downloaded=0
	helper=$(resolve_vscode_ext_helper 2>/dev/null) || {
		helper=$(mktemp)
		downloaded=1
		curl -fsSL https://raw.githubusercontent.com/afonsoft/modded-ubuntu/master/distro/vscode-ext.sh -o "$helper" || {
			rm -f "$helper"
			return 0
		}
		chmod +x "$helper"
	}
	bash "$helper" \
		Angular.ng-template johnpapa.Angular2 dbaeumer.vscode-eslint \
		esbenp.prettier-vscode EditorConfig.EditorConfig christian-kohler.path-intellisense \
		formulahendry.auto-rename-tag PKief.material-icon-theme \
		ms-dotnettools.vscode-dotnet-runtime ms-dotnettools.csharp ms-dotnettools.csdevkit || true
	if [ "$downloaded" -eq 1 ]; then
		rm -f "$helper"
	fi
}

update_ai_tools() {
	echo -e "${C} [*] Atualizando somente as ferramentas de IA já instaladas...${W}"
	if command -v opencode >/dev/null 2>&1; then
		npm install -g opencode-ai@latest || true
	fi
	if command -v claude >/dev/null 2>&1; then
		npm install -g --prefix /usr/local @anthropic-ai/claude-code@latest || true
	fi
	if command -v agy >/dev/null 2>&1; then
		install_antigravity --update || true
	fi
	if command -v devin >/dev/null 2>&1; then
		install_devin_cli --update || true
	fi

	local apt_tools=()
	dpkg-query -W -f='${Status}' claude-desktop 2>/dev/null | grep -q 'install ok installed' && apt_tools+=(claude-desktop)
	dpkg-query -W -f='${Status}' devin-desktop 2>/dev/null | grep -q 'install ok installed' && apt_tools+=(devin-desktop)
	if [ "${#apt_tools[@]}" -gt 0 ]; then
		apt-get install -y --only-upgrade "${apt_tools[@]}" || true
	fi
	if [ -d /opt/OpenCode ]; then
		install_opencode_desktop --update || true
	fi
}

update_chromium() {
	# Só atualiza se o usuário já tiver escolhido o Chromium alguma vez.
	if ! command -v chromium >/dev/null 2>&1 \
		&& ! command -v chromium-browser >/dev/null 2>&1 \
		&& [ ! -x /usr/local/bin/chromium ]; then
		return 0
	fi
	echo -e "${C} [*] Atualizando Chromium (repositório XtraDeb + shim --no-sandbox)...${W}"
	local chromium_pkg=""
	dpkg-query -W -f='${Status}' chromium 2>/dev/null | grep -q 'install ok installed' && chromium_pkg=chromium
	[ -z "$chromium_pkg" ] && dpkg-query -W -f='${Status}' chromium-browser 2>/dev/null | grep -q 'install ok installed' && chromium_pkg=chromium-browser
	if [ -n "$chromium_pkg" ]; then
		apt-get install -y --only-upgrade "$chromium_pkg" || true
	fi
	install_chromium || true
}

install_tools() {
	banner
	cat <<- EOF
		${Y} ---${G} Select Browser ${Y}---

		${C} [${W}1${C}] Firefox (Default)
		${C} [${W}2${C}] Chromium
		${C} [${W}3${C}] Both (Firefox + Chromium)

	EOF
	read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" BROWSER_OPTION
	banner

	if [[ "$arch" != arm ]]; then
		cat <<- EOF
			${Y} ---${G} Select IDE & Code Editor ${Y}---

			${C} [${W}1${C}] Sublime Text Editor
			${C} [${W}2${C}] Visual Studio Code
			${C} [${W}3${C}] OpenCode CLI
			${C} [${W}4${C}] All (Sublime, VSCode, OpenCode)
			${C} [${W}5${C}] Skip! (Default)

		EOF
	else
		cat <<- EOF
			${Y} ---${G} Select IDE & Code Editor ${Y}---

			${C} [${W}1${C}] OpenCode CLI
			${C} [${W}2${C}] Skip! (Default)
			${Y} [!] VSCode/Sublime are not available on 32-bit ARM.${W}

		EOF
	fi
	read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" IDE_OPTION
	banner

	cat <<- EOF
		${Y} ---${G} Select Media Player ${Y}---

		${C} [${W}1${C}] MPV Media Player (Recommended)
		${C} [${W}2${C}] VLC Media Player
		${C} [${W}3${C}] Both (MPV + VLC)
		${C} [${W}4${C}] Skip! (Default)

	EOF
	read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" PLAYER_OPTION
	banner

	cat <<- EOF
		${Y} ---${G} Select Development Tools ${Y}---

		${C} [${W}1${C}] Git + GitHub CLI (gh)
		${C} [${W}2${C}] Essential Dev Stack (build-essential, python3-pip, nodejs, npm, cmake)
		${C} [${W}3${C}] .NET SDK 10.0 + C# tooling
		${C} [${W}4${C}] Node.js LTS (direct)
		${C} [${W}5${C}] Angular (CLI mais recente) + extensões do VS Code
		${C} [${W}6${C}] Full-Stack C# + Angular
		${C} [${W}7${C}] All of the above
		${C} [${W}8${C}] Skip! (Default)

	EOF
	read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" DEV_OPTION
	banner

	cat <<- EOF
		${Y} ---${G} Select AI Coding Assistants ${Y}---

		${C} [${W}1${C}] Claude Code CLI
		${C} [${W}2${C}] Claude Desktop
		${C} [${W}3${C}] OpenCode CLI
		${C} [${W}4${C}] OpenCode Desktop
		${C} [${W}5${C}] Antigravity CLI (agy)
		${C} [${W}6${C}] Devin CLI
		${C} [${W}7${C}] Devin Desktop
		${C} [${W}8${C}] All of the above
		${C} [${W}9${C}] Skip! (Default)

	EOF
	read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" AI_OPTION
	banner

	cat <<- EOF
		${Y} ---${G} Select Additional Tools ${Y}---

		${C} [${W}1${C}] Kali Linux Tools	
		${C} [${W}2${C}] Ghost Framework
		${C} [${W}3${C}] Wireshark
		${C} [${W}4${C}] GIMP
		${C} [${W}5${C}] htop
		${C} [${W}6${C}] Obsidian
		${C} [${W}7${C}] All of the above
		${C} [${W}8${C}] Skip! (Default)

	EOF
	read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" TOOLS_OPTION
	banner

	cat <<- EOF
		${Y} ---${G} LibreOffice Basic ${Y}---

		${C} [${W}1${C}] Instalar Writer + Calc + Impress
		${C} [${W}2${C}] Pular (Default)

	EOF
	read -n1 -p "${R} [${G}~${R}]${Y} Select an Option: ${G}" LO_OPTION
	banner

	# Install Browsers
	if [[ ${BROWSER_OPTION} == 2 ]]; then
		install_chromium
	elif [[ ${BROWSER_OPTION} == 3 ]]; then
		install_firefox
		install_chromium
	else
		install_firefox
	fi

	# Install IDEs
	if [[ "$arch" != arm ]]; then
		case $IDE_OPTION in
			1) install_sublime ;;
			2) install_vscode ;;
			3) install_opencode ;;
			4)
				install_sublime
				install_vscode
				install_opencode
				;;
			*) echo -e "${Y} [!] Skipping IDE Installation\n" ;;
		esac
	else
		case $IDE_OPTION in
			1) install_opencode ;;
			*) echo -e "${Y} [!] Skipping IDE Installation\n" ;;
		esac
	fi

	# Install Media Players
	if [[ ${PLAYER_OPTION} == 1 ]]; then
		install_apt "mpv"
	elif [[ ${PLAYER_OPTION} == 2 ]]; then
		install_apt "vlc"
	elif [[ ${PLAYER_OPTION} == 3 ]]; then
		install_apt "mpv" "vlc"
	else
		echo -e "${Y} [!] Skipping Media Player Installation\n"
		sleep 1
	fi

	# Install Development Tools
	case $DEV_OPTION in
		1) install_git_gh ;;
		2) install_devtools ;;
		3) install_csharp_tools ;;
		4) install_node ;;
		5) install_angular_tooling ;;
		6) install_fullstack ;;
		7)
			install_git_gh
			install_devtools
			install_csharp_tools
			install_node
			install_angular_tooling
			;;
		*) echo -e "${Y} [!] Skipping Development Tools Installation\n" ;;
	esac

	# Install AI Coding Assistants
	case $AI_OPTION in
		1) install_claude_code ;;
		2) install_claude_desktop ;;
		3) install_opencode ;;
		4) install_opencode_desktop ;;
		5) install_antigravity ;;
		6) install_devin_cli ;;
		7) install_devin_desktop ;;
		8)
			install_claude_code
			install_claude_desktop
			install_opencode
			install_opencode_desktop
			install_antigravity
			install_devin_cli
			install_devin_desktop
			;;
		*) echo -e "${Y} [!] Skipping AI Assistants Installation\n" ;;
	esac

	# Install Additional Tools
	case $TOOLS_OPTION in
		1) install_kali_tools ;;
		2) install_ghost_framework ;;
		3) install_wireshark ;;
		4) install_gimp ;;
		5) install_htop ;;
		6) install_obsidian ;;
		7)
			install_kali_tools
			install_ghost_framework
			install_wireshark
			install_gimp
			install_htop
			install_obsidian
			;;
		*) echo -e "${Y} [!] Skipping Additional Tools Installation\n" ;;
	esac

	# Install LibreOffice Basic (opcional)
	if [ "${LO_OPTION:-2}" = "1" ]; then
		install_libreoffice
	fi
}

downloader(){
	local path="$1"
	local url="$2"
	[[ -e "$path" ]] && rm -rf "$path"
	echo "Downloading $(basename "$path")..."
	curl --progress-bar --fail \
		 --retry-connrefused --retry 3 --retry-delay 2 \
		  --location --output "${path}" "${url}"
}

sound_fix() {
	local ubuntu_bin="/data/data/com.termux/files/usr/bin/ubuntu"
	if [ -f "$ubuntu_bin" ] && ! grep -q "bash ~/.sound" "$ubuntu_bin"; then
		local tmp
		tmp=$(mktemp)
		{
			echo "bash ~/.sound"
			cat "$ubuntu_bin"
		} > "$tmp"
		mv "$tmp" "$ubuntu_bin"
		chmod +x "$ubuntu_bin"
	fi
	if ! grep -q 'export DISPLAY=":1"' /etc/profile; then
		echo 'export DISPLAY=":1"' >> /etc/profile
	fi
	if ! grep -q "export PULSE_SERVER=127.0.0.1" /etc/profile; then
		echo "export PULSE_SERVER=127.0.0.1" >> /etc/profile
	fi
	source /etc/profile
}

rem_theme() {
	theme=(Bright Daloa Emacs Moheli Retro Smoke)
	for rmi in "${theme[@]}"; do
		type -p "$rmi" &>/dev/null || {
			rm -rf /usr/share/themes/"$rmi"
		}
	done
}

rem_icon() {
	fonts=(hicolor LoginIcons ubuntu-mono-light)
	for rmf in "${fonts[@]}"; do
		type -p "$rmf" &>/dev/null || {
			rm -rf /usr/share/icons/"$rmf"
		}
	done
}

config() {
	banner
	sound_fix

	add_apt_key 3B4FE6ACC0B21F32
	yes | apt upgrade || true
	yes | apt install gtk2-engines-murrine gtk2-engines-pixbuf sassc optipng inkscape libglib2.0-dev-bin || true

	echo -e "${R} [${W}-${R}]${C} Aplicando tema, ícones, papel de parede e layout XFCE..\n"${W}
	if command -v xfce-apply >/dev/null 2>&1; then
		# Aplica o tema, painel, ícones, papel de parede e atalhos para todos os usuários.
		xfce-apply --all
	else
		echo -e "${Y} xfce-apply não encontrado. Pulando customizações XFCE.\n${W}"
	fi

	echo -e "${R} [${W}-${R}]${C} Rebuilding Font Cache..\n"${W}
	fc-cache -fv

	echo -e "${R} [${W}-${R}]${C} Upgrading the System..\n"${W}
	apt update
	yes | apt upgrade
	apt clean
	yes | apt autoremove
}

cleanup() {
	echo -e "${C} [*] Limpando arquivos temporários e caches finais...${W}"

	# Limpa dependências órfãs e depois o cache de pacotes
	apt-get autoremove -y 2>/dev/null || true
	apt-get clean 2>/dev/null || true

	# Limpa cache do npm/pip quando disponíveis
	if command -v npm >/dev/null 2>&1; then
		npm cache clean --force 2>/dev/null || true
	fi
	if command -v pip >/dev/null 2>&1; then
		pip cache purge 2>/dev/null || true
	fi

	# Remove scripts/tarballs temporários conhecidos
	rm -f /tmp/nvm-install.sh \
		/tmp/dotnet-install.sh \
		/tmp/install_ghost.sh \
		/tmp/tools.sh \
		/tmp/node_script \
		/tmp/angular_script \
		/tmp/csharp_script 2>/dev/null || true

	# Limpa logs antigos de instalação (mantém os mais recentes)
	find /var/log -type f -name "*.log.*" -mtime +7 -delete 2>/dev/null || true

	echo -e "${G} [*] Limpeza concluída.${W}"
}

update_mode() {
	check_root
	banner
	echo -e "${C} [*] Atualização: pacotes base, ferramentas de IA, extensões do VS Code e configurações XFCE...${W}"
	package
	install_obsidian
	update_ai_tools
	update_chromium
	refresh_vscode_extensions
	config
	if [ "${MODDED_INSTALL_DESKTOPS:-0}" = "1" ]; then
		install_claude_desktop
		install_opencode_desktop
		install_devin_desktop
	fi
	echo -e "${G} [*] Atualização concluída. Reinicie o Termux/Ubuntu se desejar.${W}"
	cleanup
}

# ----------------------------

case "${1:-}" in
	--update|update)
		update_mode
		;;
	""|-h|--help)
		check_root
		package
		install_tools
		config
		note
		cleanup
		;;
	*)
		echo "Uso: $(basename "$0") [--update]"
		exit 1
		;;
esac
