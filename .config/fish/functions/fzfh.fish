function fzfh --description 'Search history with fzf'
    history | fzf --query="$argv" --tac | read cmd
    if test -n "$cmd"
        echo $cmd
        commandline -r $cmd
    end
end
