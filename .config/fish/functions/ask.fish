function ask --description 'answer from cht.sh' 
  curl -s https://cht.sh/$(string join '+' $argv[1..]) 
end
