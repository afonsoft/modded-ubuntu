#!/bin/bash

# Logging
LOG_FILE="/var/log/tools_installation.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "[+] Logging to $LOG_FILE"

# Color Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Non-interactive mode
AUTO_YES=false
for arg in "$@"; do
  case "$arg" in
    -y|--yes) AUTO_YES=true ;;
  esac
done

ask_yn() {
  local var_name="$1"
  local prompt_text="$2"
  if [ "$AUTO_YES" = true ]; then
    echo -e "${GREEN}[+] $prompt_text${NC}: y (modo automático)"
    printf -v "$var_name" '%s' "y"
  else
    local answer
    read -rp "$prompt_text (y/n): " answer
    printf -v "$var_name" '%s' "$answer"
  fi
}

export DEBIAN_FRONTEND=noninteractive

# Error Handling
handle_error() {
  echo -e "${RED}[-] Error: $1${NC}"
  exit 1
}

display_banner() {
  echo -e "${GREEN}=============================================${NC}"
  echo -e "${CYAN}  Linux Tools Installation Script            ${NC}"
  echo -e "${MAGENTA}        Coded by LIONMAD                    ${NC}"
  echo -e "${MAGENTA}         Credit to BDhackers009                ${NC}"
  echo -e "${GREEN}=============================================${NC}"
  echo ""
  echo -e "${YELLOW}[+] Welcome to the Interactive Tool Installation Script${NC}"
  echo -e "${YELLOW}[+] This script will help you install various security and utility tools.${NC}"
  echo -e "${YELLOW}[+] Please follow the prompts to select the tools you want to install.${NC}"
  echo ""
}

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo -e "${RED}[-] This script must be run as root.${NC}"
  exec sudo "$0" "$@"
  exit 1
fi

# Evita que pacotes tentem iniciar serviços dentro do PRoot
if [ ! -f /usr/sbin/policy-rc.d ]; then
  printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d
  chmod 755 /usr/sbin/policy-rc.d
fi

# Detect Linux Distribution
detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "$ID"
  elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    echo "$DISTRIB_ID"
  elif [ -f /etc/debian_version ]; then
    echo "debian"
  elif [ -f /etc/redhat-release ]; then
    echo "rhel"
  elif [ -f /etc/arch-release ]; then
    echo "arch"
  else
    echo "unknown"
  fi
}

# Detect Package Manager Based on Distro
detect_package_manager() {
  local distro=$1
  case $distro in
    ubuntu | debian | kali)
      echo "apt"
      ;;
    arch | manjaro)
      echo "pacman"
      ;;
    fedora | centos | rhel | rocky | alma)
      if command -v dnf &>/dev/null; then
        echo "dnf"
      else
        echo "yum"
      fi
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

DISTRO=$(detect_distro)
PACKAGE_MANAGER=$(detect_package_manager "$DISTRO")

if [ "$PACKAGE_MANAGER" == "unknown" ]; then
  handle_error "Unsupported Linux distribution. Exiting..."
fi

echo -e "${GREEN}[+] Detected Distribution: $DISTRO${NC}"
echo -e "${GREEN}[+] Using Package Manager: $PACKAGE_MANAGER${NC}"

# Update system packages
update_system() {
  echo -e "${YELLOW}[+] Updating system packages...${NC}"
  case $PACKAGE_MANAGER in
    apt)
      apt-get update -yq && apt-get upgrade -yq || handle_error "Failed to update system packages."
      ;;
    pacman)
      pacman -Syu --noconfirm || handle_error "Failed to update system packages."
      ;;
    yum)
      yum update -y || handle_error "Failed to update system packages."
      ;;
    dnf)
      dnf update -y || handle_error "Failed to update system packages."
      ;;
  esac
  echo -e "${GREEN}[+] System packages updated successfully.${NC}"
}

# Install a package with the detected package manager
install_package() {
  local package=$1
  echo -n "[+] Installing $package..."
  case $PACKAGE_MANAGER in
    apt)
      if apt-get install -yq "$package"; then
        echo -e "${GREEN} Done.${NC}"
      else
        echo -e "${RED} Failed.${NC}"
        return 1
      fi
      ;;
    pacman)
      if pacman -S --noconfirm "$package"; then
        echo -e "${GREEN} Done.${NC}"
      else
        echo -e "${RED} Failed.${NC}"
        return 1
      fi
      ;;
    yum)
      if yum install -y "$package"; then
        echo -e "${GREEN} Done.${NC}"
      else
        echo -e "${RED} Failed.${NC}"
        return 1
      fi
      ;;
    dnf)
      if dnf install -y "$package"; then
        echo -e "${GREEN} Done.${NC}"
      else
        echo -e "${RED} Failed.${NC}"
        return 1
      fi
      ;;
  esac
}

