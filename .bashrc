#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return


alias grep='grep --color=auto'
alias fzf="fzf --preview color='always {}'"
alias pacs="sudo pacman -Syu"
alias nmaps="sudo nmap -sn 192.168.0.0/24"
alias mem="df -H --output=source,size,used,avail | grep 480G | sort -u"
alias kittyimg="kitten icat"
alias vpn="sudo wg-quick up wg0"
alias vpnoff="sudo wg-quick down wg0"
alias xremaps="sudo xremap ~/.config/xremap/config.yml"
alias llama="~/projects/llama.cpp/build/bin/llama-server -m /home/anon/projects/llama.cpp/models/Llama-3.2-3B-Instruct-F16.gguf"
alias dots="cd ~/.dotfiles/.config/ && nvim"
alias aliases="bat ~/.config/fish/config.fish"

# List Directory
# alias ls="lsd"
alias l="ls -l"
alias la="ls -a"
alias lla="ls -la"
alias lt="ls --tree"

# Git
alias gs='git status'
alias gca='git add -p . && git commit'
alias gd="git diff --word-diff"
alias gl='git log --graph --show-signature'
alias gla="git log --all --decorate --oneline --graph"
alias gm='git merge'
alias gis='git status'

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
    local purple='97;77;133' dark='38;35;53' white='255;255;255'
    local green='114;241;184' yellow='254;222;93' red='254;68;80' pink='249;126;114'
    PS1="\[\e]0;\w\a\]"
    __pl_bg=''
    [[ -n $SSH_TTY ]] && __pl_seg "$pink" "$dark" '\u@\h'
    __pl_seg "$purple" "$white" '\w'
    local b
    if b=$(git symbolic-ref --short HEAD 2>/dev/null || git describe --contains --all HEAD 2>/dev/null); then
        if [[ -n $(git status --porcelain 2>/dev/null | head -n1) ]]; then
            __pl_seg "$yellow" "$dark" "${__pl_branch} ${b} ✱"
        else
            __pl_seg "$green" "$dark" "${__pl_branch} ${b}"
        fi
    fi
    ((s != 0)) && __pl_seg "$red" "$white" "✘ ${s}"
    [[ $EUID == 0 ]] && __pl_seg "$red" "$white" '#'
    __pl_end
}
PROMPT_COMMAND=__prompt

set -o vi

# eval "$(zoxide init --cmd cd bash)"
