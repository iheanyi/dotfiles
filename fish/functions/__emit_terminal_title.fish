function __emit_terminal_title --description "Set terminal title, passing through tmux when needed"
    set -l title (string join " " -- $argv)
    set title (string replace -ar "[[:cntrl:]]" "" -- "$title")

    if set -q TMUX
        # tmux DCS passthrough sends the OSC title sequence to Ghostty outside tmux.
        printf "\033Ptmux;\033\033]0;%s\007\033\\\\" "$title"
    else
        printf "\033]0;%s\007" "$title"
    end
end
