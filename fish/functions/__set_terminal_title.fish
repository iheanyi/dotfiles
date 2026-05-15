function __set_terminal_title --description "Temporarily set terminal title"
    set -l title (string join " " -- $argv)
    if test -z "$title"
        return 1
    end

    set -g __terminal_title_stack $__terminal_title_stack (__terminal_title_default)
    __emit_terminal_title "$title"
end
