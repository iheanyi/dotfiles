if status is-interactive
    # Commands to run in interactive sessions can go here
    # source (jump shell fish | psub)
end


if test -z "$GHOSTTY_RESOURCES_DIR"
  set -gxp GHOSTTY_RESOURCES_DIR /Applications/Ghostty.app/Contents/Resources/ghostty
end

# Globals
set -gxp PATH $HOME/development/go/bin /opt/homebrew/bin /opt/homebrew/opt/openjdk/bin /Applications/Ghostty.app/Contents/MacOS
set -gx GOBIN $HOME/development/go/bin
set -gx PSCALE_DISABLE_DEV_WARNING 1

set -gx EDITOR nvim
# set -gx TERM screen-256color
# set -gx COLORTERM truecolor
set -gx FZF_DEFAULT_OPTS '--color=bg+:#3B4252,bg:#2E3440,spinner:#81A1C1,hl:#616E88,fg:#D8DEE9,header:#616E88,info:#81A1C1,pointer:#81A1C1,marker:#81A1C1,fg+:#D8DEE9,prompt:#81A1C1,hl+:#81A1C1'
set -gx BAT_THEME "base16"
set -gx FZF_DEFAULT_COMMAND 'ag --hidden --ignore .git -g ""'
set -gx NVM_DIR "$HOME/.nvim"

# Starship prompt
starship init fish | source

# Atuin search
atuin init fish --disable-up-arrow | source

# Disable Spring rails
set -gx DISABLE_SPRING 1

# don't show any greetings
set fish_greeting ""
# Sensitive functions taht are not pushed to GitHub, usually work-related.
source ~/.private.fish

# alias python="python3"
# alias cat="bat"
# alias ss="bundle exec spring stop"
# alias cowork="npx @koddsson/coworking-with"
# alias close-right-tmux-windows="for win_id in $(tmux list-windows -F '#{window_active} #{window_id}' | awk '/^1/ { active=1; next } active { print $2 }'); do tmux kill-window -t "$win_id"; done"
# alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"
alias rubo="bundle exec rubocop -a --cache true --server"

# Autocompletions
if test -d (brew --prefix)"/share/fish/completions"
    set -p fish_complete_path (brew --prefix)/share/fish/completions
end

if test -d (brew --prefix)"/share/fish/vendor_completions.d"
    set -p fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
end

eval "$(rbenv init -)"

# SSH Agent
# https://gist.github.com/josh-padnick/c90183be3d0e1feb89afd7573505cab3
if test -z (pgrep ssh-agent | string collect)
  # Cleanup old processes
  trap "kill $SSH_AGENT_PID" exit
  trap "ssh-agent -k" exit
  eval (ssh-agent -c)
  set -Ux SSH_AUTH_SOCK $SSH_AUTH_SOCK
  set -Ux SSH_AGENT_PID $SSH_AGENT_PID
  set -Ux SSH_AUTH_SOCK $SSH_AUTH_SOCK
end

# Autojump
test -e {$HOME}/.iterm2_shell_integration.fish ; and source {$HOME}/.iterm2_shell_integration.fish
[ -f /opt/homebrew/share/autojump/autojump.fish ]; and source /opt/homebrew/share/autojump/autojump.fish

# Created by `pipx` on 2024-04-01 21:48:03
set PATH $PATH /Users/iheanyi/.local/bin

source {$GHOSTTY_RESOURCES_DIR}/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish

pyenv init - | source
fish_add_path /Users/iheanyi/.humanlog/bin
fish_add_path /opt/homebrew/sbin
# source /Users/iheanyi/.config/op/plugins.sh
