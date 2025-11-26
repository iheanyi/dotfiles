# SSH Agent setup
# Uses socket check for reliability instead of pgrep

function _cleanup_ssh_agent --on-event fish_exit
    test -n "$SSH_AGENT_PID"; and kill $SSH_AGENT_PID 2>/dev/null
end

if not set -q SSH_AUTH_SOCK; or not test -S "$SSH_AUTH_SOCK"
    eval (ssh-agent -c)
    set -Ux SSH_AUTH_SOCK $SSH_AUTH_SOCK
    set -Ux SSH_AGENT_PID $SSH_AGENT_PID
end
