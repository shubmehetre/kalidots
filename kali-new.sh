#!/usr/bin/env bash
set -euo pipefail

# Kali setup script (hyprland-free variant)
# - NO hyprland, NO waybar
# - install ghostty via snap (if available)
# - install keyd and enable it
# - create zsh symlinks (as requested)
# - skip yazi install

# === Configurable variables ===
DOTFILES_REPO="https://github.com/shubmehetre/hyprdots.git"
DOTFILES_DIR="$HOME/.local/share/dotfiles"
KALIDOTS_DIR="$HOME/kalidots"

# Minimal apt package list (Kali/Debian-ish). Edit to taste.
# NOTE: Some hyprland-specific packages are omitted intentionally
APT_PACKAGES=(
  git curl wget build-essential jq ripgrep neovim fzf
  mpv mpd ncmpcpp wl-clipboard
  fonts-jetbrains-mono swayimg pavucontrol
  keyd nwg-displays  # keyd available in Debian repos; nwg-displays may be in newer repos
  xdg-desktop-portal # helpful generally
  less man-db unzip p7zip-full
  pass syncthing qbittorrent
  # utilities
  bc btop fd-find tree kali-community-wallpapers
)

echo "[*] Running Kali setup..."

update_system() {
  echo "[*] updating apt..."
  sudo apt update
  sudo apt full-upgrade -y
}

install_apt_packages() {
  echo "[*] installing apt packages..."
  sudo apt install -y "${APT_PACKAGES[@]}" || {
    echo "[!] apt install had issues — try rerunning or install missing packages manually."
  }
}

# ========== Install snap related packages ==========
install_snap_packages() {
  echo "[*] Installing snapd (if missing) and Ghostty via snap..."
  if ! command -v snap >/dev/null 2>&1; then
    sudo apt install -y snapd || {
      echo "[!] Could not install snapd via apt. Install snapd manually."
      return 1
    }
    # enable snapd (systemd)
    sudo systemctl enable --now snapd.socket || true
    # ensure classic support if needed
    sudo ln -sf /var/lib/snapd/snap /snap 2>/dev/null || true
  fi

  # Try to install ghostty via snap (if present in snap store)
  if snap find ghostty >/dev/null 2>&1; then
    sudo snap install ghostty --classic || {
      echo "[!] snap install ghostty failed — you can build ghostty from source later."
    }
  else
    echo "[!] Ghostty snap not found by 'snap find'.  You may need to build Ghostty from source."
  fi
}

# ========== Keyd remaps ==========
setup_keyd() {
  echo "[*] Installing and enabling keyd..."
  if ! dpkg -s keyd >/dev/null 2>&1; then
    sudo apt install -y keyd || {
      echo "[!] keyd not available via apt - you'll need to build/install manually from https://github.com/rvaiya/keyd"
      return 1
    }
  fi

  sudo systemctl enable --now keyd.service || {
    echo "[!] failed to enable keyd.service — check systemd status for errors"
  }

  # example default config symlink to XDG-friendly home
  if [ ! -f /etc/keyd/default.conf ] && [ -f "$HOME/.config/keyd/default.conf" ]; then
    sudo ln -sf "$HOME/.config/keyd/default.conf" /etc/keyd/default.conf
  fi
}

# ========== get cofigs from hyprdots ==========
clone_and_deploy_dotfiles() {
  echo "[*] Cloning dotfiles (if not present)..."
  if [ ! -d "$DOTFILES_DIR" ]; then
    git clone --depth 1 "$DOTFILES_REPO" "$DOTFILES_DIR" || {
      echo "[!] failed to clone dotfiles repo: $DOTFILES_REPO"
    }
  else
    echo "[*] Dotfiles already present — pulling..."
    git -C "$DOTFILES_DIR" pull --ff-only || true
  fi

  echo "[*] copying relevant dotfiles (home/...)"
  rsync -av --no-perms --no-owner --no-group --exclude='.git' "$DOTFILES_DIR/home/doom/" "$HOME/" || true
}

# ========== zsh related symlinks ==========
create_zsh_symlinks() {
  echo "[*] Creating zsh symlinks"
  # user requested:

  # rm ${HOME}/.profile && rm ${HOME}/.profile

  ln -sf "${HOME}/.config/zsh/.profile" "${HOME}/.zprofile" || true
  ln -sf "${HOME}/.config/zsh/.zshrc" "${HOME}/.zshrc" || true
}

# ========== Enable required services ==========
enable_services_user() {
  echo "[*] enabling user services (mpd, syncthing if installed)..."
  # enable mpd (user)
  # if command -v mpd >/dev/null 2>&1; then
  #   systemctl --user enable --now mpd || true
  # fi
  # syncthing
  # if command -v syncthing >/dev/null 2>&1; then
  #   systemctl --user enable --now syncthing || true
  # fi
}

# ========== create symlinks for XFCE (from kalidots) ==========
echo "[*] Creating XFCE symlinks (keyboard/wm shortcuts)..."
mkdir -p "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/"
# adjust the source paths below if your repo structure differs
if [ -f "$KALIDOTS_DIR/keyboard-shortcuts" ]; then
  ln -sf "$KALIDOTS_DIR/keyboard-shortcuts" "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml"
fi
if [ -f "$KALIDOTS_DIR/wm-shortcuts" ]; then
  ln -sf "$KALIDOTS_DIR/wm-shortcuts" "$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml"
fi
if [ -f "$KALIDOTS_DIR/.tmux.conf" ]; then
  ln -sf "$KALIDOTS_DIR/.tmux.conf" "$HOME/.tmux.conf"
fi

# ========== Make zsh the default shell (interactive) ==========
ZSH_PATH="$(command -v zsh || true)"
if [ -n "$ZSH_PATH" ]; then
  if [ "$SHELL" != "$ZSH_PATH" ]; then
    echo "[*] Setting zsh as default shell for $USER (may prompt for password)..."
    sudo chsh -s "$ZSH_PATH" "$USER" || echo "[!] chsh failed - run 'sudo chsh -s $ZSH_PATH $USER' manually"
  else
    echo "[*] zsh is already the default shell."
  fi
fi

post_install_summary() {
  cat <<EOF

Done. Summary / Next steps:

- Packages attempted via apt: ${APT_PACKAGES[*]}
- Ghostty: attempted to install via snap (if snap store has a ghostty snap).
- keyd: installed and enabled (systemd service). This is for Capslock setup
- Dotfiles: cloned to $DOTFILES_DIR and copied into $HOME (rsync).
- zsh symlinks created: ~/.zprofile -> ~/.config/zsh/.profile, ~/.zshrc -> ~/.config/zsh/.zshrc
- symlinks for XFCE added.

Caveats / manual followups:
  * Some packages (AUR or Arch specific) are not in apt — you will need to build or find Debian packages:
    - tokyonight-gtk-theme-git (AUR)
  * If ghostty snap wasn't available, build ghostty from source per Ghostty docs.
  * DOWNLOAD Nerd fonts manually
  * If you want system-wide keyd config symlinked to ~/.config/keyd, copy it yourself or leave as /etc/keyd/default.conf
  * You may want to re-login for snapd/path changes to take effect.

EOF
}

main() {
  update_system
  install_apt_packages
  install_snap_packages
  setup_keyd
  clone_and_deploy_dotfiles
  create_zsh_symlinks
  # enable_services_user
  post_install_summary
}

main "$@"
