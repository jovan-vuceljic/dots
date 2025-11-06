set -gx EDITOR nvim
set -gx PAGER less
set -Ux MANPAGER "nvim +Man!"
set -g fish_greeting
set -g fish_cursor_insert line
set -g fish_cursor_default block
set -g fish_cursor_visual underscore
set -g fish_user_key_bindings
set -g ask
set -g tuis
set -x NEWT_COLORS 'root=black,black;window=black,black;border=white,black;listbox=white,black;label=blue,black;checkbox=red,black;title=green,black;button=white,red;actsellistbox=white,red;actlistbox=white,gray;compactbutton=white,gray;actcheckbox=white,blue;entry=lightgray,black;textbox=blue,black' nmtui
# set -Ux BAT_THEME gruvbox

#set -xU MANPAGER 'less -R --use-color -Dd+r -Du+b'
#set -xU MANROFFOPT '-P -c'

# alias fzf="fzf --preview color='always {}'"
# alias llama="~/projects/llama.cpp/build/bin/llama-server -m /home/anon/projects/llama.cpp/models/Llama-3.2-3B-Instruct-F16.gguf"
alias grep="grep --color=auto"
alias img="kitten icat"
alias dmz="cat  ~/.config/fish/dmz.txt"

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
alias gg="serie"
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
abbr tts "tt -notheme -bold -showwpm -json"

abbr vpnhome "sudo wg-quick up wg0"
abbr ipadd "sudo ip route add 192.168.0.1 dev wg0"
abbr copy "wl-copy"
abbr cat "vimcat"
abbr mkdir "mkdir -p"
abbr pacs "sudo pacman -Syu --noconfirm"
abbr yays "yay --noconfirm --sudoloop"
abbr nmaps "sudo nmap -sn 192.168.0.0/24"
abbr lg "lazygit"
abbr llamacpp "~/projects/random-clones/llama.cpp/build/bin/llama-server --port 11343 -m ~/projects/random-clones/llama.cpp/models/Qwen3-Coder-30B-A3B-Instruct-UD-IQ2_XXS.gguf"

abbr pwwa "~/projects/wingman/website/src/assets/"
abbr scrp "~/projects/scripts/"

zoxide init --cmd cd fish | source

# pnpm
set -gx PNPM_HOME "/home/coja/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

