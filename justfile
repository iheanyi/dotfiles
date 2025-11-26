# Dotfiles installation and management
# Run `just` to see available recipes

set shell := ["fish", "-c"]

# Default recipe - show help
default:
    @just --list

# Detect OS
os := if os() == "macos" { "macos" } else if os() == "linux" { "linux" } else { "unknown" }

# ============================================================================
# Installation
# ============================================================================

# Full installation (run this on a new machine)
install: install-homebrew install-packages install-fish link
    @echo "✓ Installation complete! Restart your terminal."

# Install Homebrew (macOS/Linux)
install-homebrew:
    #!/usr/bin/env bash
    if ! command -v brew &> /dev/null; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    else
        echo "Homebrew already installed"
    fi

# Install packages via Homebrew
install-packages: install-homebrew
    brew bundle --file=Brewfile

# Install fish shell and set as default
install-fish:
    #!/usr/bin/env bash
    if ! grep -q "$(which fish)" /etc/shells; then
        echo "$(which fish)" | sudo tee -a /etc/shells
    fi
    if [ "$SHELL" != "$(which fish)" ]; then
        chsh -s "$(which fish)"
    fi
    # Install fisher plugin manager
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"
    fish -c "fisher update"

# ============================================================================
# Symlink Management
# ============================================================================

# Link all dotfiles to home directory
link: link-fish link-neovim link-terminal link-git link-tmux link-starship

# Link fish configuration
link-fish:
    @mkdir -p ~/.config/fish/conf.d
    @mkdir -p ~/.config/fish/functions
    @ln -sf {{justfile_directory()}}/config.fish ~/.config/fish/config.fish
    @ln -sf {{justfile_directory()}}/fish_plugins ~/.config/fish/fish_plugins
    @for f in {{justfile_directory()}}/fish/conf.d/*.fish; ln -sf $f ~/.config/fish/conf.d/; end
    @for f in {{justfile_directory()}}/fish/functions/*.fish; ln -sf $f ~/.config/fish/functions/; end
    @echo "✓ Fish config linked"

# Link Neovim configuration
link-neovim:
    @mkdir -p ~/.config/nvim/lua/config
    @ln -sf {{justfile_directory()}}/init.lua ~/.config/nvim/init.lua
    @ln -sf {{justfile_directory()}}/.stylua.toml ~/.config/nvim/.stylua.toml
    @for f in {{justfile_directory()}}/lua/config/*.lua; ln -sf $f ~/.config/nvim/lua/config/; end
    @echo "✓ Neovim config linked"

# Link terminal emulator configs
link-terminal:
    @mkdir -p ~/.config/ghostty
    @ln -sf {{justfile_directory()}}/ghostty/config ~/.config/ghostty/config
    @echo "✓ Ghostty config linked"

# Link git configuration
link-git:
    @ln -sf {{justfile_directory()}}/.gitignore_global ~/.gitignore_global
    @git config --global core.excludesfile ~/.gitignore_global
    @echo "✓ Git config linked"

# Link tmux configuration
link-tmux:
    @ln -sf {{justfile_directory()}}/.tmux.conf ~/.tmux.conf
    @echo "✓ Tmux config linked"

# Link starship prompt
link-starship:
    @mkdir -p ~/.config
    @ln -sf {{justfile_directory()}}/starship.toml ~/.config/starship.toml
    @echo "✓ Starship config linked"

# ============================================================================
# Maintenance
# ============================================================================

# Update all packages and plugins
update: update-brew update-fish update-neovim
    @echo "✓ All updates complete"

# Update Homebrew packages
update-brew:
    brew update && brew upgrade

# Update fish plugins
update-fish:
    fish -c "fisher update"

# Update Neovim plugins
update-neovim:
    nvim --headless "+Lazy! sync" +qa

# Clean up old/unused files
clean:
    brew cleanup
    @echo "✓ Cleanup complete"

# ============================================================================
# Backup
# ============================================================================

# Backup current Homebrew packages to Brewfile
backup-brew:
    brew bundle dump --force --file=Brewfile
    @echo "✓ Brewfile updated"

# ============================================================================
# Utilities
# ============================================================================

# Check if all tools are installed
check:
    #!/usr/bin/env bash
    echo "Checking installed tools..."
    tools=("fish" "nvim" "starship" "fzf" "git" "tmux" "ghostty")
    for tool in "${tools[@]}"; do
        if command -v $tool &> /dev/null; then
            echo "✓ $tool"
        else
            echo "✗ $tool (not installed)"
        fi
    done

# Show current OS
info:
    @echo "OS: {{os}}"
    @echo "Home: $HOME"
    @echo "Dotfiles: {{justfile_directory()}}"
