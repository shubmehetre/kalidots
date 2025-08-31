#!/bin/sh
# Kali setup script inspired by larbs.sh

set -e

# Variables
DOTFILES_REPO="shubmehetre/dotfiles"
DOTFILES_DIR="$HOME/.local/share/dotfiles"
KALIDOTS_DIR="$HOME/kalidots"

# Package list
PACKAGES="lf ueberzug bc dosfstools nsxiv xwallpaper neovim ncmpcpp fonts-jetbrains-mono \
ncdu fzf eza alacritty ripgrep jq qbittorrent obsidian syncthing pass manpages foliate \
zathura mpv newsboat"
# REplace these with proper packages some can be kept as is the x server related. But i want ghostty, yazi instead

update_system() {
  echo "[*] Updating system..."
  sudo apt update && sudo apt -y upgrade
}

install_packages() {
  echo "[*] Installing packages..."
  sudo apt install -y $PACKAGES
}

get_hyprdots() {
  echo "[*] Cloning dotfiles..."
  if [ ! -d "$DOTFILES_DIR" ]; then
    # clone https://github.com/shubmehetre/hyprdots
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
  ssh-keygen -t ed25519 -C "kalivm@example.com"
  cat ~/.ssh/id_ed25519.pub
}

post_install_message() {
  echo
  echo "------------------------------------------------------"
  echo " Setup complete!"
  echo " IMP:  Import your GPG keys for the password manager."
  echo " - Dotfiles cloned to: $DOTFILES_DIR"
  echo " - Symlinks created for the WM and Keyboard shortcuts"
  echo " - ADD below key to Github"
  echo "------------------------------------------------------"
  cat ~/.ssh/id_ed25519.pub
}

main() {
  update_system
  install_packages
  get_hyprdots
  post_install_message
}

main "$@"
