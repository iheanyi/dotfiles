# Send notification when Claude needs attention or completes a task
# Uses multiple channels: macOS notification, tmux status, terminal bell
function claude-notify --description "Notify when Claude needs attention"
    set -l message $argv[1]
    if test -z "$message"
        set message "Claude needs attention"
    end

    # macOS notification (if terminal-notifier installed)
    if command -q terminal-notifier
        terminal-notifier -title "Claude" -message "$message" -sound default 2>/dev/null
    end

    # tmux status bar flash (if in tmux)
    if set -q TMUX
        tmux display-message "Claude: $message" 2>/dev/null
    end

    # Terminal bell (Ghostty and other terminals handle this)
    printf "\a"
end
