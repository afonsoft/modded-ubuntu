#!/usr/bin/env bash
set -u

Y="$(printf '\033[1;33m')"
W="$(printf '\033[1;37m')"

warn() {
	printf '%b\n' "${Y}[set-wallpaper] $*${W}"
}

image="${1:-}"
if [ -z "$image" ]; then
	if [ -f "$HOME/.config/xfce4/wallpaper/modded-ubuntu-tech.jpg" ]; then
		image="$HOME/.config/xfce4/wallpaper/modded-ubuntu-tech.jpg"
	else
		image=/usr/share/backgrounds/xfce/modded-ubuntu-tech.jpg
	fi
fi

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
