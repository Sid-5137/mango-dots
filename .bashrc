#!/usr/bin/env bash

# ==============================================================================
# BASHRC CONFIGURATION
# Originally sourced aliases/scripts by zachbrowne.me
# Refactored for readability and maintainability
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. INITIAL SETUP & GLOBAL SOURCING
# ------------------------------------------------------------------------------

# Test if the shell is interactive (used later to wrap interactive-only commands)
iatest=$(expr index "$-" i)

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# Enable bash programmable completion features in interactive shells
if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

# ------------------------------------------------------------------------------
# 2. ENVIRONMENT VARIABLES & PATH
# ------------------------------------------------------------------------------

# Setup custom PATH
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.local/share/flatpak/exports/bin:/var/lib/flatpak/exports/bin:$PATH"

# Set up XDG Base Directory specification folders
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"

# Set default text editors
export EDITOR=nvim
export VISUAL=nvim

# Set QT theme environment variable
export QT_QPA_PLATFORMTHEME=qt6ct

# Custom directory export for other scripts
export LINUXTOOLBOXDIR="$HOME/linuxtoolbox"

# ------------------------------------------------------------------------------
# 3. SHELL OPTIONS & HISTORY MANAGEMENT
# ------------------------------------------------------------------------------

# Expand the history size and add timestamps
export HISTFILESIZE=10000
export HISTSIZE=500
export HISTTIMEFORMAT="%F %T "

# Ignore duplicate commands and commands starting with a space in history
export HISTCONTROL=erasedups:ignoredups:ignorespace

# Append to history instead of overwriting (preserves history across multiple terminals)
shopt -s histappend

# Save history immediately after each command
PROMPT_COMMAND='history -a'

# Automatically check and update window size (LINES and COLUMNS) after each command
shopt -s checkwinsize

# ------------------------------------------------------------------------------
# 4. KEYBINDINGS & COMPLETION BEHAVIOR
# ------------------------------------------------------------------------------

# Disable the annoying terminal bell
if [[ $iatest -gt 0 ]]; then bind "set bell-style visible"; fi

# Allow ctrl-S for history navigation (alongside ctrl-R)
[[ $- == *i* ]] && stty -ixon

# Ignore case on auto-completion
if [[ $iatest -gt 0 ]]; then bind "set completion-ignore-case on"; fi

# Show auto-completion list automatically, without needing a double tab
if [[ $iatest -gt 0 ]]; then bind "set show-all-if-ambiguous On"; fi

# Bind Ctrl+f to insert 'zi' followed by a newline (interactive shell only)
if [[ $- == *i* ]]; then
    bind '"\C-f":"zi\n"'
fi

# ------------------------------------------------------------------------------
# 5. UI, COLORS, & PROMPT
# ------------------------------------------------------------------------------

# Enable colors for ls and grep commands
export CLICOLOR=1
export LS_COLORS='no=00:fi=00:di=00;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:*.xml=00;31:'

# Custom colors for manpages (makes them easier to read in 'less')
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

# Initialize Starship prompt
eval "$(starship init bash)"

# ------------------------------------------------------------------------------
# 6. SYSTEM ALIASES
# ------------------------------------------------------------------------------
# Note: To temporarily bypass an alias, precede the command with a backslash (\ls)

# Core utilities overrides
alias cp='cp -i'                # Prompt before overwrite
alias mv='mv -i'                # Prompt before overwrite
alias rm='trash -v'             # Send to trash instead of permanent deletion
alias mkdir='mkdir -p'          # Create parent directories as needed
alias ps='ps auxf'              # Detailed process tree
alias ping='ping -c 10'         # Limit ping to 10 packets
alias less='less -R'            # Parse ANSI color escape sequences
alias cls='clear'               # DOS-style clear command

# File Editing
alias spico='sudo pico'
alias snano='sudo nano'
alias vim='nvim'
alias vi='nvim'
alias svi='sudo vi'
alias vis='nvim "+set si"'

