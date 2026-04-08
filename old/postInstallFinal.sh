#!/bin/bash

# === Constants ===
BLUE="\e[1;34m"
RESET="\e[0m"
AUR_DIR="$HOME/AUR"

# === Functions ===

log() {
    echo -e "${BLUE}>> $1${RESET}"
}

error_exit() {
    echo -e "${BLUE}>> Error: $1${RESET}" >&2
    exit 1
}

check_folder_exists() {
    local folder="$1"
    [ -d "$folder" ] && log "Folder '$folder' already exists." && return 0 || return 1
}

check_file_exists() {
    local file="$1"
    [ -f "$file" ] && log "File '$file' already exists." && return 0 || return 1
}

check_app_installed() {
    local app="$1"
    command -v "$app" >/dev/null 2>&1 && log "Application '$app' is already installed." && return 0 || return 1
}

setup_mirrors() {
    log "Configuring mirrors..."
    sudo pacman -Syu --needed reflector || error_exit "Failed to install reflector."
    sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
    sudo reflector --country france --age 6 --protocol https --sort rate --save /etc/pacman.d/mirrorlist || error_exit "Reflector setup failed."
    sudo pacman -Syy || error_exit "Pacman failed to refresh mirrors."
}

setup_mirror_timer() {
    log "Setting up reflector timer..."
    sudo bash -c 'cat > /etc/systemd/system/reflector.service <<EOF
[Unit]
Description=Update Arch Linux Mirrorlist

[Service]
Type=oneshot
ExecStart=/usr/bin/reflector --country france --age 6 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
EOF'

    sudo bash -c 'cat > /etc/systemd/system/reflector.timer <<EOF
[Unit]
Description=Run Reflector Weekly

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF'

    sudo systemctl daemon-reload
    sudo systemctl enable --now reflector.timer || error_exit "Failed to enable reflector timer."
}

install_paru() {
    log "Installing paru..."
    check_folder_exists "$AUR_DIR" || mkdir -p "$AUR_DIR" || error_exit "Failed to create AUR directory."
    cd "$AUR_DIR" || error_exit "Failed to navigate to AUR directory."

    local PARU_DIR="${AUR_DIR}/paru-bin"
    check_folder_exists "$PARU_DIR" || git clone https://aur.archlinux.org/paru-bin.git "$PARU_DIR" || error_exit "Failed to clone paru repository."
    cd "$PARU_DIR" || error_exit "Failed to navigate to paru directory."
    makepkg -si --noconfirm || error_exit "Failed to build/install paru."
}

install_essentials() {
    log "Installing essential packages..."
    sudo pacman -Syu --needed --noconfirm git wget curl vim zsh neovim btrfs-progs dosfstools exfatprogs e2fsprogs ntfs-3g xfsprogs udftools || error_exit "Failed to install essentials."
}

install_custom_tools() {
    log "Installing custom tools..."
    sudo pacman -Syu --needed --noconfirm htop fastfetch firefox unzip zip wl-clipboard deluge deluge-gtk bzip2 bzip3 gzip xz p7zip unrar eza yazi swww waybar gcc gdb nmap wireshark-qt aircrack-ng nikto john sqlmap lsdn whois netcat gparted gpart xorg-xhost || error_exit "Failed to install custom tools."
}

install_qemu_kvm() {
    log "Installing QEMU/KVM tools..."
    sudo pacman -Syu --needed --noconfirm qemu-full qemu-img libvirt virt-install virt-manager virt-viewer edk2-ovmf swtpm guestfs-tools libosinfo tuned || error_exit "Failed to install QEMU/KVM tools."
    sudo systemctl enable libvirtd.service
    sudo virt-host-validate qemu
    sudo systemctl enable --now tuned.service
    tuned-adm active
    sudo tuned-adm profile virtual-host
    sudo tuned-adm verify
}

configure_zsh() {
    log "Configuring ZSH..."
    local ZSHRC_FILE="$HOME/.zshrc"
    check_file_exists "$ZSHRC_FILE" || touch "$ZSHRC_FILE" || error_exit "Failed to create .zshrc file."

    log "Updating .zshrc with aliases and plugins..."
    cat > "$ZSHRC_FILE" <<'EOF'
alias ll='ls -la'
alias pac='sudo pacman -Syu --needed'
alias szsh='source ~/.zshrc'
alias nzsh='nvim ~/.zshrc'

# Auto ls after cd
cd() {
    builtin cd "$@" && ls -la
}

# ZSH Plugins
source ${HOME}/AUR/zsh-autosuggestions/zsh-autosuggestions.zsh
source ${HOME}/AUR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
EOF

    source "$ZSHRC_FILE" || log "Loaded new ZSH configuration."
}

install_zsh_plugins() {
    log "Installing ZSH plugins..."
    local AUTOSUGGESTIONS_DIR="$AUR_DIR/zsh-autosuggestions"
    local SYNTAX_HIGHLIGHTING_DIR="$AUR_DIR/zsh-syntax-highlighting"

    check_folder_exists "$AUTOSUGGESTIONS_DIR" || git clone https://github.com/zsh-users/zsh-autosuggestions "$AUTOSUGGESTIONS_DIR" || error_exit "Failed to clone zsh-autosuggestions."
    check_folder_exists "$SYNTAX_HIGHLIGHTING_DIR" || git clone https://github.com/zsh-users/zsh-syntax-highlighting "$SYNTAX_HIGHLIGHTING_DIR" || error_exit "Failed to clone zsh-syntax-highlighting."
}

install_fonts() {
    log "Installing fonts..."
    sudo pacman -Syu --needed --noconfirm ttf-dejavu ttf-roboto noto-fonts otf-droid-nerd otf-firamono-nerd otf-monaspace-nerd ttf-jetbrains-mono-nerd ttf-ubuntu-mono-nerd ttf-proggyclean-nerd otf-font-awesome || error_exit "Failed to install fonts."
}

setup_firewall() {
    log "Setting up firewall..."
    sudo pacman -Syu --needed --noconfirm ufw || error_exit "Failed to install UFW."
    sudo systemctl enable --now ufw || error_exit "Failed to enable UFW."
    sudo ufw default deny
    sudo ufw allow from 192.168.0.0/24
    sudo ufw allow Deluge
    sudo ufw limit ssh
    sudo ufw enable || error_exit "Failed to enable firewall rules."
}

install_power_management() {
    log "Installing power management tools..."
    sudo pacman -Syu --needed --noconfirm tlp tlp-rdw || error_exit "Failed to install TLP."
    sudo systemctl enable tlp
    sudo systemctl start tlp
    sudo systemctl mask systemd-rfkill.service
    sudo systemctl mask systemd-rfkill.socket
}

#configure_neovim() {
#    log "Configuring Neovim..."
#    local NVIM_DIR="$HOME/.config/nvim"
#    local NVIM_FILE="$NVIM_DIR/init.lua"
#    mkdir -p "$NVIM_DIR" || error_exit "Failed to create Neovim configuration directory."
#    nvim --headless -c 'call mkdir(stdpath("config"), "p") | exe "edit" stdpath("config") . "/init.lua" | write | quit' || error_exit "Failed to create Neovim init.lua."
 #   cat >> "$NVIM_FILE" <<'EOF'
#set number 
#"set relativenumber
#EOF
#}

# === Main Script ===

log "Starting post-installation script..."

setup_mirrors
setup_mirror_timer
install_paru
install_essentials
install_custom_tools
install_qemu_kvm
install_zsh_plugins
configure_zsh
install_fonts
setup_firewall
install_power_management
configure_neovim

log "Post-installation script completed successfully!"

