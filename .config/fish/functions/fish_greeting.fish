function fish_greeting
    #curl "wttr.in/Belgrade?format=%l:+%c+%t+|+%h+|+%w+|+(%%M+%m)\n"
    test -r ~/.config/fish/greet.txt; and cat ~/.config/fish/greet.txt ## populated by cronjob
    date +"📅 %d. %b 🕗 %H:%M - %A"
end
