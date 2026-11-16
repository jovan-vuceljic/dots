function extract --description 'Extract any archive'
    switch $argv[1]
        case '*.tar' '*.tar.*' '*.tgz' '*.tbz2' '*.txz' # tar autodetects compression
            tar xf $argv[1]
        case '*.zip'
            unzip $argv[1]
        case '*.rar'
            unrar x $argv[1]
        case '*.7z'
            7z x $argv[1]
        case '*.gz'
            gunzip -k $argv[1]
        case '*.xz'
            unxz -k $argv[1]
        case '*.zst'
            unzstd $argv[1]
        case '*.bz2'
            bunzip2 -k $argv[1]
        case '*'
            echo "Unknown extension: $argv[1]"
            return 1
    end
end
