# Environment variables

# Ghostty resources (cross-platform)
if test -z "$GHOSTTY_RESOURCES_DIR"
    switch (uname)
        case Darwin
            set -gx GHOSTTY_RESOURCES_DIR /Applications/Ghostty.app/Contents/Resources/ghostty
        case Linux
            test -d /usr/share/ghostty; and set -gx GHOSTTY_RESOURCES_DIR /usr/share/ghostty
    end
end

# Go
set -gx GOBIN $HOME/development/go/bin
set -gx GOPATH $HOME/development/go

# Editor
set -gx EDITOR nvim

# Python version manager (pyenv)
set -gx PYENV_ROOT $HOME/.pyenv

# FZF configuration
# Colors match Poimandres theme
set -gx FZF_DEFAULT_OPTS '--color=bg+:#303340,bg:#252b37,spinner:#5de4c7,hl:#5fb3a1,fg:#a6accd,header:#5fb3a1,info:#89ddff,pointer:#5de4c7,marker:#fffac2,fg+:#e4f0fb,prompt:#5de4c7,hl+:#5de4c7 --height=40% --layout=reverse --border'

# File finder (used by fzf default and Ctrl+T)
set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git --exclude node_modules --exclude vendor --exclude .cache'
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_CTRL_T_OPTS '--preview "bat --color=always --style=numbers --line-range=:500 {}" --preview-window=right:60%'

# Directory finder (Alt+C)
set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git --exclude node_modules --exclude vendor'
set -gx FZF_ALT_C_OPTS '--preview "eza --tree --level=2 --color=always {}"'

# Bat configuration (used for cat replacement and man pager)
set -gx BAT_THEME "base16"
set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
set -gx MANROFFOPT "-c"

# NVM directory
set -gx NVM_DIR "$HOME/.nvm"

# Bun
set -gx BUN_INSTALL "$HOME/.bun"

# Disable warnings/features
set -gx PSCALE_DISABLE_DEV_WARNING 1
set -gx DISABLE_SPRING 1

# Cache Homebrew prefix as universal variable (avoid calling brew --prefix every shell start)
if not set -q HOMEBREW_PREFIX
    if command -q brew
        set -Ux HOMEBREW_PREFIX (brew --prefix)
    end
end
