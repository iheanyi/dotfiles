# Wrap nvim to always listen on a per-pane socket when inside tmux.
# This enables tmux-fzf-files and other tools to open files in your
# existing nvim instance via RPC (e.g. :e +line file).
#
# The socket lives at /tmp/nvim-<TMUX_PANE>.sock (e.g. /tmp/nvim-%9.sock).
# If a stale socket exists from a crashed nvim, we clean it up before
# launching so you don't get "address already in use" errors.
function nvim --wraps=nvim --description "Neovim with per-pane server socket"
    if set -q TMUX_PANE
        set -l socket /tmp/nvim-$TMUX_PANE.sock

        # Clean up stale sockets: try to ping an existing nvim at this socket.
        # If the ping fails, the socket is leftover from a crash — remove it.
        if test -e $socket
            if not command nvim --server $socket --remote-expr '"1"' &>/dev/null
                rm -f $socket
            end
        end

        command nvim --listen $socket $argv
    else
        # Outside tmux: no socket needed
        command nvim $argv
    end
end
