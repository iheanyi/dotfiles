# Fish shell configuration
# Most config is now split into conf.d/ for better organization:
#   - conf.d/path.fish        - PATH additions
#   - conf.d/env.fish         - Environment variables
#   - conf.d/ssh-agent.fish   - SSH agent setup
#   - conf.d/abbreviations.fish - Command abbreviations

# Disable greeting
set fish_greeting ""

# Interactive-only configuration
if status is-interactive
    # Starship prompt
    command -q starship; and starship init fish | source

    # Atuin search (shell history)
    command -q atuin; and atuin init fish --disable-up-arrow | source

    # FZF key bindings (Ctrl+R for history, Ctrl+T for files)
    command -q fzf; and fzf --fish 2>/dev/null | source

    # Enhanced FZF widgets (override default Ctrl+T, add Ctrl+G)
    if command -q fzf; and command -q fd
        bind \ct _fzf_file_enhanced
        bind -M insert \ct _fzf_file_enhanced
        bind \cg _fzf_cd_enhanced
        bind -M insert \cg _fzf_cd_enhanced
    end

    # Ruby version manager
    command -q rbenv; and rbenv init - fish | source

    # Python version manager
    if command -q mise
        # Prefer mise for Python/Node (partial migration)
        mise activate fish | source
    else
        command -q pyenv; and pyenv init - | source
    end

    # Direnv (auto-load .envrc files)
    command -q direnv; and direnv hook fish | source

    # Zoxide (smarter cd)
    command -q zoxide; and zoxide init fish --cmd j | source

    # Homebrew completions (use cached HOMEBREW_PREFIX)
    if set -q HOMEBREW_PREFIX
        if test -d "$HOMEBREW_PREFIX/share/fish/completions"
            set -p fish_complete_path $HOMEBREW_PREFIX/share/fish/completions
        end
        if test -d "$HOMEBREW_PREFIX/share/fish/vendor_completions.d"
            set -p fish_complete_path $HOMEBREW_PREFIX/share/fish/vendor_completions.d
        end
    end

    # Ghostty shell integration
    if set -q GHOSTTY_RESOURCES_DIR
        test -f $GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish
        and source $GHOSTTY_RESOURCES_DIR/shell-integration/fish/vendor_conf.d/ghostty-shell-integration.fish
    end

    # OrbStack integration
    test -f ~/.orbstack/shell/init2.fish; and source ~/.orbstack/shell/init2.fish 2>/dev/null

    # Private/work-related config (not in git)
    test -f ~/.config/fish/private.fish; and source ~/.config/fish/private.fish
end
