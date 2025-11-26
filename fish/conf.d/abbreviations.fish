# Abbreviations - expand inline, more fish-idiomatic than aliases
if status is-interactive
    # Ruby/Rails
    abbr -a rubo "bundle exec rubocop -a --cache true --server"
    abbr -a be "bundle exec"
    abbr -a rc "bundle exec rails console"
    abbr -a rs "bundle exec rails server"

    # Git shortcuts
    abbr -a g git
    abbr -a ga "git add"
    abbr -a gc "git commit"
    abbr -a gcm "git commit -m"
    abbr -a gco "git checkout"
    abbr -a gd "git diff"
    abbr -a gp "git push"
    abbr -a gpl "git pull"
    abbr -a gs "git status"
    abbr -a gl "git log --oneline"

    # Common commands
    abbr -a ll "ls -la"
    abbr -a la "ls -a"
    abbr -a .. "cd .."
    abbr -a ... "cd ../.."
end
