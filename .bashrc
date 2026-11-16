#
# ~/.bashrc  (shared; host-specific bits in ~/.bashrc.host)
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# fzf's built-in walker ignores .ignore files; fd honours them. Mirrors config.fish.
export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix'

alias grep='grep --color=auto'
alias fzf="fzf --preview 'bat --color=always {}'"
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
alias dots="cd ~/.dots/ && nvim"
alias aliases="bat ~/.config/fish/config.fish"
alias ipadd="sudo ip route add 192.168.0.234 dev wg0"

# List directory
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

alias exti=exit
alias cat="bat -p"
alias untar="tar -xf"
alias keybinds="nvim ~/.dots/.config/hypr/binds.lua"
alias dmz="cat ~/.config/fish/dmz.txt"
alias nmatrix="neo-matrix -DS 3"
alias tts="tt -notheme -bold -showwpm -json"
alias fzff="fzf --multi --preview 'bat --style=numbers --color=always {}' | xargs -n 1 nvim"

# Network
alias vpnhome="sudo wg-quick up wg0"
alias vpnkralizec="sudo wg-quick up kralizec-wg0"
alias vpnsumadija="sudo wg-quick up sumadija-wg0"

# scrcpy
alias scrcpyc='scrcpy -wSK -m 1920 --window-borderless --always-on-top --power-off-on-close'
alias scrcpys='scrcpy -wS --power-off-on-close'
alias scrcpyz='scrcpy -wSK -m 1920 --window-borderless --always-on-top --power-off-on-close --no-audio'

# `ls` must be aliased to eza or `lt` (above) falls through to coreutils ls, which has
# no --tree. bash re-expands the first word of an alias, so l/la/lla/lt all pick up eza.
alias ls='eza --icons --group-directories-first'

# Git extras
alias gti="git"
alias glog="git log --all --decorate --oneline --color --graph"
alias gls="serie"

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
eval "$(fzf --bash)"
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

# Keepassxc search
kp() {
  local DB="${KP_DB:?Error: KP_DB environment variable is not set. Check .bash_profile.}"
  read -sp "Enter db password: " pass; echo ""; printf '%s\n' "$pass" | keepassxc-cli ls -q -R "$DB" | fzf | (read -r entry; printf '%s\n' "$pass" | keepassxc-cli clip -q "$DB" "$entry" 0)
}

# Per-host extras
[ -f ~/.bashrc.host ] && . ~/.bashrc.host

