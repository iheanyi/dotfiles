# Copy file contents with path header to clipboard for sharing with Claude
# Usage: claude-file <file> [file2] [file3] ...
# Examples:
#   claude-file src/main.go
#   claude-file src/main.go src/utils.go
function claude-file
    if test (count $argv) -eq 0
        echo "Usage: claude-file <file> [file2] ..."
        return 1
    end

    set -l first_file 1

    for file in $argv
        if not test -f $file
            echo "File not found: $file"
            return 1
        end

        # Get git-relative path if in a repo, otherwise use the provided path
        set -l display_path $file
        if git rev-parse --git-dir >/dev/null 2>&1
            set -l git_root (git rev-parse --show-toplevel)
            set -l abs_path (realpath $file)
            set display_path (string replace "$git_root/" "" $abs_path)
        end

        # Add file with header, separated by blank lines
        if test $first_file -eq 0
            echo
            echo
        end
        echo "// $display_path"
        command cat $file
        set first_file 0
    end | pbcopy
    echo "Copied "(count $argv)" file(s) to clipboard"
end
