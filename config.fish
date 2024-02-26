if status is-interactive
    # Commands to run in interactive sessions can go here
    # source (jump shell fish | psub)
end


# Globals
set -gxp PATH $HOME/development/go/bin /opt/homebrew/bin /opt/homebrew/opt/openjdk/bin
set -gx EDITOR vim
set -gx TERM tmux-256color
set -gx COLORTERM truecolor
set -gx FZF_DEFAULT_OPTS '--color=bg+:#3B4252,bg:#2E3440,spinner:#81A1C1,hl:#616E88,fg:#D8DEE9,header:#616E88,info:#81A1C1,pointer:#81A1C1,marker:#81A1C1,fg+:#D8DEE9,prompt:#81A1C1,hl+:#81A1C1'
set -gx BAT_THEME "base16"
set -gx FZF_DEFAULT_COMMAND 'ag --hidden --ignore .git -g ""'
set -gx NVM_DIR "$HOME/.nvim"

# Starship prompt
starship init fish | source

# Disable Spring rails
set -gx DISABLE_SPRING 1

# don't show any greetings
set fish_greeting ""

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

# SSH Agent
eval (ssh-agent -c)

test -e {$HOME}/.iterm2_shell_integration.fish ; and source {$HOME}/.iterm2_shell_integration.fish

