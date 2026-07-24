# Single positional arg: a branch name. It runs `git checkout -b`, so the new
# branch is typically a fresh name -- but offer existing branch names as a base
# to type from. Only suggest inside a git repo.
complete -c c2-worktree -x -n 'git rev-parse --is-inside-work-tree 2>/dev/null' \
    -a '(git for-each-ref --format="%(refname:short)" refs/heads refs/remotes 2>/dev/null | string replace -r "^origin/" "")'
