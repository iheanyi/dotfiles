# Dotfiles installation and management
# Run `just` to see available recipes

# Use bash for portability - fish may not be installed on fresh machines
set shell := ["bash", "-c"]

# Default recipe - show help
default:
    @just --list

# Detect OS
os := if os() == "macos" { "macos" } else if os() == "linux" { "linux" } else { "unknown" }

# ============================================================================
# Installation
# ============================================================================

# Full installation (run this on a new machine)
install: install-homebrew install-packages install-fish install-tmux-plugins link setup-git
    @echo "✓ Installation complete! Restart your terminal."

# Configure git with base settings and user info
setup-git:
    #!/usr/bin/env bash
    echo "=== Git Configuration ==="

    DOTFILES="{{justfile_directory()}}"
    BASE_CONFIG="$DOTFILES/.gitconfig.base"

    # Apply base configuration settings
    echo "Applying base git configuration..."
    if [ -f "$BASE_CONFIG" ]; then
        # Read each section and key from base config and apply
        # This preserves existing user settings while adding our defaults
        git config --global init.defaultBranch main
        git config --global core.excludesfile ~/.gitignore_global
        git config --global core.editor nvim
        git config --global core.pager delta
        git config --global interactive.diffFilter "delta --color-only"
        git config --global delta.navigate true
        git config --global delta.side-by-side true
        git config --global delta.line-numbers true
        git config --global pull.rebase true
        git config --global push.default current
        git config --global push.autoSetupRemote true
        git config --global fetch.prune true
        git config --global rebase.autoStash true
        git config --global merge.conflictstyle diff3
        git config --global diff.colorMoved default
        git config --global diff.tool difftastic
        git config --global difftool.prompt false
        git config --global difftool.difftastic.cmd 'difft "$LOCAL" "$REMOTE"'
        git config --global pager.difftool true
        git config --global color.ui true
        git config --global rerere.enabled true
        # Mergiraf structural merge driver
        git config --global merge.mergiraf.name mergiraf
        git config --global merge.mergiraf.driver 'mergiraf merge --git %O %A %B -s %S -x %X -y %Y -p %P -l %L'
        git config --global branch.sort -committerdate
        git config --global column.ui auto
        # Aliases
        git config --global alias.s "status -sb"
        git config --global alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
        git config --global alias.ll "log --oneline"
        git config --global alias.last "log -1 HEAD --stat"
        git config --global alias.co "checkout"
        git config --global alias.cob "checkout -b"
        git config --global alias.br "branch"
        git config --global alias.bra "branch -a"
        git config --global alias.cm "commit -m"
        git config --global alias.ca "commit --amend"
        git config --global alias.can "commit --amend --no-edit"
        git config --global alias.d "diff"
        git config --global alias.dc "diff --cached"
        git config --global alias.undo "reset HEAD~1 --mixed"
        git config --global alias.unstage "reset HEAD --"
        git config --global alias.sl "stash list"
        git config --global alias.sp "stash pop"
        git config --global alias.ss "stash save"
        git config --global alias.cleanup "!git branch --merged | grep -v '\\*\\|main\\|master' | xargs -n 1 git branch -d"
        echo "✓ Base config applied"
    else
        echo "⚠ Base config not found at $BASE_CONFIG"
    fi

    # Check current user config
    current_name=$(git config --global user.name 2>/dev/null || echo "")
    current_email=$(git config --global user.email 2>/dev/null || echo "")

    if [ -n "$current_name" ] && [ -n "$current_email" ]; then
        echo ""
        echo "Current user:"
        echo "  Name:  $current_name"
        echo "  Email: $current_email"
        echo ""
        read -p "Do you want to update these? [y/N] " update
        if [[ ! "$update" =~ ^[Yy]$ ]]; then
            echo "✓ Git setup complete"
            exit 0
        fi
    fi

    # Prompt for name
    echo ""
    if [ -n "$current_name" ]; then
        read -p "Enter your name [$current_name]: " name
        name=${name:-$current_name}
    else
        read -p "Enter your name: " name
    fi

    # Prompt for email
    if [ -n "$current_email" ]; then
        read -p "Enter your email [$current_email]: " email
        email=${email:-$current_email}
    else
        read -p "Enter your email: " email
    fi

    # Set user config
    git config --global user.name "$name"
    git config --global user.email "$email"

    echo ""
    echo "✓ Git configured:"
    echo "  Name:  $(git config --global user.name)"
    echo "  Email: $(git config --global user.email)"

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
link: link-fish link-neovim link-terminal link-git link-tmux link-starship link-claude link-bin
    @echo "✓ All configs linked"

# Link fish configuration
link-fish:
    @mkdir -p ~/.config/fish/conf.d
    @mkdir -p ~/.config/fish/functions
    @ln -sf {{justfile_directory()}}/config.fish ~/.config/fish/config.fish
    @ln -sf {{justfile_directory()}}/fish_plugins ~/.config/fish/fish_plugins
    @for f in {{justfile_directory()}}/fish/conf.d/*.fish; do ln -sf "$$f" ~/.config/fish/conf.d/; done
    @for f in {{justfile_directory()}}/fish/functions/*.fish; do ln -sf "$$f" ~/.config/fish/functions/; done
    @echo "✓ Fish config linked"

# Link Neovim configuration
link-neovim:
    @mkdir -p ~/.config/nvim/lua/config
    @ln -sf {{justfile_directory()}}/init.lua ~/.config/nvim/init.lua
    @ln -sf {{justfile_directory()}}/.stylua.toml ~/.config/nvim/.stylua.toml
    @for f in {{justfile_directory()}}/lua/config/*.lua; do ln -sf "$$f" ~/.config/nvim/lua/config/; done
    @echo "✓ Neovim config linked"

# Link terminal emulator configs
link-terminal:
    @mkdir -p ~/.config/ghostty
    @ln -sf {{justfile_directory()}}/ghostty/config ~/.config/ghostty/config
    @echo "✓ Ghostty config linked"

# Link git configuration
link-git:
    @ln -sf {{justfile_directory()}}/.gitconfig ~/.gitconfig
    @ln -sf {{justfile_directory()}}/.gitignore_global ~/.gitignore_global
    @mkdir -p ~/.config/git
    @ln -sf {{justfile_directory()}}/git/attributes ~/.config/git/attributes
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

# Link Claude Code configuration
link-claude:
    @mkdir -p ~/.claude
    @ln -sf {{justfile_directory()}}/claude/settings.json ~/.claude/settings.json
    @ln -sf {{justfile_directory()}}/claude/statusline-command.sh ~/.claude/statusline-command.sh
    @echo "✓ Claude config linked"

# Link helper scripts (tmux-open-in-nvim, tmux-fzf-files, etc.)
link-bin:
    @mkdir -p ~/.dotfiles/bin
    @for f in {{justfile_directory()}}/bin/*; do ln -sf "$$f" ~/.dotfiles/bin/; done
    @echo "✓ Helper scripts linked"

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
    tools=("fish" "nvim" "starship" "fzf" "git" "tmux" "ghostty" "bat" "fd" "rg" "zoxide" "direnv" "difft" "mergiraf")
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
        "$HOME/.gitignore_global"
        "$HOME/.config/git/attributes"
        "$HOME/.claude/settings.json"
        "$HOME/.claude/statusline-command.sh"
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
