if status is-interactive
    # Commands to run in interactive sessions can go here
end


if test -z "$GHOSTTY_RESOURCES_DIR"
  set -gxp GHOSTTY_RESOURCES_DIR /Applications/Ghostty.app/Contents/Resources/ghostty
end

# Globals
# Consolidated PATH additions (fish_add_path handles deduplication)
fish_add_path $HOME/development/go/bin
fish_add_path /opt/homebrew/bin
fish_add_path /opt/homebrew/sbin
fish_add_path /opt/homebrew/opt/openjdk/bin
fish_add_path /Applications/Ghostty.app/Contents/MacOS
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.humanlog/bin
fish_add_path $HOME/.bun/bin
fish_add_path $HOME/.antigravity/antigravity/bin

set -gx GOBIN $HOME/development/go/bin
set -gx PSCALE_DISABLE_DEV_WARNING 1

set -gx EDITOR nvim
set -gx FZF_DEFAULT_OPTS '--color=bg+:#3B4252,bg:#2E3440,spinner:#81A1C1,hl:#616E88,fg:#D8DEE9,header:#616E88,info:#81A1C1,pointer:#81A1C1,marker:#81A1C1,fg+:#D8DEE9,prompt:#81A1C1,hl+:#81A1C1'
set -gx BAT_THEME "base16"
set -gx FZF_DEFAULT_COMMAND 'ag --hidden --ignore .git -g ""'
set -gx NVM_DIR "$HOME/.nvm"

# Starship prompt
starship init fish | source

# Atuin search
atuin init fish --disable-up-arrow | source

# Disable Spring rails
set -gx DISABLE_SPRING 1

# don't show any greetings
set fish_greeting ""
# Sensitive functions that are not pushed to GitHub, usually work-related.
test -f ~/.private.fish; and source ~/.private.fish

alias rubo="bundle exec rubocop -a --cache true --server"

# Autocompletions (cache brew prefix to avoid multiple calls)
set -l brew_prefix (brew --prefix)
if test -d "$brew_prefix/share/fish/completions"
    set -p fish_complete_path $brew_prefix/share/fish/completions
end

if test -d "$brew_prefix/share/fish/vendor_completions.d"
    set -p fish_complete_path $brew_prefix/share/fish/vendor_completions.d
end

rbenv init - fish | source

# SSH Agent
# https://gist.github.com/josh-padnick/c90183be3d0e1feb89afd7573505cab3
function _cleanup_ssh_agent --on-event fish_exit
    test -n "$SSH_AGENT_PID"; and kill $SSH_AGENT_PID 2>/dev/null
end

if test -z (pgrep ssh-agent | string collect)
  eval (ssh-agent -c)
  set -Ux SSH_AUTH_SOCK $SSH_AUTH_SOCK
  set -Ux SSH_AGENT_PID $SSH_AGENT_PID
end

# Autojump
[ -f /opt/homebrew/share/autojump/autojump.fish ]; and source /opt/homebrew/share/autojump/autojump.fish

test -f {$GHOSTTY_RESOURCES_DIR}/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish; and source {$GHOSTTY_RESOURCES_DIR}/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish

pyenv init - | source

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :

# bun
set -gx BUN_INSTALL "$HOME/.bun"
