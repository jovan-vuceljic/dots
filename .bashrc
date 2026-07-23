#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return


# Shorts (mirrored from fish config)
alias grep='grep --color=auto'
alias fzf="fzf --multi --preview 'bat --style=numbers --color=always {}' | xargs -n 1 nvim"
alias fm='yazi'
alias mem='df -H --output=source,size,used,avail | grep 480G | sort -u'
alias kittyimg='kitten icat'
alias xremaps='sudo xremap ~/.config/xremap/config.yml'
alias copy='wl-copy'
alias cat='bat -p'
alias mkdir='mkdir -p'
alias lsusb='cyme'
alias lg='lazygit'
alias tts='tt -notheme -bold -showwpm -json'

# Git
alias gs='git status --short'
alias gis='git status'
alias gca='git add -p . && git commit'
alias gd='git diff --word-diff'
alias gl='git log --graph --show-signature'
alias gla='git log --all --decorate --oneline --graph'
alias gls='serie'
alias gm='git merge'

# Dirs / projects
alias cdots='cd ~/.dotfiles/.config/'
alias dots='cd ~/.dotfiles/.config/ && nvim'
alias keybinds='cd ~/.dotfiles/.config/ && nvim ./hypr/keybindings.conf'
alias aliases='bat ~/.bashrc'
alias wnotes='cd ~/sync/notes && nvim'
alias todo='cd ~/sync/notes/wm-client/ && nvim todo.md'
alias scrp='cd ~/projects/scripts/'
alias currdir='cd ~/projects/wingman/wm-clients/c2/'
alias current='currdir && nvim'
alias tilesrv='cd /home/coja/software/wmclient/ && ./martin ./mapfiles/data -W 4 --font ./mapfiles/fonts'
alias startsim='cd ~/software/wmclient/ && ./wmsimulator.sh'
alias blocks='~/Documents/Blocks/LinuxNoEditor/Blocks.sh -windowed -RenderOffscreen'
alias llamacpp='~/projects/random-clones/llama.cpp/build/bin/llama-server --alias Qwen3-Coder-30B-Instruct-XXS --jinja --ctx-size 8192 --temp 1.0 --top-p 0.95 --min-p 0.01 --port 11343 -m ~/Documents/models/Qwen3-Coder-30B-A3B-Instruct-UD-IQ2_XXS.gguf'

# List Directory
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'

# Handy change dir shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'

# System
alias pacs='sudo pacman -Syu --noconfirm'
alias yays='yay --noconfirm --sudoloop'
alias nmaps='sudo nmap -sn 192.168.0.0/24'
alias vpn='sudo wg-quick up wg0'
alias vpnhome='sudo wg-quick up wg0'
alias vpnoff='sudo wg-quick down wg0'
alias ipadd='sudo ip route add 192.168.0.1 dev wg0'

# Powerline prompt, synthwave palette (needs a Nerd Font for the glyphs)
PROMPT_DIRTRIM=3
__pl_sep=$'\ue0b0'    # powerline triangle
__pl_branch=$'\ue0a0' # branch glyph
__pl_seg() { # $1=bg $2=fg $3=text  (colors as "R;G;B")
    [[ -n $__pl_bg ]] && PS1+="\[\e[38;2;${__pl_bg};48;2;${1}m\]${__pl_sep}\[\e[0m\]"
    PS1+="\[\e[48;2;${1};38;2;${2}m\] ${3} \[\e[0m\]"
    __pl_bg=$1
}
__pl_end() {
    PS1+="\[\e[38;2;${__pl_bg}m\]${__pl_sep}\[\e[0m\] "
    __pl_bg=''
}
__prompt() {
    local s=$?
    # muted synthwave: segment colors pre-blended ~40% onto the terminal bg
    # (#262335) so they read as semi-transparent overlays
    local fg='205;200;220'
    local purple='67;56;93' green='65;107;99' yellow='114;100;67'
    local red='124;39;52' pink='122;71;77'
    PS1="\[\e]0;\w\a\]"
    __pl_bg=''
    [[ -n $SSH_TTY ]] && __pl_seg "$pink" "$fg" '\u@\h'
    __pl_seg "$purple" "$fg" '\w'
    local b
    if b=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --contains --all HEAD 2>/dev/null); then
        if [[ -n $(git status --porcelain 2>/dev/null | head -n1) ]]; then
            __pl_seg "$yellow" "$fg" "${__pl_branch} ${b} ✱"
        else
            __pl_seg "$green" "$fg" "${__pl_branch} ${b}"
        fi
    fi
    ((s != 0)) && __pl_seg "$red" "$fg" "✘ ${s}"
    [[ $EUID == 0 ]] && __pl_seg "$red" "$fg" '#'
    __pl_end
}
PROMPT_COMMAND=__prompt

set -o vi

# eval "$(zoxide init --cmd cd bash)"