# Package Management
alias apt-get='sudo apt-get'
alias yayf="yay -Slq | fzf --multi --preview 'yay -Sii {1}' --preview-window=down:75% | xargs -ro yay -S"

# Directory Navigation
alias home='cd ~'
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias bd='cd "$OLDPWD"'         # Go back to previous directory

# Directory Listing (ls variants)
alias ls='ls -aFh --color=always' # Base ls: all, formatted, human-readable, colored
alias la='ls -Alh'                # All (no . or ..), long, human-readable
alias lx='ls -lXBh'               # Sort by extension
alias lk='ls -lSrh'               # Sort by size (reverse)
alias lc='ls -ltcrh'              # Sort by change time
alias lu='ls -lturh'              # Sort by access time
alias lr='ls -lRh'                # Recursive listing
alias lt='ls -ltrh'               # Sort by date (reverse)
alias lm='ls -alh |more'          # Pipe through more
alias lw='ls -xAh'                # Wide listing
alias ll='ls -Fls'                # Long listing
alias labc='ls -lap'              # Alphabetical sort
alias lf="ls -l | egrep -v '^d'"  # Files only
alias ldir="ls -l | egrep '^d'"   # Directories only
alias lla='ls -Al'                # List + Hidden
alias las='ls -A'                 # Hidden only
alias lls='ls -l'                 # Long list

# Permissions (chmod)
alias mx='chmod a+x'
alias 000='chmod -R 000'
alias 644='chmod -R 644'
alias 666='chmod -R 666'
alias 755='chmod -R 755'
alias 777='chmod -R 777'

# File & Directory Operations
alias rmd='/bin/rm --recursive --force --verbose' # Force remove dir
alias countfiles="for t in files links directories; do echo \`find . -type \${t:0:1} | wc -l\` \$t; done 2> /dev/null"
alias diskspace="du -S | sort -n -r |more"
alias folders='du -h --max-depth=1'
alias folderssort='find . -maxdepth 1 -type d -print0 | xargs -0 du -sk | sort -rn'
alias tree='tree -CAhF --dirsfirst'
alias treed='tree -CAFd'
alias mountedinfo='df -hT'

# Archives
alias mktar='tar -cvf'
alias mkbz2='tar -cvjf'
alias mkgz='tar -cvzf'
alias untar='tar -xvf'
alias unbz2='tar -xvjf'
alias ungz='tar -xvzf'

# System Tools & Network
alias p="ps aux | grep "                                      # Search processes
alias topcpu="/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10"
alias h="history | grep "                                     # Search history
alias f="find . | grep "                                      # Search files
alias openports='netstat -nape --inet'                        # View open ports
alias whatismyip="whatsmyip"                                  # IP lookup function alias
alias rebootsafe='sudo shutdown -r now'
alias rebootforce='sudo shutdown -r -n now'
alias logs="sudo find /var/log -type f -exec file {} \; | grep 'text' | cut -d' ' -f1 | sed -e's/:$//g' | grep -v '[0-9]$' | xargs tail -f"
alias multitail='multitail --no-repeat -c'
alias freshclam='sudo freshclam'
alias sha1='openssl sha1'

# Environment & Utility Aliases
alias ebrc='edit ~/.bashrc'                                   # Edit bashrc
alias hlp='less ~/.bashrc_help'                               # Show bashrc help
alias da='date "+%Y-%m-%d %A %T %Z"'                          # Formatted date
alias checkcommand="type -t"                                  # Determine if command is alias/file/builtin
alias clickpaste='sleep 3; xdotool type "$(xclip -o -selection clipboard)"'
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Python / Conda
alias activate='conda activate'
alias deactivate='conda deactivate'

# User-Specific / Project Aliases
alias src="cd $HOME/mango-dots/"
alias web='cd /var/www/html'
alias linutil="curl -fsSL christitus.com/linux | sh"

