#!/usr/bin/env bash
set -Eeuo pipefail

########################################
# Paths
########################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUDO="$(command -v sudo >/dev/null 2>&1 && echo sudo || echo '')"

########################################
# Logging
########################################
log()  { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*"; }
err()  { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

########################################
# User Preferences
########################################
USE_SHELL_CONFIG=false
INSTALL_MODE="symlink"
USE_TERMINAL_DOTS=false

########################################
# Utils
########################################
cmd() { command -v "$1" >/dev/null 2>&1; }

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

########################################
# Arch/Fedora Guard
########################################
check_supported_distro() {
    distro="$(detect_distro)"
    log "Detected distro: $distro"

    if [[ "$distro" != "arch" && "$distro" != "fedora" ]]; then
        err "This installer supports only Arch Linux and Fedora."
    fi
}

########################################
# Preference Prompts
########################################
ask_shell_config() {
    read -rp "Use provided .bashrc and Starship config? [y/N]: " ans
    [[ "$ans" =~ ^[Yy]$ ]] && USE_SHELL_CONFIG=true
}

ask_install_mode() {
    echo
    echo "Installation mode:"
    echo "1) Symlink"
    echo "2) Copy"
    read -rp "Choose [1/2]: " ans

    [[ "$ans" == "2" ]] && INSTALL_MODE="copy"

    if [[ "$INSTALL_MODE" == "symlink" ]]; then
        log "Symlink mode selected."
        log "Configs will reference:"
        log "$SCRIPT_DIR"
    fi
}

ask_terminal_dots() {
    read -rp "Use provided Kitty and Rofi configs? [y/N]: " ans
    [[ "$ans" =~ ^[Yy]$ ]] && USE_TERMINAL_DOTS=true
}

########################################
# Install Helpers
########################################
install_arch_repo_then_aur() {
    local pkg_repo="$1"
    local pkg_aur="${2:-$1}"

    # Try pacman first
    if $SUDO pacman -Sy --needed --noconfirm "$pkg_repo" 2>/dev/null; then
        log "Installed $pkg_repo via pacman."
        return 0
    fi

    warn "Pacman failed. Trying AUR..."

    if cmd yay; then
        yay -S --needed --noconfirm "$pkg_aur"
    elif cmd paru; then
        paru -S --needed --noconfirm "$pkg_aur"
    else
        err "No AUR helper found (yay/paru required)."
    fi
}

install_fedora() {
    $SUDO dnf install -y "$@"
}

########################################
# MangoWC
########################################
install_mangowc() {
    if cmd mangowc || cmd mango; then
        log "MangoWC already installed"
        return
    fi

    if [[ "$(detect_distro)" == "arch" ]]; then
        install_arch_repo_then_aur mangowc mangowc-git
    else
        install_fedora mangowc
    fi
}

########################################
# Starship
########################################
install_starship() {
    [[ "$USE_SHELL_CONFIG" == "true" ]] || return

    if cmd starship; then
        return
    fi

    mkdir -p "$HOME/.local/bin"
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
}

install_bashrc() {
    [[ "$USE_SHELL_CONFIG" == "true" ]] || return
    install_path "$SCRIPT_DIR/.bashrc" "$HOME/.bashrc"
}

########################################
# Noctalia
########################################
install_noctalia() {
    if cmd noctalia-shell; then
        return
    fi

    if [[ "$(detect_distro)" == "arch" ]]; then
        install_arch_repo_then_aur noctalia-shell
    else
        if ! rpm -q terra-release >/dev/null 2>&1; then
            $SUDO dnf install -y \
              --nogpgcheck \
              --repofrompath="terra,https://repos.fyralabs.com/terra\$releasever" \
              terra-release
        fi
        $SUDO dnf makecache -y
        install_fedora noctalia-shell
    fi
}

########################################
# SDDM + Astronaut
########################################
install_sddm_astronaut() {
    current_dm=""
    if [[ -L /etc/systemd/system/display-manager.service ]]; then
        current_dm="$(readlink -f /etc/systemd/system/display-manager.service)"
    fi

    if [[ -n "$current_dm" ]]; then
        if ! cmd sddm; then
            read -rp "Install SDDM alongside existing DM? [y/N]: " ans
            [[ "$ans" =~ ^[Yy]$ ]] || return
        fi
    else
        read -rp "No display manager found. Install SDDM? [y/N]: " ans
        [[ "$ans" =~ ^[Yy]$ ]] || return
    fi

    if [[ "$(detect_distro)" == "arch" ]]; then
        $SUDO pacman -Sy --needed --noconfirm sddm
    else
        install_fedora sddm
    fi

    tmp="$(mktemp -d)"
    git clone --depth=1 https://github.com/Keyitdev/sddm-astronaut-theme "$tmp/astronaut"
    if [[ -f "$tmp/astronaut/setup.sh" ]]; then
        chmod +x "$tmp/astronaut/setup.sh"
        $SUDO "$tmp/astronaut/setup.sh"
    fi
    rm -rf "$tmp"
}

########################################
# Install Path
########################################
install_path() {
    local src="$1"
    local dest="$2"

    [[ -e "$src" ]] || { warn "Missing: $src"; return; }

    mkdir -p "$(dirname "$dest")"

    if [[ -e "$dest" && ! -L "$dest" ]]; then
        mv "$dest" "$dest.bak.$(date +%s)"
    fi

    if [[ "$INSTALL_MODE" == "copy" ]]; then
        if [[ -d "$src" ]]; then
            cp -r "$src" "$dest"
        else
            cp "$src" "$dest"
        fi
    else
        ln -sf "$src" "$dest"
    fi
}

########################################
# Link Configs
########################################
link_configs() {
    install_path "$SCRIPT_DIR/mango" "$HOME/.config/mango"

    if [[ "$USE_TERMINAL_DOTS" == "true" ]]; then
        install_path "$SCRIPT_DIR/kitty" "$HOME/.config/kitty"
        install_path "$SCRIPT_DIR/rofi" "$HOME/.config/rofi"
    fi

    if [[ "$USE_SHELL_CONFIG" == "true" ]]; then
        install_path "$SCRIPT_DIR/starship.toml" "$HOME/.config/starship.toml"
    fi
}

########################################
# Main
########################################
main() {
    check_supported_distro
    ask_shell_config
    ask_terminal_dots
    ask_install_mode

    install_mangowc
    install_starship
    install_noctalia
    install_sddm_astronaut
    install_bashrc
    link_configs

    log "Setup complete."
}

main "$@"
