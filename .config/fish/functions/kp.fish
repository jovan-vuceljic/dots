function kp
    if not set -q KP_DB
        echo "Error: KP_DB environment variable is not set. Check ~/.config/fish/conf.d/secrets.fish"
        return 1
    end

    read -s -P "Enter db password: " pass
    echo ""

    # -f flattens to full paths; without it nested entries are printed indented and
    # without their group prefix, so `clip` can't find them. Group lines end in "/".
    set -l entry (printf '%s\n' $pass | keepassxc-cli ls -q -R -f $KP_DB | string match -v '*/' | fzf | string trim)
    if test -n "$entry"
        printf '%s\n' $pass | keepassxc-cli clip -q $KP_DB $entry 0
    end
end
