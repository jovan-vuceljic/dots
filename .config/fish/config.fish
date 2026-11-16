## Shared fish config (all hosts). Host-specific bits live in host.fish (sourced at the end).
## Secrets (e.g. DUSKADIY_API_KEY) go in conf.d/secrets.fish, which is gitignored.

set -gx EDITOR nvim
set -gx PAGER less
set -gx QT_FONT_DPI 96
set -gx PI_SKIP_VERSION_CHECK 1
set -gx MANPAGER "nvim +Man!"
# fzf's built-in walker is the one search tool that ignores .ignore files, so point it at
# fd, which honours them. fd still hides dotfiles by default everywhere else — this only
# changes what fzf sees inside trees that opt in (e.g. ~/.dots/.ignore).
set -gx FZF_DEFAULT_COMMAND 'fd --type f --strip-cwd-prefix'
set -gx NEWT_COLORS 'root=black,black;window=black,black;border=white,black;listbox=white,black;label=blue,black;checkbox=red,black;title=green,black;button=white,red;actsellistbox=white,red;actlistbox=white,gray;compactbutton=white,gray;actcheckbox=white,blue;entry=lightgray,black;textbox=blue,black' # themes nmtui
# set -gx BAT_THEME "Catppuccin Mocha"

# PATH additions — global on purpose: scripts need these tools too.
# (fnm is initialized once in conf.d/fnm.fish — don't source it again here)
fish_add_path $HOME/.cargo/bin $HOME/.local/bin

# pnpm
set -gx PNPM_HOME "$HOME/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end

# Everything below is for a human at a prompt. config.fish is sourced by EVERY fish —
# scripts and `fish -c` included — and zoxide's `--cmd cd` alias is unconditional: in a
# script, a failed `cd` would silently land in zoxide's best database match (exit 0)
# instead of erroring, and every script `cd` would pollute the database. Aliases/abbrs
# leak into scripts the same way (`ls` → eza, `mkdir` → `mkdir -p`, fzf previews …).
if status is-interactive
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
    alias gs="git status -s"
    alias gp="git pull"
    alias gca="git add -p . && git commit"
    alias gd="git diff --word-diff"
    alias gl="git log --graph --show-signature"
    alias glog="git log --all --decorate --oneline --color --graph"
    alias gla="git log --all --decorate --oneline"
    alias gls="serie"
    alias gm="git merge"

    # List directory
    alias ls='eza --icons --group-directories-first'
    alias l="ls -l"
    alias la="ls -a"
    alias lla="ls -la"
    alias lt="ls --tree"

    # Dotfiles + notes
    alias cdots="cd ~/.dots/"
    alias cpnotes="cd ~/sync/PersonalNotes/"
    alias cnotes="cd ~/sync/CojaDuska/Notes/"
    abbr notes "cnotes && nvim"
    abbr dots "cdots && nvim"
    abbr pnotes "cpnotes && nvim"
    abbr todo "cpnotes && nvim ToDoNext.md"
    abbr aliases "bat ~/.config/fish/config.fish"

    # Handy
    abbr cat "bat -p"
    abbr untar "tar -xf"
    abbr unarchive "atool -x"
    abbr copy wl-copy
    abbr img "kitten icat"
    abbr fm yazi
    abbr lg lazygit
    abbr mkdir "mkdir -p"
    abbr faillock "sudo faillock --reset"
    abbr xremaps "sudo xremap ~/.config/xremap/config.yml"
    abbr pacs "sudo pacman -Syu --noconfirm"
    abbr yays "yay --noconfirm --sudoloop"
    abbr nmaps "sudo nmap -sn 192.168.0.0/24"
    abbr scrcpyc 'scrcpy -wSK -m 1920 --window-borderless --always-on-top --power-off-on-close'
    abbr scrcpys 'scrcpy -wS --power-off-on-close'
    abbr tts "tt -notheme -bold -showwpm -json"
    abbr keybinds "nvim ~/.dots/.config/hypr/binds.lua"
    abbr vpnhome "sudo wg-quick up wg0"
    abbr vpnkralizec "sudo wg-quick up kralizec-wg0"
    abbr vpnsumadija "sudo wg-quick up sumadija-wg0"
    abbr ipadd "sudo ip route add 192.168.0.234 dev wg0"
    abbr aria2cs "aria2c -x 16 -k 1M"

    # Change-dir shortcuts
    abbr .. "cd .."
    abbr ... "cd ../.."
    abbr .3 "cd ../../.."
    abbr .4 "cd ../../../.."
    abbr .5 "cd ../../../../.."

    # Tool init
    zoxide init --cmd cd fish | source

    # thefuck, lazy-loaded on first use (its --alias eval costs ~170ms of shell startup)
    function fuck
        functions -e fuck
        thefuck --alias | source
        fuck $argv
    end
end

# Per-host extras
test -f ~/.config/fish/host.fish; and source ~/.config/fish/host.fish
