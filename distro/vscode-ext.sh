#!/usr/bin/env bash
set -u

Y="$(printf '\033[1;33m')"
W="$(printf '\033[1;37m')"

warn() {
	printf '%b\n' "${Y}[vscode-ext] $*${W}"
}

log() {
	printf '%s\n' "[vscode-ext] $*"
}

usage() {
	printf 'Uso: vscode-ext [--user USUARIO] EXTENSAO [EXTENSAO...]\n'
}

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

code_bin=""
for candidate in "$(command -v code 2>/dev/null || true)" \
	/usr/bin/code /usr/local/bin/code /usr/share/code/bin/code; do
	if [ -n "$candidate" ] && [ -x "$candidate" ]; then
		code_bin="$candidate"
		break
	fi
done

if [ -z "$code_bin" ]; then
	warn "VS Code não instalado; pulando extensões"
	exit 0
fi

target_user=""
extensions=()
while [ "$#" -gt 0 ]; do
	case "$1" in
		--user)
			if [ "$#" -lt 2 ]; then
				usage
				exit 0
			fi
			target_user="$2"
			shift 2
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			extensions+=("$1")
			shift
			;;
	esac
done

if [ -z "$target_user" ]; then
	if [ "$(id -un)" = "root" ]; then
		target_user=$(detect_user)
	else
		target_user=$(id -un)
	fi
fi

target_home=$(getent passwd "$target_user" 2>/dev/null | cut -d: -f6)
if [ -z "$target_home" ]; then
	target_home="$HOME"
fi
mkdir -p "$target_home" "$target_home/.vscode" 2>/dev/null || true
if [ "$(id -u)" -eq 0 ]; then
	chown "$target_user:" "$target_home" "$target_home/.vscode" 2>/dev/null || true
fi

executor=()
code_args=()
if [ "$(id -un)" = "$target_user" ]; then
	:
elif [ "$(id -u)" -eq 0 ] && command -v runuser >/dev/null 2>&1; then
	executor=(runuser -u "$target_user" --)
elif [ "$(id -u)" -eq 0 ] && command -v sudo >/dev/null 2>&1; then
	executor=(sudo -u "$target_user" -H)
else
	code_args+=(--user-data-dir "$HOME/.vscode-root" --extensions-dir "$HOME/.vscode-root/extensions")
	mkdir -p "$HOME/.vscode-root/extensions" 2>/dev/null || true
fi

log_file="${TMPDIR:-/tmp}/vscode-ext.log"
installed_extensions=$("${executor[@]}" "$code_bin" "${code_args[@]}" \
	--no-sandbox --disable-gpu --list-extensions 2>/dev/null || true)
installed_count=0
present_count=0
failed_count=0

for extension in "${extensions[@]}"; do
	if printf '%s\n' "$installed_extensions" | grep -Fxi -- "$extension" >/dev/null 2>&1; then
		log "Extensão $extension já instalada."
		present_count=$((present_count + 1))
		continue
	fi

	success=0
	attempt=1
	while [ "$attempt" -le 2 ]; do
		printf '%s\n' "[vscode-ext] Instalando $extension (tentativa $attempt)" >> "$log_file"
		if "${executor[@]}" "$code_bin" "${code_args[@]}" --no-sandbox --disable-gpu \
			--force --install-extension "$extension" >> "$log_file" 2>&1; then
			success=1
			break
		fi
		attempt=$((attempt + 1))
	done

	if [ "$success" -eq 1 ]; then
		log "Extensão $extension instalada."
		installed_count=$((installed_count + 1))
	else
		warn "Falha ao instalar $extension:"
		tail -n 5 "$log_file" 2>/dev/null || true
		failed_count=$((failed_count + 1))
	fi
done

log "Resumo: $installed_count instaladas, $present_count já presentes, $failed_count falharam"
exit 0
