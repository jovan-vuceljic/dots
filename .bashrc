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
alias ls="lsd"
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

PS1='[\u@\h \W]\$' 
set -o vi

eval "$(zoxide init --cmd cd bash)"
