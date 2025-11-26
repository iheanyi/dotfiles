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
install: install-homebrew install-packages install-fish install-tmux-plugins link
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

# Install tmux plugin manager (TPM)
install-tmux-plugins:
    #!/usr/bin/env bash
    if [ ! -d ~/.tmux/plugins/tpm ]; then
        echo "Installing TPM..."
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    else
        echo "TPM already installed"
    fi
    # Install plugins
    ~/.tmux/plugins/tpm/bin/install_plugins || true

# ============================================================================
# Symlink Management
# ============================================================================

# Link all dotfiles to home directory
link: link-fish link-neovim link-terminal link-git link-tmux link-starship
    @echo "✓ All configs linked"

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
    @ln -sf {{justfile_directory()}}/.gitconfig ~/.gitconfig
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
update: update-brew update-fish update-neovim update-tmux
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

# Update tmux plugins
update-tmux:
    ~/.tmux/plugins/tpm/bin/update_plugins all || true

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
# Diagnostics
# ============================================================================

# Check if all tools are installed
check:
    #!/usr/bin/env bash
    echo "Checking installed tools..."
    tools=("fish" "nvim" "starship" "fzf" "git" "tmux" "ghostty" "bat" "fd" "rg" "zoxide" "direnv")
    for tool in "${tools[@]}"; do
        if command -v $tool &> /dev/null; then
            echo "✓ $tool"
        else
            echo "✗ $tool (not installed)"
        fi
    done

# Diagnose common issues
doctor:
    #!/usr/bin/env bash
    echo "Running diagnostics..."
    echo ""
    errors=0

    # Check symlinks
    echo "=== Symlinks ==="
    links=(
        "$HOME/.config/fish/config.fish"
        "$HOME/.config/nvim/init.lua"
        "$HOME/.config/ghostty/config"
        "$HOME/.config/starship.toml"
        "$HOME/.tmux.conf"
        "$HOME/.gitconfig"
        "$HOME/.gitignore_global"
    )
    for link in "${links[@]}"; do
        if [ -L "$link" ]; then
            echo "✓ $link"
        elif [ -f "$link" ]; then
            echo "⚠ $link (exists but not a symlink)"
            ((errors++))
        else
            echo "✗ $link (missing)"
            ((errors++))
        fi
    done
    echo ""

    # Check plugin managers
    echo "=== Plugin Managers ==="
    if [ -d "$HOME/.tmux/plugins/tpm" ]; then
        echo "✓ TPM (tmux)"
    else
        echo "✗ TPM not installed (run: just install-tmux-plugins)"
        ((errors++))
    fi

    if fish -c "type -q fisher" 2>/dev/null; then
        echo "✓ Fisher (fish)"
    else
        echo "✗ Fisher not installed (run: just install-fish)"
        ((errors++))
    fi
    echo ""

    # Check shell
    echo "=== Shell ==="
    if [ "$SHELL" = "$(which fish)" ]; then
        echo "✓ Default shell is fish"
    else
        echo "⚠ Default shell is $SHELL (not fish)"
    fi
    echo ""

    # Summary
    if [ $errors -eq 0 ]; then
        echo "✓ All checks passed!"
    else
        echo "✗ Found $errors issue(s)"
        exit 1
    fi

# Validate all configuration files
lint:
    #!/usr/bin/env bash
    echo "Validating configuration files..."
    errors=0

    # Fish configs
    echo ""
    echo "=== Fish Shell ==="
    for f in {{justfile_directory()}}/config.fish {{justfile_directory()}}/fish/conf.d/*.fish; do
        if fish -n "$f" 2>/dev/null; then
            echo "✓ $(basename $f)"
        else
            echo "✗ $(basename $f)"
            fish -n "$f"
            ((errors++))
        fi
    done

    # Neovim config
    echo ""
    echo "=== Neovim ==="
    if nvim --headless -c "lua print('ok')" -c "qa" 2>&1 | grep -q "ok"; then
        echo "✓ init.lua"
    else
        echo "✗ init.lua"
        nvim --headless -c "qa" 2>&1 | head -5
        ((errors++))
    fi

    # Starship
    echo ""
    echo "=== Starship ==="
    if STARSHIP_LOG=error starship prompt 2>&1 | grep -qi "error"; then
        echo "✗ starship.toml has errors"
        ((errors++))
    else
        echo "✓ starship.toml"
    fi

    # Tmux (use separate socket to avoid killing active sessions)
    echo ""
    echo "=== Tmux ==="
    if tmux -L lint-test -f {{justfile_directory()}}/.tmux.conf start-server \; kill-server 2>&1 | grep -qi "error\|invalid\|unknown"; then
        echo "✗ .tmux.conf has errors"
        tmux -L lint-test -f {{justfile_directory()}}/.tmux.conf start-server \; kill-server 2>&1 | head -5
        ((errors++))
    else
        echo "✓ .tmux.conf"
    fi

    # Brewfile
    echo ""
    echo "=== Brewfile ==="
    if brew bundle check --file={{justfile_directory()}}/Brewfile 2>&1 | grep -q "satisfied"; then
        echo "✓ Brewfile (all dependencies satisfied)"
    else
        echo "⚠ Brewfile (some dependencies not installed)"
    fi

    # Shell scripts
    echo ""
    echo "=== Shell Scripts ==="
    if command -v shellcheck &> /dev/null; then
        # Only check if there are shell scripts
        if ls {{justfile_directory()}}/*.sh 2>/dev/null; then
            for f in {{justfile_directory()}}/*.sh; do
                if shellcheck "$f" 2>/dev/null; then
                    echo "✓ $(basename $f)"
                else
                    echo "✗ $(basename $f)"
                    ((errors++))
                fi
            done
        else
            echo "✓ No shell scripts to check"
        fi
    else
        echo "⚠ shellcheck not installed (skipping)"
    fi

    # Summary
    echo ""
    if [ $errors -eq 0 ]; then
        echo "✓ All configs valid!"
    else
        echo "✗ Found $errors error(s)"
        exit 1
    fi

# Show current OS
info:
    @echo "OS: {{os}}"
    @echo "Home: $HOME"
    @echo "Dotfiles: {{justfile_directory()}}"
