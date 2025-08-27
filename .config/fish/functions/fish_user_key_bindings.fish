function fish_user_key_bindings
    fish_default_key_bindings -M insert
    fish_vi_key_bindings --no-erase insert
    bind -M default ctrl-a beginning-of-line
    bind -M default ctrl-e end-of-line
    bind -M insert ctrl-space accept-autosuggestion
    bind -M insert ctrl-g 'git diff' repaint

    bind -M insert ctrl-o execute yazi
    bind -M insert ctrl-l clear-screen ls repaint
end
