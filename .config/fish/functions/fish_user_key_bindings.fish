function fish_user_key_bindings
    # free Ctrl+S from terminal flow control (XOFF) so it can be bound below
    stty -ixon
    fish_default_key_bindings -M insert
    fish_vi_key_bindings --no-erase insert
    bind -M default ctrl-a beginning-of-line
    bind -M default ctrl-e end-of-line
    bind -M insert ctrl-space accept-autosuggestion
    bind -M insert ctrl-g 'git diff' repaint
    bind -M insert ctrl-o execute yazi
    bind -M insert ctrl-l clear-screen ls repaint
    bind -M default ctrl-s copy-commandline
    bind -M insert ctrl-s copy-commandline
    bind -M search ctrl-s copy-commandline
end
