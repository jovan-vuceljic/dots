# `h <cmd> ...` shows a command's --help via bat, so complete it like a
# command line: first token = a command, rest = that command's own args.
complete -c h -x -a '(__fish_complete_subcommand)'
