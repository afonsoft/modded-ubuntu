#!/usr/bin/env bash
# Otimizações de performance/qualidade para Samsung S26 e dispositivos de alta resolução
set -e

G="\033[1;32m"
Y="\033[1;33m"
C="\033[1;36m"
W="\033[0m"

echo -e "${G} [${W}~${G}]${C} Otimizando XFCE4 para alta resolução e baixa latência...${W}"

# Desativa vsync/compositor para reduzir input lag e melhorar o desempenho
xfconf-query -c xfwm4 -p /general/vblank_mode -s off 2>/dev/null || true
xfconf-query -c xfwm4 -p /general/use_compositing -s false 2>/dev/null || true

# Ajusta o DPI para telas de alta densidade (ex.: Galaxy S26)
xfconf-query -c xsettings -p /Xft/DPI -n -t int -s 120 2>/dev/null || \
    xfconf-query -c xsettings -p /Xft/DPI -s 120 2>/dev/null || true

echo -e "${G} [${W}+${G}]${C} Otimização concluída.${W}"
echo -e "${Y} Use ${W}vncstart-fhd${Y} para 2340x1080 ou ${W}vncstart-qhd${Y} para 3088x1440.${W}"
