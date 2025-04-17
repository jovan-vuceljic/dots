set -gx EDITOR nvim
set -gx PAGER less
# set -Ux BAT_THEME gruvbox
set -Ux MANPAGER "nvim +Man!"
set -g fish_greeting
set -g fish_cursor_insert line
set -g fish_cursor_default block
set -g fish_cursor_visual underscore
set -g fish_user_key_bindings
set -g ask

set -gx PNPM_HOME "/home/coja/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end

#set -xU MANPAGER 'less -R --use-color -Dd+r -Du+b'
#set -xU MANROFFOPT '-P -c'

alias grep="grep --color=auto"
alias fzf="fzf --preview color='always {}'"
alias pacs="sudo pacman -Syu"
alias nmaps="sudo nmap -sn 192.168.0.0/24"
alias mem="df -H --output=source,size,used,avail | grep 480G | sort -u"
alias kittyimg="kitten icat"
alias dmz="cat  ~/.config/fish/dmz.txt"
alias xremaps="sudo xremap ~/.config/xremap/config.yml"
alias vpnhome="sudo wg-quick up wg0"
# alias llama="~/projects/llama.cpp/build/bin/llama-server -m /home/anon/projects/llama.cpp/models/Llama-3.2-3B-Instruct-F16.gguf"
alias cdots="cd ~/.dotfiles/.config/"
alias dots="cd ~/.dotfiles/.config/ && nvim"
alias keybinds="cd ~/.dotfiles/.config/ && nvim ./hypr/keybindings.conf"
alias aliases="bat ~/.config/fish/config.fish"
alias notes="cd ~/sync/notes && nvim"
alias ipadd="sudo ip route add 192.168.0.1 dev wg0"
alias copy="wl-copy"
alias current="cd ~/projects/wingman/website/ && nvim"

# List Directory
alias ls="lsd"
alias l="ls -l"
alias la="ls -a"
alias lla="ls -la"
alias lt="ls --tree"

# Git
alias gs="git status"
alias gca="git add -p . && git commit"
alias gd="git diff --word-diff"
alias gl="git log --graph --show-signature"
alias gla="git log --all --decorate --oneline --graph"
alias gm="git merge"

# Handy change dir shortcuts
abbr .. "cd .."
abbr ... "cd ../.."
abbr .3 "cd ../../.."
abbr .4 "cd ../../../.."
abbr .5 "cd ../../../../.."

# Always mkdir a path (this doesn't inhibit functionality to make a single dir)
abbr mkdir "mkdir -p"

abbr pwwa "~/projects/wingman/website/src/assets/"
abbr scrp "~/projects/scripts/"

zoxide init --cmd cd fish | source


# pnpm
set -gx PNPM_HOME "/home/coja/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
