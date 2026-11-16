function gcap --description 'Git add, commit with message, and push'
    git add .
    and git commit -m "$argv"
    and git push
end
