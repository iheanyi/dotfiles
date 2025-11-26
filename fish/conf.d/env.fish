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

# Editor
set -gx EDITOR nvim

# FZF configuration
set -gx FZF_DEFAULT_OPTS '--color=bg+:#3B4252,bg:#2E3440,spinner:#81A1C1,hl:#616E88,fg:#D8DEE9,header:#616E88,info:#81A1C1,pointer:#81A1C1,marker:#81A1C1,fg+:#D8DEE9,prompt:#81A1C1,hl+:#81A1C1'
set -gx FZF_DEFAULT_COMMAND 'ag --hidden --ignore .git -g ""'

# Bat theme
set -gx BAT_THEME "base16"

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
