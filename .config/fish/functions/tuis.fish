
function tuis --description 'fzf select tui' 
  eval (string split "\n" (cat ".dotfiles/tuis.txt") | fzf)
end
