#!/bin/bash

# Script para corrigir o erro [Process completed (signal 9) - press Enter] no Termux
# causado pelo Phantom Process Killer do Android 12+.
# Script to fix the [Process completed (signal 9) - press Enter] error in Termux
# caused by the Android 12+ Phantom Process Killer.

R="$(printf '\033[1;31m')"
G="$(printf '\033[1;32m')"
Y="$(printf '\033[1;33m')"
C="$(printf '\033[1;36m')"
NC="$(printf '\033[0m')"

show_help() {
    cat << EOF
${C}Uso / Usage:${NC}
  bash fix-signal9.sh [opção/option]

${C}Opções / Options:${NC}
  --help, -h       Mostra esta ajuda / Show this help
  --check, -c      Apenas verifica o estado atual / Only check current state
  --apply, -a      Aplica a correção (padrão) / Apply the fix (default)

${C}Descrição / Description:${NC}
  Esse script tenta desabilitar o Phantom Process Killer do Android.
  This script tries to disable the Android Phantom Process Killer.

  ${Y}Sem root / Non-root:${NC} o Android não permite alterar a configuração
  diretamente pelo Termux; o script mostrará instruções manuais.
  the Android does not allow changing this setting directly from Termux;
  the script will show manual instructions.

  ${Y}Com root / Rooted:${NC} o script executa os comandos su corretos para a
  versão do Android e pede para reiniciar.
  the script runs the correct su commands for the Android version and
  asks for a reboot.
EOF
}

log() {
    echo -e "${C}[$(date '+%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${R}[ERRO / ERROR]${NC} $1" >&2
}

success() {
    echo -e "${G}[OK]${NC} $1"
}

warning() {
    echo -e "${Y}[AVISO / WARNING]${NC} $1"
}

# Detecta se está rodando no Termux / Detect if running in Termux
if [ -z "${PREFIX:-}" ]; then
    error "Este script deve ser executado dentro do Termux. / This script must be run inside Termux."
    exit 1
fi

if ! command -v settings >/dev/null 2>&1 && ! command -v getprop >/dev/null 2>&1; then
    error "Comandos do Android não encontros. Instale o Termux:API ou execute no Termux. / Android commands not found. Install Termux:API or run inside Termux."
    exit 1
fi

# Detecta versão do Android / Detect Android version
ANDROID_VERSION="$(getprop ro.build.version.release 2>/dev/null || echo "0")"
ANDROID_SDK="$(getprop ro.build.version.sdk 2>/dev/null || echo "0")"

# Verifica root / Check for root
IS_ROOTED=false
if command -v su >/dev/null 2>&1 && su -c 'id' >/dev/null 2>&1; then
    IS_ROOTED=true
fi

MODE="apply"
if [ "$#" -ge 1 ]; then
    case "$1" in
        --help|-h)
            show_help
            exit 0
            ;;
        --check|-c)
            MODE="check"
            ;;
        --apply|-a)
            MODE="apply"
            ;;
        *)
            error "Opção inválida: $1 / Invalid option: $1"
            show_help
            exit 1
            ;;
    esac
fi

echo ""
echo -e "${C}=== Fix Termux Signal 9 (Phantom Process Killer) ===${NC}"
echo ""
log "Versão do Android detectada: ${ANDROID_VERSION} (SDK ${ANDROID_SDK})"
log "Root detectado: ${IS_ROOTED}"
echo ""

if [ "${MODE}" = "check" ]; then
    log "Verificando estado atual... / Checking current state..."

    if command -v settings >/dev/null 2>&1; then
        CURRENT_MONITOR="$(settings get global settings_enable_monitor_phantom_procs 2>/dev/null || echo "desconhecido/unknown")"
        log "settings_enable_monitor_phantom_procs = ${CURRENT_MONITOR}"
    fi

    if command -v device_config >/dev/null 2>&1; then
        CURRENT_MAX="$(device_config get activity_manager max_phantom_processes 2>/dev/null || echo "desconhecido/unknown")"
        log "activity_manager/max_phantom_processes = ${CURRENT_MAX}"
    fi

    echo ""
    if [ "$IS_ROOTED" = false ]; then
        warning "Aparelho sem root. Use as instruções manuais do README. / Device not rooted. Use the manual instructions from README."
    fi
    exit 0
