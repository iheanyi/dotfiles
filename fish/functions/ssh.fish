# SSH wrapper with tab title
function ssh --wraps=ssh --description "SSH with tab title"
    # Get the last argument (usually the host)
    set -l host (string split '@' -- $argv[-1])[-1]
    # Strip domain suffix for cleaner title
    set host (string split '.' -- $host)[1]

    __set_terminal_title $host
    command ssh $argv
    set -l ssh_status $status
    __reset_terminal_title
    return $ssh_status
end
