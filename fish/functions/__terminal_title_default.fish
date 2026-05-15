function __terminal_title_default --description "Best effort default terminal title"
    if set -q TMUX; and command -q tmux
        set -l tmux_title (tmux display-message -p "#S:#W" 2>/dev/null)
        if test -n "$tmux_title"
            echo "$tmux_title"
            return 0
        end
    end

    if functions -q fish_title
        set -l fish_title_output (fish_title)
        if test -n "$fish_title_output"
            echo "$fish_title_output"
            return 0
        end
    end

    prompt_pwd
end