fi

if [ "$IS_ROOTED" = false ]; then
    echo -e "${R}Este aparelho não parece ter root.${NC}"
    echo -e "${R}This device does not appear to be rooted.${NC}"
    echo ""
    echo -e "${Y}Siga uma das opções abaixo / Follow one of the options below:${NC}"
    echo ""
    echo -e "${C}1) Android 14+ (sem PC / no PC):${NC}"
    echo "   Acesse Configurações → Opções do desenvolvedor"
    echo "   Go to Settings → Developer Options"
    echo "   Ative 'Desativar restrições de processos filhos'"
    echo "   Enable 'Disable child process restrictions'"
    echo "   Reinicie o aparelho / Reboot the device"
    echo ""
    echo -e "${C}2) Android 12, 12L ou 13 (com PC / with PC):${NC}"
    echo "   Instale o Android Platform Tools no PC"
    echo "   Install Android Platform Tools on your PC"
    echo "   Ative a Depuração USB e conecte o celular"
    echo "   Enable USB debugging and connect the phone"
    echo ""
    if [ "$ANDROID_SDK" -ge 32 ]; then
        echo "   adb shell \"settings put global settings_enable_monitor_phantom_procs false\""
    else
        echo "   adb shell \"/system/bin/device_config set_sync_disabled_for_tests persistent\""
        echo "   adb shell \"/system/bin/device_config put activity_manager max_phantom_processes 2147483647\""
    fi
    echo ""
    echo "   Reinicie o aparelho / Reboot the device"
    echo ""
    exit 0
fi

# Com root: aplica a correção / With root: apply the fix
echo -e "${C}Aplicando correção com root... / Applying fix with root...${NC}"
echo ""

if [ "$ANDROID_SDK" -ge 34 ]; then
    log "Android 14+ detectado. Desabilitando monitor de processos fantasmas..."
    log "Android 14+ detected. Disabling phantom process monitor..."
    if su -c "settings put global settings_enable_monitor_phantom_procs false"; then
        success "Configuração aplicada com sucesso. / Setting applied successfully."
    else
        error "Falha ao aplicar settings_enable_monitor_phantom_procs. / Failed to apply settings_enable_monitor_phantom_procs."
        exit 1
    fi
elif [ "$ANDROID_SDK" -ge 31 ]; then
    log "Android 12/12L/13 detectado. Desabilitando monitor e aumentando limite..."
    log "Android 12/12L/13 detected. Disabling monitor and raising limit..."

    if su -c "/system/bin/device_config set_sync_disabled_for_tests persistent"; then
        success "Sincronização de device_config desabilitada. / device_config sync disabled."
    else
        error "Falha ao desabilitar sincronização de device_config. / Failed to disable device_config sync."
        exit 1
    fi

    if su -c "/system/bin/device_config put activity_manager max_phantom_processes 2147483647"; then
        success "Limite de processos fantasmas aumentado. / Phantom process limit raised."
    else
        error "Falha ao aumentar limite de processos fantasmas. / Failed to raise phantom process limit."
        exit 1
    fi
else
    warning "Android anterior ao 12 detectado. O erro signal 9 não costuma ocorrer nessa versão. / Android version older than 12 detected. The signal 9 error usually does not occur on this version."
    exit 0
fi

echo ""
success "Correção aplicada! / Fix applied!"
warning "Reinicie o aparelho para que a alteração tenha efeito. / Reboot the device for the change to take effect."
warning "Atualizações do sistema podem reverter essa configuração. / System updates may revert this setting."
echo ""
