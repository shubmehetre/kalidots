#!/bin/sh
# Kali setup script inspired by larbs.sh

set -e

# Variables
PASSWORD_STORE_REPO="shubmehetre/password-store"
DOTFILES_REPO="shubmehetre/dotfiles"
PASSWORD_STORE_DIR="$HOME/.local/share/password-store"
DOTFILES_DIR="$HOME/.local/share/dotfiles"
KALIDOTS_DIR="$HOME/kalidots"

# Package list
PACKAGES="lf ueberzug bc dosfstools nsxiv xwallpaper neovim ncmpcpp fonts-jetbrains-mono \
ncdu alacritty ripgrep jq qbittorrent obsidian syncthing pass manpages foliate \
zathura mpv newsboat"

update_system() {
    echo "[*] Updating system..."
    sudo apt update && sudo apt -y upgrade
}

install_packages() {
    echo "[*] Installing packages..."
    sudo apt install -y $PACKAGES
}

install_github_cli() {
    echo "[*] Installing GitHub CLI..."
    sudo apt install -y gh

    if ! gh auth status &>/dev/null; then
        echo "[*] GitHub authentication required..."
        gh auth login
    else
        echo "[*] Already authenticated with GitHub."
    fi
}

install_password_store() {
    echo "[*] Setting up password-store..."
    if [ ! -d "$PASSWORD_STORE_DIR" ]; then
        gh repo clone "$PASSWORD_STORE_REPO" "$PASSWORD_STORE_DIR"
    else
        echo "[*] Password-store already exists, pulling latest..."
        git -C "$PASSWORD_STORE_DIR" pull
    fi
}

install_dotfiles() {
    echo "[*] Cloning dotfiles..."
    if [ ! -d "$DOTFILES_DIR" ]; then
        gh repo clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    else
        echo "[*] Dotfiles already cloned, pulling latest..."
        git -C "$DOTFILES_DIR" pull
    fi

    echo "[*] Copying dotfiles into home directory..."
    rsync -av --exclude='.git' "$DOTFILES_DIR"/ "$HOME"/

    echo "[*] Creating symlinks..."
    ln -sf "$KALIDOTS_DIR/keyboard-shortcuts" \
        "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml"
    ln -sf "$KALIDOTS_DIR/wm-shortcuts" \
        "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml"
    ln -sf "$KALIDOTS_DIR/.tmux.conf" "$HOME/.tmux.conf"

    echo "[*] Dotfiles installed and symlinks created."
}

generate_ssh_keys() {
	ssh-keygen -t ed25519 -C "your_email@example.com"
	cat ~/.ssh/id_ed25519.pub
}

post_install_message() {
    echo
    echo "------------------------------------------------------"
    echo " Setup complete!"
    echo " IMP:  Import your GPG keys for the password manager."
    echo " - Password-store cloned to: $PASSWORD_STORE_DIR"
    echo " - Dotfiles cloned to: $DOTFILES_DIR"
    echo " - Symlinks created for the WM and Keyboard shortcuts"
    echo " - ADD below key to Github"
    echo "------------------------------------------------------"
    cat ~/.ssh/id_ed25519.pub
}

main() {
    update_system
    install_packages
    install_github_cli
    install_password_store
    install_dotfiles
    post_install_message
}

main "$@"
