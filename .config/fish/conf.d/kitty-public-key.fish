# Drop kitty's KITTY_PUBLIC_KEY from the shell environment.
#
# kitty generates a random 40-char base85 public key per instance and exports it
# to every child (kitty/child.py). It is only read on the password path of kitty
# remote control (kitty/remote_control.py: "Password usage requested but
# KITTY_PUBLIC_KEY environment variable is not available"), which needs
# allow_remote_control — not enabled here. `kitten ssh`, icat, clipboard and
# shell integration never touch it.
#
# Why bother: tools that inline the environment into generated code get corrupted
# when a value contains a String.replace replacement sequence. prettier's
# --experimental-cli inlines JSON.stringify(process.env) into its parallel worker
# and splices it with .replace(placeholder, bootloader); a `$` + backtick in the
# key expands to "everything before the match", injecting the worker's own source
# mid-string. Every file then fails with a bogus
# "SyntaxError: Unexpected identifier 'string'". Roughly a 1-in-185 chance per
# kitty launch, which is exactly as fun to debug as it sounds.
if set -q KITTY_PUBLIC_KEY
    set -e KITTY_PUBLIC_KEY
end
