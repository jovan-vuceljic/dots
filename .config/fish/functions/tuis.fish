function tuis --description 'fzf select tui' 
  eval (string split "\n" (cat $HOME/.dotfiles/tuis.txt) | fzf)
end
