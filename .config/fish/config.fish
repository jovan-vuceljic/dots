# Disable XOFF/XON flow control so Ctrl+s can be used for other things
stty -ixon

# Bind Ctrl+s to the function in all modes (default, search, etc.)
bind --mode default \cs copy-commandline
bind --mode insert \cs copy-commandline
bind --mode search \cs copy-commandline

set -gx EDITOR nvim
set -gx PAGER less
set -gx QT_FONT_DPI 96
set -gx PI_SKIP_VERSION_CHECK 1
set -gx OPENCODE_CONFIG "$HOME/.config/opencode/openai-gpt.jsonc"
set -gx MANPAGER "nvim +Man!"
set -gx NEWT_COLORS 'root=black,black;window=black,black;border=white,black;listbox=white,black;label=blue,black;checkbox=red,black;title=green,black;button=white,red;actsellistbox=white,red;actlistbox=white,gray;compactbutton=white,gray;actcheckbox=white,blue;entry=lightgray,black;textbox=blue,black' # themes nmtui
# set -gx BAT_THEME "Catppuccin Mocha"

# Cursor / greeting
set -g fish_greeting
set -g fish_cursor_insert line
set -g fish_cursor_default block
set -g fish_cursor_visual underscore

# Misc
alias exti=exit
alias dmz="cat ~/.config/fish/dmz.txt"
alias nmatrix="neo-matrix -DS 3"
alias grep="grep --color=auto"
alias fzf="fzf --preview 'bat --color=always {}'"
alias fzff="fzf --multi --preview 'bat --style=numbers --color=always {}' | xargs -n 1 nvim"
abbr scrcpyz 'scrcpy -wSK -m 1920 --window-borderless --always-on-top --power-off-on-close --no-audio'

# Git
alias gti="git"
alias gs="git status"
alias gca="git add -p . && git commit"
alias gd="git diff --word-diff"
alias gl="git log --graph --show-signature"
alias glog="git log --all --decorate --oneline --color --graph"
alias gla="git log --all --decorate --oneline"
alias gls="serie"
alias gm="git merge"

alias tilesrv="cd /home/coja/software/wmclient/ && ./martin ./mapfiles/data -W 4 --font ./mapfiles/fonts"
alias blocks="~/Documents/Blocks/LinuxNoEditor/Blocks.sh -windowed -RenderOffscreen"
alias cur="cd ~/projects/wingman/wm-clients/c2/c2-main"
alias c2m="cd ~/projects/wingman/wm-clients/c2/c2-main"
alias c2b="cd ~/projects/wingman/wm-clients/c2/c2-building"
abbr todo "cd ~/sync/notes/wm-client/ && nvim todo.md"

# List directory
alias ls='eza --icons --group-directories-first'
alias l="ls -l"
alias la="ls -a"
alias lla="ls -la"
alias lt="ls --tree"

# Dotfiles + notes
alias dots="cd ~/.dotfiles/.config/ && nvim"
abbr aliases "bat ~/.config/fish/config.fish"

# Handy
abbr cat "bat -p"
abbr untar "tar -xf"
abbr copy wl-copy
abbr img "kitten icat"
abbr fm yazi
abbr lg lazygit
abbr gcommit "git diff HEAD | aichat -r commit"
abbr aichatdel "rm ~/.config/aichat/sessions/*.yaml"
abbr mkdir "mkdir -p"
abbr faillock "sudo faillock --reset"
abbr xremaps "sudo xremap ~/.config/xremap/config.yml"
abbr pacs "sudo pacman -Syu --noconfirm"
abbr yays "yay --noconfirm --sudoloop"
abbr nmaps "sudo nmap -sn 192.168.0.0/24"
abbr scrcpyc 'scrcpy -wSK -m 1920 --window-borderless --always-on-top --power-off-on-close'
abbr scrcpys 'scrcpy -wS --power-off-on-close'
abbr tts "tt -notheme -bold -showwpm -json"
abbr tuioss "tuios --show-clock --show-keys --show-cpu --show-ram --confirm-quit"
abbr keybinds "cd ~/.dotfiles/.config/ && nvim ./hypr/keybindings.conf"
abbr vpnhome "sudo wg-quick up wg0"
abbr vpnkralizec "sudo wg-quick up kralizec-wg0"
abbr vpnsumadija "sudo wg-quick up sumadija-wg0"
abbr ipadd "sudo ip route add 192.168.0.234 dev wg0"

# Change-dir shortcuts
abbr .. "cd .."
abbr ... "cd ../.."
abbr .3 "cd ../../.."
abbr .4 "cd ../../../.."
abbr .5 "cd ../../../../.."

# Tool init (fnm is initialized once in conf.d/fnm.fish — don't source it again here)
zoxide init --cmd cd fish | source
fish_add_path $HOME/.cargo/bin $HOME/.local/bin

# thefuck, lazy-loaded on first use (its --alias eval costs ~170ms of shell startup)
function fuck
    functions -e fuck
    thefuck --alias | source
    fuck $argv
end

# pnpm
set -gx PNPM_HOME "$HOME/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end

# Per-host extras
test -f ~/.config/fish/host.fish; and source ~/.config/fish/host.fish
