function ssh
    if type -q kitten
        kitten ssh $argv
    else
        command ssh $argv
    end
end
