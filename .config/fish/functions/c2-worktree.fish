function c2-worktree
    if test (count $argv) -ne 1
        echo "Usage: pkg-worktree <branch-name>"
        echo "Example: pkg-worktree package/package-update"
        return 1
    end

    set branch $argv[1]
    set dir (basename $branch)

    git checkout -b $branch
    or return 1

    git checkout master
    or return 1

    git worktree add $dir $branch
    or return 1

    cd $dir
    or return 1

    pnpm i
end
