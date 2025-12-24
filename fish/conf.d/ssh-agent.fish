# SSH Agent setup
# macOS: Use system keychain (requires AddKeysToAgent/UseKeychain in ~/.ssh/config)
# Linux: Manual ssh-agent management

switch (uname)
    case Darwin
        # macOS handles ssh-agent via launchd - just ensure we have the socket
        if not set -q SSH_AUTH_SOCK
            set -gx SSH_AUTH_SOCK (launchctl getenv SSH_AUTH_SOCK 2>/dev/null)
        end
    case '*'
        # Linux/other: Manual ssh-agent management
        function _cleanup_ssh_agent --on-event fish_exit
            test -n "$SSH_AGENT_PID"; and kill $SSH_AGENT_PID 2>/dev/null
        end

        if not set -q SSH_AUTH_SOCK; or not test -S "$SSH_AUTH_SOCK"
            eval (ssh-agent -c)
            set -Ux SSH_AUTH_SOCK $SSH_AUTH_SOCK
            set -Ux SSH_AGENT_PID $SSH_AGENT_PID
        end
end
