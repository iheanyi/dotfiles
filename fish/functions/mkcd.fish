# Create directory and cd into it
function mkcd --description "Create directory and cd into it"
    if test (count $argv) -eq 0
        echo "Usage: mkcd <directory>"
        return 1
    end
    mkdir -p $argv[1]; and cd $argv[1]
end
