#!/bin/bash
# Mise à jour du système
echo -e "\e[1;34m>> Mise à jour du système...\e[0m"
sudo pacman -Syu --noconfirm


#__________
# Mirrors configuration
echo -e "\e[1;34m>> Configuration des miroirs ...\e[0m"
sudo pacman -Syu --needed reflector
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
sudo reflector --country france --age 6 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
sudo pacman -Syy

# Update Mirrors Service
sudo bash -c 'cat > /etc/systemd/system/reflector.service <<EOF
[Unit]
Description=Update Arch Linux Mirrorlist

[Service]
Type=oneshot
ExecStart=/usr/bin/reflector --country france --age 6 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
EOF'

# Timer for Mirrors
sudo bash -c 'cat > /etc/systemd/system/reflector.timer <<EOF
[Unit]
Description=Run Reflector Weekly

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF'

# Reload systemd and enable the timer
sudo systemctl daemon-reload
sudo systemctl enable --now reflector.timer



#__________
# AUR helper

# Function to check if a folder exists
check_folder_exists() {
    local folder="$1"
    if [ -d "$folder" ]; then
        echo -e "\e[1;34m>> Folder '$folder' already exists.\e[0m"
        return 0 # True
    else
        echo -e "\e[1;34m>> Folder '$folder' does not exist.\e[0m"
        return 1 # False
    fi
}

# Function to check if an application is installed
check_app_installed() {
    local app="$1"
    if command -v "$app" >/dev/null 2>&1; then
        echo -e "\e[1;34m>> Application '$app' is already installed.\e[0m"
        return 0 # True
    else
        echo -e "\e[1;34m>> Application '$app' is not installed.\e[0m"
        return 1 # False
    fi
}

# Define the AUR directory and Paru folder
AUR_DIR="$HOME/AUR"
PARU_DIR="$AUR_DIR/paru"

# Check if paru is installed
if check_app_installed "paru"; then
    echo -e "\e[1;34m>> Skipping paru installation.\e[0m"
else
    # Check and create AUR directory if it doesn't exist
    if ! check_folder_exists "$AUR_DIR"; then
        echo -e "\e[1;34m>> Creating AUR directory...\e[0m"
        mkdir -p "$AUR_DIR"
    fi

    # Change to the AUR directory
    cd "$AUR_DIR"

    # Clone the paru repository if not already cloned
    if ! check_folder_exists "$PARU_DIR"; then
        echo -e "\e[1;34m>> Cloning paru repository...\e[0m"
        git clone https://aur.archlinux.org/paru.git
    else
        echo -e "\e[1;34m>> Paru repository already exists. Skipping clone.\e[0m"
    fi

    # Change to the paru directory
    cd "$PARU_DIR"

    # Build and install paru
    echo -e "\e[1;34m>> Building and installing paru...\e[0m"
    makepkg -si --noconfirm
fi

echo -e "\e[1;34m>> Function completed!\e[0m"

cd


#__________
echo -e "\e[1;34m>> Installation des paquets essentiels...\e[0m"
sudo pacman -Syu --needed --noconfirm git wget curl vim neovim zsh less vi pavucontrol cmake neovim btrfs-progs dosfstools exfatprogs e2fsprogs ntfs-3g xfsprogs udftools 


#__________
echo -e "\e[1;34m>> Installation d'outils personnalisés...\e[0m"
sudo pacman -Syu --needed --noconfirm htop fastfetch firefox unzip zip wl-clipboard deluge deluge-gtk bzip2 bzip3 gzip xz p7zip unrar eza yazi swww waybar gcc gdb nmap wireshark-qt aircrack-ng nikto john sqlmap lsdn whois netcat gparted gpart xorg-xhost

#__________
echo -e "\e[1;34m>> Installation de Qemu/Kvm...\e[0m"
sudo pacman -Syu --needed --noconfirm qemu-full qemu-img libvirt virt-install virt-manager virt-viewer edk2-ovmf swtpm guestfs-tools libosinfo tuned

sudo systemctl enable libvirtd.service
sudo virt-host-validate qemu
sudo systemctl enable --now tuned.service
tuned-adm active
sudo tuned-adm profile virtual-host
sudo tuned-adm verify

#__________
# Creating bridge interface 
# https://gist.github.com/tatumroaquin/c6464e1ccaef40fd098a4f31db61ab22
#sudo nmcli device status
#sudo nmcli connection add type bridge con-name bridge0 ifname bridge0
#sudo nmcli connection add type ethernet slave-type bridge con-name 'Bridge connection 1' \
#ifname enp3s0 master bridge0
#sudo nmcli connection up bridge0
#sudo nmcli connection modify bridge0 connection.autoconnect-slaves 1
#sudo nmcli connection up bridge0
#sudo nmcli device status
#configure bridge network
#touch nwbridge.xml

