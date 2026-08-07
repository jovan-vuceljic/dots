#
# ~/.bashrc  (shared; host-specific bits in ~/.bashrc.host)
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# fzf's built-in walker ignores .ignore files; fd honours them. Mirrors config.fish.
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix'

# Mirrors the aliases + abbrs in .config/fish/config.fish (see README). fish abbrs only
# expand at the prompt; here they are plain aliases, which is as close as bash gets.
# Keep the two in step — if you add one there, add it here.
alias exti=exit
alias grep='grep --color=auto'
alias cat="bat -p"
alias untar="tar -xf"
alias copy="wl-copy"
alias img="kitten icat"
alias fm="yazi"
alias lg="lazygit"
alias mkdir="mkdir -p"
alias pacs="sudo pacman -Syu --noconfirm"
alias yays="yay --noconfirm --sudoloop"
alias nmaps="sudo nmap -sn 192.168.0.0/24"
alias faillock="sudo faillock --reset"
alias xremaps="sudo xremap ~/.config/xremap/config.yml"
alias dots="cd ~/.dotfiles/.config/ && nvim"
alias keybinds="cd ~/.dotfiles/.config/ && nvim ./hypr/keybindings.conf"
alias aliases="bat ~/.config/fish/config.fish"
alias dmz="cat ~/.config/fish/dmz.txt"
alias nmatrix="neo-matrix -DS 3"
alias tts="tt -notheme -bold -showwpm -json"
alias tuioss="tuios --show-clock --show-keys --show-cpu --show-ram --confirm-quit"
alias fzf="fzf --preview 'bat --color=always {}'"
alias fzff="fzf --multi --preview 'bat --style=numbers --color=always {}' | xargs -n 1 nvim"
alias gcommit="git diff HEAD | aichat -r commit"
alias aichatdel="rm ~/.config/aichat/sessions/*.yaml"

# Network
alias ipadd="sudo ip route add 192.168.0.234 dev wg0"
alias vpnhome="sudo wg-quick up wg0"
alias vpnkralizec="sudo wg-quick up kralizec-wg0"
alias vpnsumadija="sudo wg-quick up sumadija-wg0"

# scrcpy
alias scrcpyc='scrcpy -wSK -m 1920 --window-borderless --always-on-top --power-off-on-close'
alias scrcpys='scrcpy -wS --power-off-on-close'
alias scrcpyz='scrcpy -wSK -m 1920 --window-borderless --always-on-top --power-off-on-close --no-audio'

# List directory — `ls` must be aliased first or `lt` falls through to coreutils ls,
# which has no --tree. bash re-expands the first word of an alias, so l/la/lla/lt
# all pick up eza from here.
alias ls='eza --icons --group-directories-first'
alias l="ls -l"
alias la="ls -a"
alias lla="ls -la"
alias lt="ls --tree"

# Git
alias gti="git"
alias gs='git status'
alias gca='git add -p . && git commit'
alias gd="git diff --word-diff"
alias gl='git log --graph --show-signature'
alias glog="git log --all --decorate --oneline --color --graph"
alias gla="git log --all --decorate --oneline"
alias gls="serie"
alias gm='git merge'

# wm-only (paths exist on this box; drop them if this file ever moves to another host)
alias tilesrv="cd /home/coja/software/wmclient/ && ./martin ./mapfiles/data -W 4 --font ./mapfiles/fonts"
alias blocks="~/Documents/Blocks/LinuxNoEditor/Blocks.sh -windowed -RenderOffscreen"
alias cur="cd ~/projects/wingman/wm-clients/c2/c2-main"
alias c2m="cd ~/projects/wingman/wm-clients/c2/c2-main"
alias c2b="cd ~/projects/wingman/wm-clients/c2/c2-building"
alias todo="cd ~/sync/notes/wm-client/ && nvim todo.md"

# Up N directories
alias ..="cd .."
alias ...="cd ../.."
alias .3="cd ../../.."
alias .4="cd ../../../.."
alias .5="cd ../../../../.."

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

# colorized --help
h() { "$@" --help 2>&1 | bat --plain --language=help; } 

# Record lookup against the local dmz db (adjust the db path to this machine)
lk(){
	local DB="$HOME/projects/dmz/soft/lk/db.rec"
	passes=0 count=0; until [ "$count" -eq "1" ] || [ "$passes" -gt 2 ] ; do \
		query="$(recsel "$DB" -p aim,tag | recsel -iq "$query" -CP aim,tag | sort -u | fzf --preview="recsel \"$DB\" -e \"aim~{}\"")" \
		&& count="$(recsel "$DB" -q "$query" -c )" ;\
		passes=$(( passes + 1 )) ;\
	done \
	&& recsel "$DB" -q "$query" | recfmt -f "$HOME/projects/dmz/soft/lk/lists.fmt" | less
}

# Per-host extras
[ -f ~/.bashrc.host ] && . ~/.bashrc.host
