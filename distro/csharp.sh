#!/usr/bin/env bash
# Stack de desenvolvimento C# / .NET para o modded-ubuntu
# Pode ser executado standalone ou chamado por distro/gui.sh

R="$(printf '\033[1;31m')"
Y="$(printf '\033[1;33m')"
C="$(printf '\033[1;36m')"
W="$(printf '\033[1;37m')"

export DEBIAN_FRONTEND=noninteractive

# Evita que pacotes tentem iniciar serviços dentro do PRoot
if [ ! -f /usr/sbin/policy-rc.d ]; then
	printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d
	chmod 755 /usr/sbin/policy-rc.d
fi

log()  { echo -e "${C}[csharp]${W} $1"; }
warn() { echo -e "${Y}[csharp]${W} $1"; }
err()  { echo -e "${R}[csharp]${W} $1"; }

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
	echo "$user_name"
}

install_prerequisites() {
	log "Atualizando repositórios e instalando dependências nativas do .NET..."
	apt-get update -yq
	apt-get install -yq --no-install-recommends \
		curl wget ca-certificates \
		libc6-dev libicu-dev libssl3 libgdiplus \
		unzip || true
}

install_dotnet_sdk() {
	log "Instalando .NET SDK..."

	local sdk_installed=false
	local pkg="dotnet-sdk-10.0"
	if apt-cache show "$pkg" >/dev/null 2>&1; then
		log "Pacote $pkg encontrado. Instalando..."
		if apt-get install -yq "$pkg"; then
			sdk_installed=true
		fi
	fi

	if [ "$sdk_installed" != true ]; then
		warn ".NET SDK 10.0 não encontrado nos repositórios. Usando dotnet-install.sh como fallback..."
		curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
		chmod +x /tmp/dotnet-install.sh
		/tmp/dotnet-install.sh --channel 10.0 --install-dir /usr/share/dotnet
		ln -sf /usr/share/dotnet/dotnet /usr/bin/dotnet
	fi

	if ! command -v dotnet >/dev/null 2>&1; then
		err "Falha ao instalar o .NET SDK."
		return 1
	fi

	log ".NET SDK instalado: $(dotnet --version)"
}

install_dotnet_global_tools() {
	if ! command -v dotnet >/dev/null 2>&1; then
		warn "dotnet não encontrado. Pulando ferramentas globais."
		return 0
	fi

	log "Instalando ferramentas globais do .NET em /usr/local/bin..."

	# dotnet-ef é essencial para projetos com Entity Framework Core
	dotnet tool install --tool-path /usr/local/bin dotnet-ef || warn "Não foi possível instalar dotnet-ef"

	# Scaffolding ASP.NET Core
	dotnet tool install --tool-path /usr/local/bin dotnet-aspnet-codegenerator || warn "Não foi possível instalar dotnet-aspnet-codegenerator"

	log "Ferramentas globais instaladas:"
	dotnet tool list --tool-path /usr/local/bin
}

install_vscode_csharp_extensions() {
	local extensions=(
		"ms-dotnettools.vscode-dotnet-runtime"
		"ms-dotnettools.csharp"
		"ms-dotnettools.csdevkit"
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
	log "Limpando caches e arquivos temporários do .NET..."
	rm -f /tmp/dotnet-install.sh /tmp/csharp-script-* 2>/dev/null || true
	apt-get autoremove -y --purge 2>/dev/null || true
	apt-get clean 2>/dev/null || true
	if command -v dotnet >/dev/null 2>&1; then
		dotnet nuget locals all --clear 2>/dev/null || true
	fi
	if command -v pip >/dev/null 2>&1; then
		pip cache purge 2>/dev/null || true
	fi
}

main() {
	install_prerequisites
	install_dotnet_sdk
	install_dotnet_global_tools
	install_vscode_csharp_extensions
	cleanup
	log "Stack de desenvolvimento C# / .NET configurada."
}

main "$@"