#bash -c 'cat > nwbridge.xml << EOF
#<network>
#    <name>nwbridge</name>
#    <forward mode="bridge" />
#    <bridge name="bridge0" />
#</network>
#EOF'
#sudo mv nwbridge.xml /etc/libvirt/qemu/networks/
#sudo virsh net-start nwbridge
#sudo virsh net-autostart nwbridge
#sudo rm /etc/libvirt/qemu/networks/nwbridge.xml
#sudo virsh net-list --all

#Removing bridge network and interface

#If you want to revert the changes to your network, do the following:

#sudo virsh net-destroy nwbridge
#sudo virsh net-undefine nwbridge
#sudo nmcli connection up 'Wired connection 1'
#sudo nmcli connection del bridge0
#sudo nmcli connection del 'Bridge connection 1'

# Granting system-wide access to regular user.
sudo virsh uri
sudo usermod -aG libvirt $USER
# if needed > qemu:///session
#echo 'export LIBVIRT_DEFAULT_URI="qemu:///system"' >> ~/.bashrc
#echo 'export LIBVIRT_DEFAULT_URI="qemu:///system"' >> ~/.zshrc

# Set ACL for the KVM images directory
sudo getfacl /var/lib/libvirt/images
sudo setfacl -R -b /var/lib/libvirt/images/
sudo setfacl -R -m u:${USER}:rwX /var/lib/libvirt/images/
# >> uppercase X states that execution permission only applied to child folders and not child files.
sudo setfacl -m d:u:${USER}:rwx /var/lib/libvirt/images/
sudo getfacl /var/lib/libvirt/images/

# Installing Fonts
#__________
echo -e "\e[1;34m>> Install Fonts...\e[0m"
sudo pacman -Syu otf-droid-nerd otf-firamono-nerd otf-monaspace-nerd ttf-dejavu-nerd ttf-jetbrains-mono-nerd ttf-roboto-mono-nerd ttf-ubuntu-mono-nerd ttf-proggyclean-nerd otf-font-awesome

#__________
echo -e "\e[1;34m>> AUR helper install needed apps...\e[0m"
paru -Syu wlogout swaylock-effects burpsuite

#__________
echo -e "\e[1;34m>> Configuration utilisateur Bashrc...\e[0m"
echo "alias ll='ls -la'" >> ~/.bashrc
source ~/.bashrc

#__________
echo -e "\e[1;34m>> Nettoyage des paquets...\e[0m"
sudo pacman -Sc --noconfirm



#__________
# Copy hyprland.conf
#mkdir -p ~/.config/hypr
#cp /usr/share/hyprland/hyprland.conf.example ~/.config/hypr/hyprland.conf


#__________
# Waybar
#mkdir -p ~/.config/waybar
#cp /etc/xdg/waybar/config ~/.config/waybar/
#cp /etc/xdg/waybar/style.css ~/.config/waybar/


#__________
# Font
echo -e "\e[1;34m>> Installing Fonts...\e[0m"
sudo pacman -Syu --needed ttf-dejavu ttf-liberation noto-fonts ttf-roboto


#__________
# Power Management Battery
echo -e "\e[1;34m>> Installing Power Management Tools for LapTops...\e[0m"
sudo pacman -Syu --needed tlp tlp-rdw
sudo systemctl enable tlp
sudo systemctl start tlp

sudo systemctl mask systemd-rfkill.service
sudo systemctl mask systemd-rfkill.socket


#_________
# Fire Wall
echo -e "\e[1;34m>> Setting up Firewall...\e[0m"
sudo pacman -Syu --needed ufw
sudo systemctl enable --now ufw
sudo ufw default deny
sudo ufw allow from 192.168.0.0/24
sudo ufw allow Deluge
sudo ufw limit ssh
sudo ufw enable


# ZSH
#__________
echo -e "\e[1;34m>> Making Zsh the default shell\e[0m"
chsh -s /usr/bin/zsh



# Git clone apps ...
#__________

# Define variables
AUR_DIR="$HOME/AUR"
ZSH_AUTOSUGGESTIONS_DIR="$AUR_DIR/zsh-autosuggestions"
ZSH_SYNTAX_HIGHLIGHTING_DIR="$AUR_DIR/zsh-syntax-highlighting"

# Ensure the AUR directory exists
if ! check_folder_exists "$AUR_DIR"; then
    echo -e "\e[1;34m>> Creating AUR directory at '$AUR_DIR'...\e[0m"
    mkdir -p "$AUR_DIR"
fi

