function copy-commandline
    set -l cmd (commandline)
    if test -n "$cmd"
        if type -q pbcopy
            echo -n "$cmd" | pbcopy
        else if type -q xclip
            echo -n "$cmd" | xclip -selection clipboard
        else if type -q wl-copy
            echo -n "$cmd" | wl-copy
        end
        
        # Provide brief visual feedback in the prompt
        set -l original_cmd (commandline)
        commandline -r "Copied!"
        sleep 0.4
        commandline -r "$original_cmd"
    end
end
