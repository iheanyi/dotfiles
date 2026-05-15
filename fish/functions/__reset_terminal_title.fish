function __reset_terminal_title --description "Restore terminal title after a temporary override"
    set -l title

    if set -q __terminal_title_stack[-1]
        set title $__terminal_title_stack[-1]
        set -e __terminal_title_stack[-1]
    else
        set title (__terminal_title_default)
    end

    __emit_terminal_title "$title"
end
