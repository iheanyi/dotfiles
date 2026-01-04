# Copy git diff to clipboard for sharing with Claude
# Usage: claude-diff [git diff args]
# Examples:
#   claude-diff              # staged + unstaged changes
#   claude-diff --staged     # only staged changes
#   claude-diff HEAD~3       # last 3 commits
function claude-diff
    set -l diff_output

    if test (count $argv) -eq 0
        # Default: show both staged and unstaged
        set diff_output (git diff HEAD 2>/dev/null)
    else
        set diff_output (git diff $argv 2>/dev/null)
    end

    if test -z "$diff_output"
        echo "No changes to copy"
        return 1
    end

    echo $diff_output | pbcopy
    set -l lines (echo $diff_output | wc -l | string trim)
    echo "Copied $lines lines of diff to clipboard"
end
