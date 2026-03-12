function clip --description "Copy stdin to system clipboard via OSC 52"
    set -l encoded
    if test (count $argv) -gt 0
        set encoded (printf '%s' "$argv" | base64 | tr -d '\n')
    else
        read -z input
        set encoded (printf '%s' "$input" | base64 | tr -d '\n')
    end
    printf '\033]52;c;%s\a' $encoded
end
