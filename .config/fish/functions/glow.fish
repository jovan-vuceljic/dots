function glow --wraps glow --description 'glow wrapped at the current terminal width; an explicit -w still wins'
    # glow never sizes itself to the terminal: glow.yml's width (or its built-in 80) applies, and
    # `width: 0` in the config means 80 too. Wide tables get squeezed into that, one word per line.
    # $COLUMNS tracks window resizes; a later -w/--width in $argv overrides this one.
    command glow --width $COLUMNS $argv
end
