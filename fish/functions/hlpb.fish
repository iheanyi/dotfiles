function hlpb
  pbpaste | highlight -O rtf --syntax $argv[1] -s base16/tomorrow-night --font="Source Code Pro" --font-size=24 | pbcopy
end
