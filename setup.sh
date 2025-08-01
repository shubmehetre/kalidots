#!/bin/bash

##############################
######### How to Use##########
##############################
# This script is used to setup Kali related profiles, configs and keymaps
# After you spin up a new Kali instance just, run this script.

# Exit on error
set -e

# Install required packages
echo "Installing required packages..."
sudo apt install -y git zsh alacritty

# Clone or update the dotfiles repository
DOTFILES_DIR="$HOME/kalidots"
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "Cloning dotfiles repository..."
    git clone https://github.com/shubmehetre/kalidots.git "$DOTFILES_DIR"
else
    echo "Updating existing dotfiles repository..."
    git -C "$DOTFILES_DIR" pull
fi

# Create required directories
mkdir -p "$HOME/.config/zsh"
mkdir -p "$HOME/.config/alacritty"

# Symlink configuration files
echo "Symlinking configuration files..."
ln -sf "$DOTFILES_DIR/.zprofile" "$HOME/.zprofile"
ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.config/zsh/.zshrc"
ln -sf "$DOTFILES_DIR/keyboard-shortcuts" "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml"
ln -sf "$DOTFILES_DIR/wm-shortcuts" "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml"
#ln -sf "$DOTFILES_DIR/.xprofile" "$HOME/.xprofile"
ln -sf "$DOTFILES_DIR/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
ln -sf "$DOTFILES_DIR/remaps" "$HOME/.local/remaps"
ln -sf "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"

# Disable LightDM and set default target to multi-user mode
echo "Disabling LightDM and setting multi-user target..."
sudo systemctl set-default multi-user.target
sudo systemctl disable lightdm

# Cache dir for zsh
mkdir -p $HOME/.cache/zsh
touch $HOME/.cache/history

echo "Setup complete! You may need to reboot for changes to take effect."