# Check if zsh-autosuggestions folder exists
if ! check_folder_exists "$ZSH_AUTOSUGGESTIONS_DIR"; then
    echo -e "\e[1;34m>> Cloning zsh-autosuggestions repository into '$ZSH_AUTOSUGGESTIONS_DIR'...\e[0m"
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_AUTOSUGGESTIONS_DIR"
else
    echo -e "\e[1;34m>> zsh-autosuggestions is already installed.\e[0m"
fi

# Check if zsh-syntax-highlighting folder exists
if ! check_folder_exists "$ZSH_SYNTAX_HIGHLIGHTING_DIR"; then
    echo -e "\e[1;34m>> Cloning zsh-syntax-highlighting repository into '$ZSH_SYNTAX_HIGHLIGHTING_DIR'...\e[0m"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_SYNTAX_HIGHLIGHTING_DIR"
else
    echo -e "\e[1;34m>> zsh-syntax-highlighting is already installed.\e[0m"
fi



# Function Check if file exist
check_file_exists() {
    local file="$1"
    if [ -f "$file" ]; then
        echo -e "\e[1;34m>> File '$file' already exists.\e[0m"
        return 0 # True
    else
        echo -e "\e[1;34m>> File '$file' does not exist.\e[0m"
        return 1 # False
    fi
}


# ADD link in .zshrc
# Define the .zshrc file path
ZSHRC_FILE="$HOME/.zshrc"

# Check if .zshrc exists
if ! check_file_exists "$ZSHRC_FILE"; then
    echo -e "\e[1;34m>> Creating .zshrc file...\e[0m"
    touch "$ZSHRC_FILE"
fi

# Write to .zshrc (append in both cases)
echo -e "\e[1;34m>> Writing to .zshrc file...\e[0m"

ZSHRC_FILE="$HOME/.zshrc"

# Write the content to .zshrc
cat > "$ZSHRC_FILE" <<'EOF'
alias ls="eza -l"
alias ll="eza -l"
alias la="eza -la"
alias pac="sudo pacman -Syu --needed "
alias syss="sudo systemctl start "
alias syse="sudo systemctl enable "
alias szsh="source ~/.zshrc"
alias nzsh="nvim ~/.zshrc"
alias fm="yazi"
alias ip="ip -c "
alias ping="ping -c4 "
alias ssh="kitty + kitten ssh "

# Auto ls after cd
cd() {
    builtin cd "$@" && ls -la
}

autoload -Uz compinit promptinit vcs_info
precmd() { vcs_info }
compinit
promptinit

# This will set the default prompt to the walters theme
#prompt walters

# Lines configured by zsh-newuser-install
setopt APPEND_HISTORY
setopt SHARE_HISTORY
HISTFILE=~/.histfile
HISTSIZE=5001
SAVEHIST=5000
setopt HIST_EXPIRE_DUPS_FIRST
setopt EXTENDED_HISTORY

# autocompletion using arrow keys (based on history)
bindkey '\e[A' history-search-backward
bindkey '\e[B' history-search-forward

# The following lines were added by compinstall
zstyle :compinstall filename '/home/antoine/.zshrc'
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

zstyle ':vcs_info:git:*' formats '%b '
setopt PROMPT_SUBST

export PS1="
%{%F{220}%}%~ %{%f%}
> "
EOF

echo "source ${ZSH_AUTOSUGGESTIONS_DIR}/zsh-autosuggestions.zsh" >> "$ZSHRC_FILE"
echo "source ${ZSH_SYNTAX_HIGHLIGHTING_DIR}/zsh-syntax-highlighting.zsh" >> "$ZSHRC_FILE"

echo -e "\e[1;34m>> .zshrc has been updated with the new configuration.\e[0m"
source ~/.zshrc


# Nvim Conf
#__________
# Define variables
nvim_DIR="$HOME/.config/nvim"
nvim_FILE="$nvim_DIR/init.lua"

# Ensure the AUR directory exists
#if ! check_folder_exists "$nvim_DIR"; then
#    echo -e "\e[1;34m>> Creating nvim directory at '$nvim_DIR'...\e[0m"
#    mkdir -p "$nvim_DIR"
#fi


# ADD conf to init.vim

# Check if init.vim exists
#if ! check_file_exists "$nvim_FILE"; then
#    echo -e "\e[1;34m>> Creating init.vim file...\e[0m"
#    touch "$nvim_FILE"
#fi

# Write to init.vim (append in both cases)
#echo -e "\e[1;34m>> Writing to init.vim file...\e[0m"

# Create folder and init.lua file
nvim --headless -c 'call mkdir(stdpath("config"), "p") | exe "edit" stdpath("config") . "/init.lua" | write | quit'

# Write the content to .zshrc
cat >> "$nvim_FILE" <<'EOF'
set number 
"set relativenumber
EOF

echo -e "\e[1;34m>> Post-installation terminée.\e[0m"
