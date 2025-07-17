function hl
  highlight $argv[1] -O rtf --syntax $argv[2] -s base16/tomorrow-night | pbcopy
end
