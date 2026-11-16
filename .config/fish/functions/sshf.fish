function sshf --description 'fzf-pick an ssh host from ~/.ssh/config'
    # command fzf: bypass the fzf alias (its bat preview makes no sense for host names);
    # skip `Host *` wildcard blocks and take every alias on multi-name Host lines
    set -l host (awk '/^Host /{for (i = 2; i <= NF; i++) if ($i != "*") print $i}' ~/.ssh/config | command fzf)
    test -n "$host"; and ssh $host
end
