set -gx EDITOR nvim
set -gx PAGER less
set -Ux MANPAGER "nvim +Man!"
set -x NEWT_COLORS 'root=black,black;window=black,black;border=white,black;listbox=white,black;label=blue,black;checkbox=red,black;title=green,black;button=white,red;actsellistbox=white,red;actlistbox=white,gray;compactbutton=white,gray;actcheckbox=white,blue;entry=lightgray,black;textbox=blue,black' nmtui
# set -gx BAT_THEME "Catppuccin Mocha"

# Shorts
alias fzf="fzf --multi --preview 'bat --style=numbers --color=always {}' | xargs -n 1 nvim"
alias grep="grep --color=auto"

# Git
alias gs="git status --short"
alias gca="git add -p . && git commit"
alias gd="git diff --word-diff"
alias gl="git log --graph --show-signature"
alias gla="git log --all --decorate --oneline --graph"
alias gls="serie"
alias gm="git merge"
alias gm="git merge"

alias cdots="cd ~/.dotfiles/.config/"
alias dots="cd ~/.dotfiles/.config/ && nvim"
alias keybinds="cd ~/.dotfiles/.config/ && nvim ./hypr/keybindings.conf"
alias aliases="bat ~/.config/fish/config.fish"
alias wnotes="cd ~/sync/notes && nvim"
alias fm="yazi"

alias tilesrv="cd /home/coja/software/wmclient/ && ./martin ./mapfiles/data -W 4 --font ./mapfiles/fonts"
alias blocks="~/Documents/Blocks/LinuxNoEditor/Blocks.sh -windowed -RenderOffscreen"
alias currdir="cd ~/projects/wingman/wm-clients/c2/"
alias current="currdir && nvim"
abbr todo "cd ~/sync/notes/wm-client/ && nvim todo.md"

# List Directory
alias ls="lsd"
alias l="ls -l"
alias la="ls -a"
alias lla="ls -la"
alias lt="ls --tree"

# Git
alias gs="git status --short"
alias gd="git diff --word-diff"
alias gl="git log --graph --show-signature"
alias gla="git log --all --decorate --oneline --graph"
alias gls="serie"

# Handy change dir shortcuts
abbr .. "cd .."
abbr ... "cd ../.."
abbr .3 "cd ../../.."
abbr .4 "cd ../../../.."
abbr .5 "cd ../../../../.."
abbr tts "tt -notheme -bold -showwpm -json"
abbr lsusb "cyme"

abbr vpnhome "sudo wg-quick up wg0"
abbr ipadd "sudo ip route add 192.168.0.1 dev wg0"
abbr copy "wl-copy"
abbr cat "bat -p"
abbr mkdir "mkdir -p"
abbr pacs "sudo pacman -Syu --noconfirm"
abbr yays "yay --noconfirm --sudoloop"
abbr nmaps "sudo nmap -sn 192.168.0.0/24"
abbr lg "lazygit"
abbr llamacpp " ~/projects/random-clones/llama.cpp/build/bin/llama-server --alias Qwen3-Coder-30B-Instruct-XXS --jinja --ctx-size 8192 --temp 1.0 --top-p 0.95 --min-p 0.01  --port 11343  -m ~/Documents/models/Qwen3-Coder-30B-A3B-Instruct-UD-IQ2_XXS.gguf"
# abbr llamacpp "~/projects/random-clones/llama.cpp/build/bin/llama-server --port 11343 --host 192.168.0.204 --models-max 3 --models-preset /home/coja/.config/llamacpp/config.ini"

abbr pwwa "~/projects/wingman/website/src/assets/"
abbr scrp "~/projects/scripts/"
abbr startsim "cd ~/software/wmclient/ && ./wmsimulator.sh"

zoxide init --cmd cd fish | source
export PATH="$HOME/.cargo/bin:$PATH"
thefuck --alias | source

# Created by `pipx` on 2025-05-31 20:14:06
set PATH $PATH /home/anon/.local/bin

# pnpm
set -gx PNPM_HOME "/home/coja/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

