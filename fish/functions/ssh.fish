# SSH wrapper with tab title
function ssh --wraps=ssh --description "SSH with tab title"
    # Get the last argument (usually the host)
    set -l host (string split '@' -- $argv[-1])[-1]
    # Strip domain suffix for cleaner title
    set host (string split '.' -- $host)[1]

    __set_terminal_title $host
    command ssh $argv
    __reset_terminal_title
end