# Systemctl Aliases
# alias hug="systemctl --user restart hugo"
# alias lanm="systemctl --user restart lan-mouse"

# SSH / Remote
# alias SERVERNAME='ssh YOURWEBSITE.com -l USERNAME -p PORTNUMBERHERE'
alias kssh="kitty +kitten ssh" # Use Kitty features remotely (e.g., tmux integration)

# Docker
alias docker-clean=' \
  docker container prune -f ; \
  docker image prune -f ; \
  docker network prune -f ; \
  docker volume prune -f '

# Mounts (Requires Root)
# mount -o loop /home/NAMEOFISO.iso /home/ISOMOUNTDIR/
# umount /home/NAMEOFISO.iso

# ------------------------------------------------------------------------------
# 7. TOOL CONFIGURATION LOGIC (Grep, Bat, etc.)
# ------------------------------------------------------------------------------

# Intelligent Grep Aliasing (Use ripgrep if available)
if command -v rg &> /dev/null; then
    alias grep='rg'
else
    alias grep="/usr/bin/grep $GREP_OPTIONS"
fi
unset GREP_OPTIONS

# ------------------------------------------------------------------------------
# 8. FUNCTIONS
# ------------------------------------------------------------------------------

# Extract any common archive format automatically
extract() {
    for archive in "$@"; do
        if [ -f "$archive" ]; then
            case $archive in
            *.tar.bz2) tar xvjf $archive ;;
            *.tar.gz) tar xvzf $archive ;;
            *.bz2) bunzip2 $archive ;;
            *.rar) rar x $archive ;;
            *.gz) gunzip $archive ;;
            *.tar) tar xvf $archive ;;
            *.tbz2) tar xvjf $archive ;;
            *.tgz) tar xvzf $archive ;;
            *.zip) unzip $archive ;;
            *.Z) uncompress $archive ;;
            *.7z) 7z x $archive ;;
            *) echo "don't know how to extract '$archive'..." ;;
            esac
        else
            echo "'$archive' is not a valid file!"
        fi
    done
}

# Search for text within all files in current folder using grep
ftext() {
    # -i: case-insensitive, -I: ignore binary, -H: print filename
    # -r: recursive, -n: print line number
    grep -iIHrn --color=always "$1" . | less -r
}

# Copy file with a terminal progress bar (requires strace)
cpp() {
    set -e
    strace -q -ewrite cp -- "${1}" "${2}" 2>&1 |
    awk '{
        count += $NF
        if (count % 10 == 0) {
            percent = count / total_size * 100
            printf "%3d%% [", percent
            for (i=0;i<=percent;i++)
                printf "="
            printf ">"
            for (i=percent;i<100;i++)
                printf " "
            printf "]\r"
        }
    }
    END { print "" }' total_size="$(stat -c '%s' "${1}")" count=0
}

# Copy file and immediately navigate to destination directory
cpg() {
    if [ -d "$2" ]; then
        cp "$1" "$2" && cd "$2"
    else
        cp "$1" "$2"
    fi
}

# Move file and immediately navigate to destination directory
mvg() {
    if [ -d "$2" ]; then
        mv "$1" "$2" && cd "$2"
    else
        mv "$1" "$2"
    fi
}

# Create a directory and immediately navigate into it
mkdirg() {
    mkdir -p "$1"
    cd "$1"
}

# Go up a specified number of directories (e.g., 'up 4')
up() {
    local d=""
    limit=$1
    for ((i = 1; i <= limit; i++)); do
        d=$d/..
    done
    d=$(echo $d | sed 's/^\///')
    if [ -z "$d" ]; then
        d=..
    fi
    cd $d
}

# Automatically run 'ls' after a 'cd' command
cd() {
    if [ -n "$1" ]; then
        builtin cd "$@" && ls
    else
        builtin cd ~ && ls
    fi
}

