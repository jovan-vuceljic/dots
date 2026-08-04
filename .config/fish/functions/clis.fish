function clis --description 'fzf select cli'
    eval (cat $HOME/.config/misc/clis.txt | command fzf --multi)
end
