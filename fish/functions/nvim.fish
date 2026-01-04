# Wrap nvim to always listen on a per-pane socket when inside tmux
# This enables tmux-fingers and other tools to open files in your existing nvim
function nvim --wraps=nvim --description "Neovim with per-pane server socket"
    if set -q TMUX_PANE
        # Inside tmux: use per-pane socket
        command nvim --listen /tmp/nvim-$TMUX_PANE.sock $argv
    else
        # Outside tmux: normal nvim
        command nvim $argv
    end
end
