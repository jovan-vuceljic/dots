# fnm — single init for all hosts (config.fish must NOT source fnm again:
# every `fnm env | source` mints a fresh multishell dir onto PATH).
# fnm may be pacman-installed (on PATH) or self-installed under ~/.local/share/fnm.
test -d "$HOME/.local/share/fnm"; and fish_add_path -g "$HOME/.local/share/fnm"
if command -q fnm
    fnm env --use-on-cd --version-file-strategy local --shell fish | source
end
