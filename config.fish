if status is-interactive
    # Commands to run in interactive sessions can go here
    # source (jump shell fish | psub)
end

# Starship prompt
starship init fish | source

# Globals
set -gxp PATH $HOME/development/go/bin /opt/homebrew/bin
set -gx EDITOR vim
set -gx TERM xterm-256color
set -gx COLORTERM truecolor
set -gx FZF_CTRL_T_COMMAND nvim
set -gx BAT_THEME "base16"
set -gx FZF_DEFAULT_COMMAND 'ag --hidden --ignore .git -g ""'
set -gx NVM_DIR "$HOME/.nvim"

# Disable Spring rails
set -gx DISABLE_SPRING 1

# don't show any greetings
set fish_greeting ""

alias tmux="env TERM=xterm-256color tmux"
alias python="python3"
alias cat="bat"
alias ss="bundle exec spring stop"
alias cowork="npx @koddsson/coworking-with"
alias close-right-tmux-windows="for win_id in $(tmux list-windows -F '#{window_active} #{window_id}' | awk '/^1/ { active=1; next } active { print $2 }'); do tmux kill-window -t "$win_id"; done"
alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

# Autocompletions
if test -d (brew --prefix)"/share/fish/completions"
    set -p fish_complete_path (brew --prefix)/share/fish/completions
end

if test -d (brew --prefix)"/share/fish/vendor_completions.d"
    set -p fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
end

# Autojump
[ -f $HOMEBREW_PREFIX/share/autojump/autojump.fish ]
source $HOMEBREW_PREFIX/share/autojump/autojump.fish

eval "$(rbenv init -)"