# Return the last 2 fields of the working directory (e.g., parent/current)
pwdtail() {
    pwd | awk -F/ '{nlast = NF -1;print $nlast"/"$NF}'
}

# Find internal and external IP addresses
function whatsmyip () {
    # Internal IP Lookup
    if command -v ip &> /dev/null; then
        echo -n "Internal IP: "
        ip addr show wlan0 | grep "inet " | awk '{print $2}' | cut -d/ -f1
    else
        echo -n "Internal IP: "
        ifconfig wlan0 | grep "inet " | awk '{print $2}'
    fi
    # External IP Lookup
    echo -n "External IP: "
    curl -4 ifconfig.me
}

# Trim leading and trailing spaces from strings (useful in scripts)
trim() {
    local var=$*
    var="${var#"${var%%[![:space:]]*}"}" # remove leading whitespace
    var="${var%"${var##*[![:space:]]}"}" # remove trailing whitespace
    echo -n "$var"
}

# Git Quick Actions
gcom() {
    git add .
    git commit -m "$1"
}

gp() {
    git add .
    git commit -m "$1" || return
    git push
}

ghnew() {
    git init
    git add .
    git commit -m "Initial commit"
    gh repo create "$(basename "$PWD")" --source=. --public --push
}

# Online Bin (Upload file to paste.rs)
hb() {
    if [ $# -eq 0 ] || [ ! -f "$1" ]; then
        echo "Usage: hb <filename>"
        echo "Error: File not found or not specified."
        return 1
    fi
    curl -sL --data-binary @"$1" https://paste.rs/
    echo 
}

# ------------------------------------------------------------------------------
# 9. SERVER CONFIGURATION & LOGGING FUNCTIONS
# ------------------------------------------------------------------------------

# View Apache logs with multitail
apachelog() {
    if [ -f /etc/httpd/conf/httpd.conf ]; then
        cd /var/log/httpd && ls -xAh && multitail --no-repeat -c -s 2 /var/log/httpd/*_log
    else
        cd /var/log/apache2 && ls -xAh && multitail --no-repeat -c -s 2 /var/log/apache2/*.log
    fi
}

# Edit Apache configuration dynamically finding the file
apacheconfig() {
    if [ -f /etc/httpd/conf/httpd.conf ]; then
        sedit /etc/httpd/conf/httpd.conf
    elif [ -f /etc/apache2/apache2.conf ]; then
        sedit /etc/apache2/apache2.conf
    else
        echo "Error: Apache config file could not be found."
        echo "Searching for possible locations:"
        sudo updatedb && locate httpd.conf && locate apache2.conf
    fi
}

# Edit PHP configuration dynamically finding the file
phpconfig() {
    if [ -f /etc/php.ini ]; then
        sedit /etc/php.ini
    elif [ -f /etc/php/php.ini ]; then
        sedit /etc/php/php.ini
    elif [ -f /etc/php5/php.ini ]; then
        sedit /etc/php5/php.ini
    elif [ -f /usr/bin/php5/bin/php.ini ]; then
        sedit /usr/bin/php5/bin/php.ini
    elif [ -f /etc/php5/apache2/php.ini ]; then
        sedit /etc/php5/apache2/php.ini
    else
        echo "Error: php.ini file could not be found."
        echo "Searching for possible locations:"
        sudo updatedb && locate php.ini
    fi
}

# Edit MySQL configuration dynamically finding the file
mysqlconfig() {
    if [ -f /etc/my.cnf ]; then
        sedit /etc/my.cnf
    elif [ -f /etc/mysql/my.cnf ]; then
        sedit /etc/mysql/my.cnf
    elif [ -f /usr/local/etc/my.cnf ]; then
        sedit /usr/local/etc/my.cnf
    elif [ -f /usr/bin/mysql/my.cnf ]; then
        sedit /usr/bin/mysql/my.cnf
    elif [ -f ~/my.cnf ]; then
        sedit ~/my.cnf
    elif [ -f ~/.my.cnf ]; then
        sedit ~/.my.cnf
    else
        echo "Error: my.cnf file could not be found."
        echo "Searching for possible locations:"
        sudo updatedb && locate my.cnf
    fi
}

# ------------------------------------------------------------------------------
# 10. OS DETECTION & COMPATIBILITY
# ------------------------------------------------------------------------------

# Function to safely detect the current Linux distribution
distribution () {
    local dtype="unknown"
    if [ -r /etc/os-release ]; then
        source /etc/os-release
        case $ID in
            fedora|rhel|centos) dtype="redhat" ;;
            sles|opensuse*)     dtype="suse" ;;
            ubuntu|debian)      dtype="debian" ;;
            gentoo)             dtype="gentoo" ;;
            arch|manjaro)       dtype="arch" ;;
            slackware)          dtype="slackware" ;;
            *)
                if [ -n "$ID_LIKE" ]; then
                    case $ID_LIKE in
                        *fedora*|*rhel*|*centos*) dtype="redhat" ;;
                        *sles*|*opensuse*)        dtype="suse" ;;
                        *ubuntu*|*debian*)        dtype="debian" ;;
                        *gentoo*)                 dtype="gentoo" ;;
                        *arch*)                   dtype="arch" ;;
                        *slackware*)              dtype="slackware" ;;
                    esac
                fi
                ;;
        esac
    fi
    echo $dtype
}

# Set alias for 'bat' depending on package name in specific distros
DISTRIBUTION=$(distribution)
if [ "$DISTRIBUTION" = "redhat" ] || [ "$DISTRIBUTION" = "arch" ]; then
    alias cat='bat'
else
    alias cat='batcat'
fi 

# Show the current version of the operating system
ver() {
    local dtype
    dtype=$(distribution)

    case $dtype in
        "redhat")
            if [ -s /etc/redhat-release ]; then cat /etc/redhat-release; else cat /etc/issue; fi
            uname -a
            ;;
        "suse")      cat /etc/SuSE-release ;;
        "debian")    lsb_release -a ;;
        "gentoo")    cat /etc/gentoo-release ;;
        "arch")      cat /etc/os-release ;;
        "slackware") cat /etc/slackware-version ;;
        *)
            if [ -s /etc/issue ]; then cat /etc/issue; else echo "Error: Unknown distribution"; exit 1; fi
            ;;
    esac
}

# Automatically install required support files based on distribution
install_bashrc_support() {
    local dtype
    dtype=$(distribution)

    case $dtype in
        "redhat")
            sudo yum install multitail tree zoxide trash-cli fzf bash-completion fastfetch
            ;;
        "suse")
            sudo zypper install multitail tree zoxide trash-cli fzf bash-completion fastfetch
            ;;
        "debian")
            sudo apt-get install multitail tree zoxide trash-cli fzf bash-completion
            FASTFETCH_URL=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | grep "browser_download_url.*linux-amd64.deb" | cut -d '"' -f 4)
            curl -sL $FASTFETCH_URL -o /tmp/fastfetch_latest_amd64.deb
            sudo apt-get install /tmp/fastfetch_latest_amd64.deb
            ;;
        "arch")
            yay -S  multitail tree zoxide trash-cli fzf bash-completion fastfetch
            ;;
        "slackware")
            echo "No install support for Slackware"
            ;;
        *)
            echo "Unknown distribution"
            ;;
    esac
}

# ------------------------------------------------------------------------------
# 11. TOOL INITIALIZATION (Zoxide, Conda)
# ------------------------------------------------------------------------------

# Initialize Zoxide
eval "$(zoxide init bash)"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/sid/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/sid/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/home/sid/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/sid/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Auto start ssh-agent and load keys
if ! ssh-add -l >/dev/null 2>&1; then
    eval "$(ssh-agent -s)" >/dev/null
    ssh-add >/dev/null 2>&1
fi
