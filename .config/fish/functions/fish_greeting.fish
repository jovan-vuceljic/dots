function fish_greeting
    # greet.txt: a weather line, refreshed by a cronjob, e.g. `curl "wttr.in/<city>?format=4" > ~/.config/fish/greet.txt`
    test -r ~/.config/fish/greet.txt; and cat ~/.config/fish/greet.txt
    date +"📅 %d. %b 🕗 %H:%M - %A"
end