# Interactive Mode
interactive_mode() {
  display_banner

  # Inicializa variáveis para evitar avisos e garantir valores padrão
  update_system_choice=""
  install_essential=""
  install_network=""
  install_web=""
  install_pen_test=""
  install_vuln=""
  install_info=""
  install_password=""
  install_exploit=""
  install_misc=""
  install_additional=""
  install_metasploit=""
  cleanup_choice=""

  # Update system
  ask_yn update_system_choice "Do you want to update the system packages?"
  if [[ "$update_system_choice" == "y" ]]; then
    update_system
  else
    echo -e "${YELLOW}[+] Skipping system update.${NC}"
  fi

  # Essential Dependencies
  ask_yn install_essential "Do you want to install Essential Dependencies?"
  if [[ "$install_essential" == "y" ]]; then
    ESSENTIAL_PACKAGES="build-essential python3-pip python3-dev git curl wget"
    for pkg in $ESSENTIAL_PACKAGES; do
      install_package "$pkg"
    done
  fi

  # Network Tools
  ask_yn install_network "Do you want to install Network Tools?"
  if [[ "$install_network" == "y" ]]; then
    # Pré-configura wireshark-common para evitar prompt do debconf
    if ! command -v debconf-set-selections >/dev/null 2>&1; then
      apt-get install -yq debconf-utils >/dev/null 2>&1 || true
    fi
    echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections 2>/dev/null || true
    NETWORK_TOOLS="nmap ncat ndiff zenmap wireshark tshark tcpdump netcat-traditional ettercap-common arpwatch"
    for tool in $NETWORK_TOOLS; do
      install_package "$tool"
    done
  fi

  # Web Application Testing Tools
  ask_yn install_web "Do you want to install Web Application Testing Tools?"
  if [[ "$install_web" == "y" ]]; then
    WEB_TOOLS="gobuster ffuf wpscan nikto"
    for tool in $WEB_TOOLS; do
      install_package "$tool"
    done
  fi

  # Penetration Testing Tools
  ask_yn install_pen_test "Do you want to install Penetration Testing Tools?"
  if [[ "$install_pen_test" == "y" ]]; then
    PEN_TEST_TOOLS="metasploit-framework aircrack-ng bettercap beef-xss"
    for tool in $PEN_TEST_TOOLS; do
      install_package "$tool"
    done
  fi

  # Vulnerability Analysis Tools
  ask_yn install_vuln "Do you want to install Vulnerability Analysis Tools?"
  if [[ "$install_vuln" == "y" ]]; then
    VULN_TOOLS="hydra sqlmap rkhunter chkrootkit lynis"
    for tool in $VULN_TOOLS; do
      install_package "$tool"
    done
  fi

  # Information Gathering Tools
  ask_yn install_info "Do you want to install Information Gathering Tools?"
  if [[ "$install_info" == "y" ]]; then
    INFO_TOOLS="theharvester cewl dnsrecon dnsenum amass subfinder"
    for tool in $INFO_TOOLS; do
      install_package "$tool"
    done
  fi

  # Password Cracking Tools
  ask_yn install_password "Do you want to install Password Cracking Tools?"
  if [[ "$install_password" == "y" ]]; then
    PASSWORD_TOOLS="john hashcat crunch"
    for tool in $PASSWORD_TOOLS; do
      install_package "$tool"
    done
  fi

  # Exploitation Tools
  ask_yn install_exploit "Do you want to install Exploitation Tools?"
  if [[ "$install_exploit" == "y" ]]; then
    EXPLOIT_TOOLS="responder evil-winrm mimikatz powershell-empire"
    for tool in $EXPLOIT_TOOLS; do
      install_package "$tool"
    done
  fi

  # Miscellaneous Tools
  ask_yn install_misc "Do you want to install Miscellaneous Tools?"
  if [[ "$install_misc" == "y" ]]; then
    MISC_TOOLS="burpsuite yara fcrackzip dirbuster spiderfoot masscan"
    for tool in $MISC_TOOLS; do
      install_package "$tool"
    done
  fi

  # Additional Tools
  ask_yn install_additional "Do you want to install Additional Tools?"
  if [[ "$install_additional" == "y" ]]; then
    ADDITIONAL_TOOLS="recon-ng maltego sublist3r massdns dirsearch scapy feroxbuster wfuzz"
    for tool in $ADDITIONAL_TOOLS; do
      install_package "$tool"
    done
  fi

  # Install Metasploit Framework
  ask_yn install_metasploit "Do you want to install Metasploit Framework?"
  if [[ "$install_metasploit" == "y" ]]; then
    if command -v curl &>/dev/null; then
      echo "[+] Installing Metasploit Framework..."
      curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb > msfinstall
      chmod 755 msfinstall && ./msfinstall || handle_error "Failed to install Metasploit Framework."
    else
      echo "[-] curl is not installed. Skipping Metasploit installation."
    fi
  fi

  # Cleanup unnecessary packages
  ask_yn cleanup_choice "Do you want to clean up unnecessary packages?"
  if [[ "$cleanup_choice" == "y" ]]; then
    echo "[+] Cleaning up unnecessary packages..."
    case $PACKAGE_MANAGER in
      apt)
        apt-get autoremove -yq || handle_error "Failed to clean up unnecessary packages."
        ;;
      pacman)
        pacman -Rns "$(pacman -Qdtq)" --noconfirm || handle_error "Failed to clean up unnecessary packages."
        ;;
      yum | dnf)
        echo "[+] Skipping cleanup for $PACKAGE_MANAGER as it doesn't require additional commands."
        ;;
    esac
    echo -e "${GREEN}[+] Cleanup complete.${NC}"
  else
    echo -e "${YELLOW}[+] Skipping cleanup.${NC}"
  fi

  # Final cleanup
  echo -e "${CYAN}[*] Limpando caches e temporários restantes...${NC}"
  case $PACKAGE_MANAGER in
    apt)
      apt-get clean 2>/dev/null || true
      ;;
    pacman)
      pacman -Sc --noconfirm 2>/dev/null || true
      ;;
    yum | dnf)
      $PACKAGE_MANAGER clean all 2>/dev/null || true
      ;;
  esac

  if command -v npm >/dev/null 2>&1; then
    npm cache clean --force 2>/dev/null || true
  fi
  if command -v pip >/dev/null 2>&1; then
    pip cache purge 2>/dev/null || true
  fi

  rm -f /tmp/tools.sh /tmp/install_ghost.sh msfinstall 2>/dev/null || true

  # Final message
  echo -e "${GREEN}[+] Installation complete! All selected tools are installed successfully.${NC}"
  echo -e "${GREEN}[+] You may want to restart your system for all changes to take effect.${NC}"
}

# Main Script Logic
interactive_mode
