function clis --description 'fzf select cli'
    # one eval per selection — a single eval of the joined lines would run the
    # first command with the other selections as its arguments
    for cmd in (cat $HOME/.config/misc/clis.txt | command fzf --multi)
        eval $cmd
    end
end
