function sshf --description 'select ssh host with fzf' 
  ssh $(grep Host -w .ssh/config | awk '{print $2}' | fzf)
end
