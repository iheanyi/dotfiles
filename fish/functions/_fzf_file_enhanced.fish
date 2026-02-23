# Enhanced FZF file finder with inline navigation.
# Replaces the default fzf Ctrl+T widget (rebound in config.fish).
#
# Instead of a flat file picker, this lets you navigate the filesystem
# without leaving fzf — go up, switch into a subdirectory, or jump to
# the repo root, all while staying in file search mode.
#
# Keybindings inside fzf:
#   Ctrl+U  - Go up to parent directory
#   Ctrl+G  - Open a directory picker to drill into, then resume file search
#   Ctrl+R  - Jump to the git repo root (nearest .git; no-op outside a repo)
#   Enter   - Insert the selected file path onto the command line
#   Escape  - Cancel
#
# Accepts an optional starting directory argument (used by _fzf_cd_enhanced
# when handing off via Ctrl+T).
function _fzf_file_enhanced --description "FZF file finder with navigation"
    # Start from the given directory, or pwd if none provided
    set -l base (pwd)
    if test (count $argv) -ge 1; and test -d "$argv[1]"
        set base "$argv[1]"
    end

    while true
        # fd returns paths relative to --base-directory, so we can compose
        # them with $base for the final path.
        set -l result ( \
            fd --type f --hidden --follow --exclude .git --base-directory "$base" 2>/dev/null | \
            fzf --height 40% --layout=reverse --border \
                --header "^U:up ^G:pick dir ^R:root | $base" \
                --expect ctrl-u,ctrl-g,ctrl-r \
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
        else if test "$key" = "ctrl-g"
            # Open a mini directory picker so the user can drill into a
            # subdirectory, then loop back to show files from there.
            set -l dir ( \
                fd --type d --hidden --follow --exclude .git --base-directory "$base" 2>/dev/null | \
                fzf --height 40% --layout=reverse --border \
                    --header "Pick directory | $base" \
            )
            if test -n "$dir"
                set base "$base/$dir"
            end
        else if test "$key" = "ctrl-r"
            # Jump to the nearest git repo root. Uses git itself to find it,
            # so this is a no-op if we're not inside a repo.
            set -l root (git -C "$base" rev-parse --show-toplevel 2>/dev/null)
            if test -n "$root"
                set base "$root"
            end
        else
            # Enter pressed — insert the file path at the cursor position
            if test -n "$selected"
                commandline -it -- "$base/$selected"
            end
            break
        end
    end
    commandline -f repaint
end
