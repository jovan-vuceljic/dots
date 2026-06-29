function clis --description 'fzf select cli' 
  eval (string split "\n" (cat $HOME/.dotfiles/.config/misc/clis.txt) | bashs "fzf --multi")
end
