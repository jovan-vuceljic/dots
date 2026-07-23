function h --description "Colorized --help via bat"
    $argv --help 2>&1 | bat --plain --language=help
end
