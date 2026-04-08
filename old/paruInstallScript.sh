#!/bin/bash

# ANSI color codes
BLUE="\e[1;34m"
RESET="\e[0m"

# Function to check if a folder exists
check_folder_exists() {
    local folder="$1"
    if [ -d "$folder" ]; then
        echo -e "${BLUE}>> Folder '$folder' already exists.${RESET}"
        return 0 # True
    else
        echo -e "${BLUE}>> Folder '$folder' does not exist.${RESET}"
        return 1 # False
    fi
}

# Function to check if an application is installed
check_app_installed() {
    local app="$1"
    if command -v "$app" >/dev/null 2>&1; then
        echo -e "${BLUE}>> Application '$app' is already installed.${RESET}"
        return 0 # True
    else
        echo -e "${BLUE}>> Application '$app' is not installed.${RESET}"
        return 1 # False
    fi
}

# Define the AUR directory and Paru folder
AUR_DIR="${HOME}/AUR"
PARU_DIR="${AUR_DIR}/paru"

# Check if git is installed
if ! check_app_installed "git"; then
    echo -e "${BLUE}>> Git is required but not installed. Please install git first.${RESET}"
    exit 1
fi

# Check if paru is installed
if check_app_installed "paru"; then
    echo -e "${BLUE}>> Skipping paru installation.${RESET}"
else
    # Check and create AUR directory if it doesn't exist
    if ! check_folder_exists "$AUR_DIR"; then
        echo -e "${BLUE}>> Creating AUR directory...${RESET}"
        mkdir -p "$AUR_DIR" || { echo -e "${BLUE}>> Failed to create AUR directory.${RESET}"; exit 1; }
    fi

    # Change to the AUR directory
    cd "$AUR_DIR" || { echo -e "${BLUE}>> Failed to navigate to AUR directory.${RESET}"; exit 1; }

    # Clone the paru repository if not already cloned
    if ! check_folder_exists "$PARU_DIR"; then
        echo -e "${BLUE}>> Cloning paru repository...${RESET}"
        git clone https://aur.archlinux.org/paru-bin.git || { echo -e "${BLUE}>> Failed to clone paru repository.${RESET}"; exit 1; }
    else
        echo -e "${BLUE}>> Paru repository already exists. Skipping clone.${RESET}"
    fi

    # Change to the paru directory
    cd "$PARU_DIR" || { echo -e "${BLUE}>> Failed to navigate to paru directory.${RESET}"; exit 1; }

    # Build and install paru
    echo -e "${BLUE}>> Building and installing paru...${RESET}"
    makepkg -si --noconfirm || { echo -e "${BLUE}>> Failed to build/install paru.${RESET}"; exit 1; }
fi

echo -e "${BLUE}>> Function completed!${RESET}"

