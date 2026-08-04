function lk --description 'linux knowledge' 
	set -l DB "$HOME/projects/dmz/soft/lk/db.rec"
	set -l passes 0
	set -l count 0
	set -l query ""

	while test $passes -lt 2; and test $count -eq 0
		set query (recsel "$DB" -p aim,tag | recsel -iq "$query" -CP aim,tag | sort -u | fzf --preview="recsel \"$DB\" -e \"aim~{}\" | bat")
		if test -n "$query"
			set count (recsel "$DB" -q "$query" -c)
		end
		set passes (math $passes + 1)
	end

	if test $count -eq 1
		recsel "$DB" -q "$query" | recfmt -f "$HOME/projects/dmz/soft/lk/lists.fmt" | less
	end
end
