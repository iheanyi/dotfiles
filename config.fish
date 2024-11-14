if status is-interactive
    # Commands to run in interactive sessions can go here
    # source (jump shell fish | psub)
end

if test -d /home/linuxbrew/.linuxbrew # Linux
	set -gx HOMEBREW_PREFIX "/home/linuxbrew/.linuxbrew"
	set -gx HOMEBREW_CELLAR "$HOMEBREW_PREFIX/Cellar"
	set -gx HOMEBREW_REPOSITORY "$HOMEBREW_PREFIX/Homebrew"
else if test -d /opt/homebrew # MacOS
	set -gx HOMEBREW_PREFIX "/opt/homebrew"
	set -gx HOMEBREW_CELLAR "$HOMEBREW_PREFIX/Cellar"
	set -gx HOMEBREW_REPOSITORY "$HOMEBREW_PREFIX/homebrew"
end

fish_add_path -gP "$HOMEBREW_PREFIX/bin" "$HOMEBREW_PREFIX/sbin";

! set -q MANPATH; and set MANPATH ''; set -gx MANPATH "$HOMEBREW_PREFIX/share/man" $MANPATH;
! set -q INFOPATH; and set INFOPATH ''; set -gx INFOPATH "$HOMEBREW_PREFIX/share/info" $INFOPATH;

# Globals
set -gxp PATH $HOME/development/go/bin /opt/homebrew/bin /opt/homebrew/opt/openjdk/bin
set -gx GOBIN $HOME/development/go/bin

set -gx EDITOR nvim
set -gx TERM tmux-256color
set -gx COLORTERM truecolor
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

alias python="python3"
# alias cat="bat"
# alias ss="bundle exec spring stop"
# alias cowork="npx @koddsson/coworking-with"
# alias close-right-tmux-windows="for win_id in $(tmux list-windows -F '#{window_active} #{window_id}' | awk '/^1/ { active=1; next } active { print $2 }'); do tmux kill-window -t "$win_id"; done"
# alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

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
[ -f (brew --prefix)/share/autojump/autojump.fish ]; and source (brew --prefix)/share/autojump/autojump.fish
