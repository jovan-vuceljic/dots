function tuis --description 'fzf select tui'
    eval (cat $HOME/.config/misc/tuis.txt | command fzf --multi)
end
