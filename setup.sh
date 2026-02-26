#!/usr/bin/env bash
set -Eeuo pipefail

########################################
# Paths
########################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANGOWC_REPO="${MANGOWC_REPO:-https://github.com/mangowc/mango}"
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
INSTALL_MODE="symlink"   # symlink | copy

########################################
# Utils
########################################
cmd() { command -v "$1" >/dev/null 2>&1; }

detect_pkg_manager() {
    cmd apt-get && { echo apt; return; }
    cmd dnf     && { echo dnf; return; }
    cmd pacman  && { echo pacman; return; }
    cmd zypper  && { echo zypper; return; }
    err "No supported package manager found"
}

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

########################################
# Support Notice
########################################
print_support_notice() {
cat <<'EOF'

========================================================
MangoWC Setup Script – Distro Support Notice
========================================================
✔ Fully automated support:
  - Arch Linux
  - Fedora

⚠ Partial support:
  - Debian / Ubuntu / openSUSE / others

Noctalia automated install works only on:
  - Arch (AUR)
  - Fedora (Terra repo)

Manual guide:
https://docs.noctalia.dev/getting-started/installation/

========================================================

EOF
}

confirm_continue() {
    read -rp "This distro is not fully supported. Continue anyway? [y/N]: " ans
    case "$ans" in
        y|Y) ;;
        *) log "Aborting setup."; exit 1 ;;
    esac
}

########################################
# Preference Prompts
########################################
ask_shell_config() {
    echo
    echo "Shell Configuration"
    echo "--------------------"
    read -rp "Use provided .bashrc and Starship config? [y/N]: " ans
    case "$ans" in
        y|Y)
            USE_SHELL_CONFIG=true
            log "Shell configuration enabled."
            ;;
        *)
            log "Skipping shell configuration."
            ;;
    esac
}

ask_install_mode() {
    echo
    echo "Dotfile Installation Mode"
    echo "--------------------------"
    echo "1) Symlink (recommended)"
    echo "2) Copy files (standalone)"
    read -rp "Choose installation mode [1/2]: " ans

    case "$ans" in
        2)
            INSTALL_MODE="copy"
            log "Using COPY mode."
            ;;
        *)
            INSTALL_MODE="symlink"
            log "Using SYMLINK mode."
            ;;
    esac
}

########################################
# Package Install Helper
########################################
install_pkgs() {
    local pm="$1"; shift
    case "$pm" in
        apt)
            $SUDO apt-get update
            $SUDO apt-get install -y "$@"
            ;;
        dnf)
            $SUDO dnf install -y "$@"
            ;;
        pacman)
            $SUDO pacman -Sy --needed --noconfirm "$@"
            ;;
        zypper)
            $SUDO zypper --non-interactive install "$@"
            ;;
    esac
}

########################################
# Dependencies
########################################
install_dependencies() {
    local pm="$1"
    log "Installing MangoWC dependencies ($pm)"
    install_pkgs "$pm" git curl meson ninja cmake pkg-config
}

########################################
# MangoWC
########################################
install_mangowc() {
    if cmd mangowc || cmd mango; then
        log "MangoWC already installed"
        return
    fi

    log "Building MangoWC from source"
    tmp="$(mktemp -d)"
    git clone --depth=1 "$MANGOWC_REPO" "$tmp/mango"
    (
        cd "$tmp/mango"
        meson setup build
        ninja -C build
        $SUDO ninja -C build install
    )
    rm -rf "$tmp"
}

########################################
# Starship
########################################
install_starship() {
    [[ "$USE_SHELL_CONFIG" == "true" ]] || return

    if cmd starship; then
        log "Starship already installed"
        return
    fi

    log "Installing Starship"
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
    local pm="$1"

    if cmd noctalia-shell; then
        log "Noctalia already installed"
        return
    fi

    case "$pm" in
        pacman)
            if cmd yay; then
                yay -S --needed --noconfirm noctalia-shell
            elif cmd paru; then
                paru -S --needed --noconfirm noctalia-shell
            else
                warn "No AUR helper found."
            fi
            ;;
        dnf)
            if ! rpm -q terra-release >/dev/null 2>&1; then
                $SUDO dnf install -y \
                  --nogpgcheck \
                  --repofrompath="terra,https://repos.fyralabs.com/terra\$releasever" \
                  terra-release
            fi
            $SUDO dnf makecache -y
            install_pkgs "$pm" noctalia-shell
            ;;
        *)
            warn "Noctalia auto-install unsupported on this distro."
            ;;
    esac
}

########################################
# SDDM + Astronaut
########################################
install_sddm_astronaut() {
    local pm="$1"

    current_dm=""
    if [[ -L /etc/systemd/system/display-manager.service ]]; then
        current_dm="$(readlink -f /etc/systemd/system/display-manager.service)"
    fi

    if [[ -n "$current_dm" ]]; then
        log "Display manager detected."
        if ! cmd sddm; then
            read -rp "Install SDDM alongside existing DM? [y/N]: " ans
            [[ "$ans" =~ ^[Yy]$ ]] || return
            install_pkgs "$pm" sddm
        fi
    else
        read -rp "No display manager found. Install SDDM? [y/N]: " ans
        [[ "$ans" =~ ^[Yy]$ ]] || return
        install_pkgs "$pm" sddm
    fi

    if ! cmd sddm; then
        return
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
# Install Path (Symlink or Copy)
########################################
install_path() {
    local src="$1"
    local dest="$2"

    [[ -e "$src" ]] || { warn "Source not found: $src"; return; }

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
        log "Copied $src → $dest"
    else
        ln -sf "$src" "$dest"
        log "Linked $dest → $src"
    fi
}

link_configs() {
    install_path "$SCRIPT_DIR/mango" "$HOME/.config/mango"
    install_path "$SCRIPT_DIR/kitty" "$HOME/.config/kitty"
    install_path "$SCRIPT_DIR/rofi" "$HOME/.config/rofi"

    if [[ "$USE_SHELL_CONFIG" == "true" ]]; then
        install_path "$SCRIPT_DIR/starship.toml" "$HOME/.config/starship.toml"
    fi
}

########################################
# Main
########################################
main() {
    pm="$(detect_pkg_manager)"
    distro="$(detect_distro)"

    log "Detected package manager: $pm"
    log "Detected distro: $distro"

    if [[ "$distro" != "arch" && "$distro" != "fedora" ]]; then
        print_support_notice
        confirm_continue
    fi

    ask_shell_config
    ask_install_mode

    install_dependencies "$pm"
    install_mangowc
    install_starship
    install_noctalia "$pm"
    install_sddm_astronaut "$pm"
    install_bashrc
    link_configs

    log "Setup complete."
}

main "$@"
