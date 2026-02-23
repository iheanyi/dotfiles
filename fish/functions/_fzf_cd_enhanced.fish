# Enhanced FZF directory switcher with inline navigation.
# Replaces the default fzf Alt+C widget (rebound to Ctrl+G in config.fish).
#
# Instead of a flat directory picker, this lets you navigate the filesystem
# without leaving fzf — go up, drill down, jump to repo root, or switch
# to file search mode.
#
# Keybindings inside fzf:
#   Ctrl+U  - Go up to parent directory
#   Ctrl+G  - Drill into the highlighted directory
#   Ctrl+R  - Jump to the git repo root (nearest .git; no-op outside a repo)
#   Ctrl+T  - Switch to file search within the highlighted directory
#   Enter   - cd into the highlighted directory
#   Escape  - Cancel
#
# Accepts an optional starting directory argument (used by other widgets).
function _fzf_cd_enhanced --description "FZF directory switcher with navigation"
    # Start from the given directory, or pwd if none provided
    set -l base (pwd)
    if test (count $argv) -ge 1; and test -d "$argv[1]"
        set base "$argv[1]"
    end

    while true
        # fd returns paths relative to --base-directory, so we can compose
        # them with $base for cd and drill-down operations.
        set -l result ( \
            fd --type d --hidden --follow --exclude .git --base-directory "$base" 2>/dev/null | \
            fzf --height 40% --layout=reverse --border \
                --header "^U:up ^G:into ^R:root ^T:files | $base" \
                --expect ctrl-u,ctrl-g,ctrl-r,ctrl-t \
        )

        # Empty result means the user hit Escape
        if test (count $result) -eq 0
            break
        end

        # --expect puts the intercepted key in result[1] and the selection in result[2]
        set -l key $result[1]
        set -l selected
        if test (count $result) -ge 2
            set selected $result[2]
        end

        if test "$key" = "ctrl-u"
            # Navigate up one level
            set base (dirname "$base")
        else if test "$key" = "ctrl-g"; and test -n "$selected"
            # Drill into the highlighted directory and re-run fzf there
            set base "$base/$selected"
        else if test "$key" = "ctrl-r"
            # Jump to the nearest git repo root. Uses git itself to find it,
            # so this is a no-op if we're not inside a repo.
            set -l root (git -C "$base" rev-parse --show-toplevel 2>/dev/null)
            if test -n "$root"
                set base "$root"
            end
        else if test "$key" = "ctrl-t"
            # Hand off to the file finder, starting in the highlighted
            # directory (or the current base if nothing is highlighted).
            set -l search_dir "$base"
            if test -n "$selected"
                set search_dir "$base/$selected"
            end
            _fzf_file_enhanced "$search_dir"
            break
        else
            # Enter pressed — cd into the selected directory
            if test -n "$selected"
                cd "$base/$selected"
            end
            break
        end
    end
    commandline -f repaint
end
