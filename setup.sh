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

    case "$pm" in
        apt)
            install_pkgs "$pm" \
                build-essential git meson ninja-build pkg-config cmake \
                wayland-protocols libwayland-dev libxkbcommon-dev \
                libinput-dev libdrm-dev libpixman-1-dev \
                libxcb1-dev libxcb-util-dev libxcb-ewmh-dev \
                libxcb-icccm4-dev libxcb-errors-dev \
                libseat-dev libcairo2-dev libpango1.0-dev \
                libpam0g-dev xwayland mate-polkit curl
            ;;
        dnf)
            install_pkgs "$pm" \
                @development-tools git meson ninja pkgconf cmake \
                wayland-devel wayland-protocols-devel libxkbcommon-devel \
                libinput-devel libdrm-devel pixman-devel \
                libxcb-devel xcb-util-devel xcb-util-wm-devel \
                xcb-util-errors-devel seatd-devel \
                cairo-devel pango-devel pam-devel \
                xorg-x11-server-Xwayland mate-polkit curl
            ;;
        pacman)
            install_pkgs "$pm" \
                base-devel git meson ninja pkgconf cmake curl \
                wayland wayland-protocols wlroots \
                libxkbcommon libinput libdrm pixman \
                libxcb xcb-util xcb-util-wm xcb-util-errors \
                libseat cairo pango pam \
                xorg-xwayland mate-polkit
            ;;
        zypper)
            install_pkgs "$pm" -t pattern devel_basis
            install_pkgs "$pm" \
                git meson ninja pkg-config cmake curl \
                wayland-devel wayland-protocols-devel wlroots-devel \
                libxkbcommon-devel libinput-devel libdrm-devel \
                pixman-devel libxcb-devel xcb-util-devel \
                xcb-util-wm-devel seatd-devel \
                cairo-devel pango-devel pam-devel \
                xwayland mate-polkit
            ;;
    esac
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
    if cmd starship; then
        log "Starship already installed"
        return
    fi

    log "Installing Starship"
    mkdir -p "$HOME/.local/bin"
    curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
    log "Starship installed"
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
            log "Installing Noctalia (Arch/AUR)"
            if cmd paru; then
                paru -S --needed --noconfirm noctalia-shell
            elif cmd yay; then
                yay -S --needed --noconfirm noctalia-shell
            else
                warn "No AUR helper found. Install manually."
            fi
            ;;
        dnf)
            log "Installing Noctalia (Fedora via Terra repo)"

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
            warn "Automatic Noctalia install not supported on this distro."
            ;;
    esac
}

########################################
# SDDM + Astronaut
########################################
install_sddm_astronaut() {
    local pm="$1"

    log "Checking display manager status..."

    current_dm=""
    if [[ -L /etc/systemd/system/display-manager.service ]]; then
        current_dm="$(readlink -f /etc/systemd/system/display-manager.service)"
    fi

    if [[ -n "$current_dm" ]]; then
        log "A display manager is already configured."

        if cmd sddm; then
            log "SDDM already installed."
        else
            read -rp "Install SDDM alongside existing display manager? [y/N]: " ans
            [[ "$ans" =~ ^[Yy]$ ]] || { log "Skipping SDDM install."; return; }
            install_pkgs "$pm" sddm
        fi
    else
        log "No display manager detected."
        read -rp "Would you like to install SDDM? [y/N]: " ans
        [[ "$ans" =~ ^[Yy]$ ]] || { log "Skipping SDDM install."; return; }
        install_pkgs "$pm" sddm
    fi

    if ! cmd sddm; then
        log "SDDM not installed. Skipping Astronaut theme setup."
        return
    fi

    log "Installing SDDM Astronaut theme"

    tmp="$(mktemp -d)"
    git clone --depth=1 https://github.com/Keyitdev/sddm-astronaut-theme "$tmp/astronaut"

    if [[ -f "$tmp/astronaut/setup.sh" ]]; then
        chmod +x "$tmp/astronaut/setup.sh"
        $SUDO "$tmp/astronaut/setup.sh"
    else
        warn "Astronaut setup script not found"
    fi

    rm -rf "$tmp"
}

########################################
# Symlinks
########################################
link_path() {
    local src="$1"
    local dest="$2"

    [[ -e "$src" ]] || { warn "Source not found: $src"; return; }

    mkdir -p "$(dirname "$dest")"

    if [[ -e "$dest" && ! -L "$dest" ]]; then
        warn "Backing up existing $dest"
        mv "$dest" "$dest.bak.$(date +%s)"
    fi

    ln -sf "$src" "$dest"
    log "Linked $dest → $src"
}

link_configs() {
    log "Linking dotfiles"

    link_path "$SCRIPT_DIR/mango" "$HOME/.config/mango"
    link_path "$SCRIPT_DIR/kitty" "$HOME/.config/kitty"
    link_path "$SCRIPT_DIR/rofi" "$HOME/.config/rofi"
    link_path "$SCRIPT_DIR/starship.toml" "$HOME/.config/starship.toml"
}

########################################
# Main
########################################
main() {
    pm="$(detect_pkg_manager)"
    distro="$(detect_distro)"

    log "Detected package manager: $pm"
    log "Detected distro: $distro"

    if [[ "$distro" == "arch" || "$distro" == "fedora" ]]; then
        log "Full automated support enabled for this distro."
    else
        print_support_notice
        confirm_continue
    fi

    install_dependencies "$pm"
    install_mangowc
    install_starship
    install_noctalia "$pm"
    install_sddm_astronaut "$pm"
    link_configs

    log "Setup complete."
}

main "$@"
