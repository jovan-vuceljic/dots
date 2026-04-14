function sshf --description 'fzf select for ssh hosts' 
  ssh $(grep Host -w ~/.ssh/config | awk '{print $2}' | bashs "fzf --multi") 
end
