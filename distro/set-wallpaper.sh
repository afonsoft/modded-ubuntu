#!/usr/bin/env bash
set -u

Y="$(printf '\033[1;33m')"
W="$(printf '\033[1;37m')"

warn() {
	printf '%b\n' "${Y}[set-wallpaper] $*${W}"
}

usage() {
	cat <<-EOF
	Uso: set-wallpaper [OPCAO|NOME|CAMINHO]

	Opcoes:
	  --list             lista os papeis de parede disponiveis
	  --random           escolhe um papel de parede aleatoriamente
	  -h, --help         mostra esta ajuda
	EOF
}

wallpaper_dirs=(
	"${HOME}/.config/xfce4/wallpaper"
	"/usr/share/backgrounds/xfce"
)

wallpaper_names=()
wallpaper_paths=()

wallpaper_name() {
	local filename="${1##*/}"
	filename="${filename%.jpg}"
	case "$filename" in
		modded-ubuntu-*)
			filename="${filename#modded-ubuntu-}"
			;;
	esac
	printf '%s\n' "$filename"
}

collect_wallpapers() {
	local dir file name existing existing_name
	for dir in "${wallpaper_dirs[@]}"; do
		[ -d "$dir" ] || continue
		for file in "$dir"/*.jpg; do
			[ -f "$file" ] || continue
			name=$(wallpaper_name "$file")
			existing=0
			for existing_name in "${wallpaper_names[@]}"; do
				if [ "$existing_name" = "$name" ]; then
					existing=1
					break
				fi
			done
			[ "$existing" -eq 0 ] || continue
			wallpaper_names+=("$name")
			wallpaper_paths+=("$file")
		done
	done
}

resolve_wallpaper_name() {
	local name="$1"
	local dir candidate
	for dir in "${wallpaper_dirs[@]}"; do
		for candidate in "$name" "$name.jpg" "modded-ubuntu-$name.jpg"; do
			if [ -f "$dir/$candidate" ]; then
				printf '%s\n' "$dir/$candidate"
				return 0
			fi
		done
	done
	return 1
}

image=""
argument="${1:-}"
case "$argument" in
	-h|--help)
		usage
		exit 0
		;;
	--list)
		collect_wallpapers
		if [ "${#wallpaper_names[@]}" -gt 0 ]; then
			printf '%s\n' "${wallpaper_names[@]}"
		fi
		exit 0
		;;
	--random)
		collect_wallpapers
		if [ "${#wallpaper_paths[@]}" -gt 0 ]; then
			image="${wallpaper_paths[$((RANDOM % ${#wallpaper_paths[@]}))]}"
		else
			warn "Nenhum papel de parede encontrado; pulando."
			exit 0
		fi
		;;
	"")
		if [ -f "$HOME/.config/xfce4/wallpaper/modded-ubuntu-tech.jpg" ]; then
			image="$HOME/.config/xfce4/wallpaper/modded-ubuntu-tech.jpg"
		else
			image=/usr/share/backgrounds/xfce/modded-ubuntu-tech.jpg
		fi
		;;
	*)
		if [[ "$argument" == */* ]] || [ -f "$argument" ]; then
			image="$argument"
		else
			image=$(resolve_wallpaper_name "$argument" || true)
		fi
		;;
esac

if [ ! -f "$image" ]; then
	warn "Imagem de papel de parede não encontrada; pulando."
	exit 0
fi

if ! command -v xfconf-query >/dev/null 2>&1; then
	warn "xfconf-query não encontrado; pulando."
	exit 0
fi

set_property() {
	local property="$1"
	local value_type="$2"
	local value="$3"
	if xfconf-query -c xfce4-desktop -p "$property" >/dev/null 2>&1; then
		xfconf-query -c xfce4-desktop -p "$property" -s "$value" >/dev/null 2>&1 || true
	else
		xfconf-query -c xfce4-desktop -p "$property" -n -t "$value_type" -s "$value" >/dev/null 2>&1 || true
	fi
}

properties=$(xfconf-query -c xfce4-desktop -l 2>/dev/null || true)
while IFS= read -r property; do
	[ -n "$property" ] || continue
	case "$property" in
		*/last-image)
			base_property="${property%/last-image}"
			set_property "$property" string "$image"
			set_property "$base_property/image-style" int 5
			set_property "$base_property/color-style" int 0
			;;
	esac
done <<EOF
$properties
EOF

monitors=()
if command -v xrandr >/dev/null 2>&1; then
	while IFS= read -r monitor; do
		[ -n "$monitor" ] && monitors+=("$monitor")
	done < <(xrandr --listmonitors 2>/dev/null | awk 'NR > 1 {print $NF}')
fi
monitors+=(VNC-0 screen)

for monitor in "${monitors[@]}"; do
	base_property="/backdrop/screen0/monitor${monitor}/workspace0"
	set_property "$base_property/last-image" string "$image"
	set_property "$base_property/image-style" int 5
	set_property "$base_property/color-style" int 0
done

if command -v xfdesktop >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
	if pgrep -x xfdesktop >/dev/null 2>&1; then
		xfdesktop --reload >/dev/null 2>&1 || true
	else
		xfdesktop >/dev/null 2>&1 &
	fi
fi

exit 0
