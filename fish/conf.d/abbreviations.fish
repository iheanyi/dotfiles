# Abbreviations - expand inline, more fish-idiomatic than aliases
if status is-interactive
    # Git abbreviations (200+ shortcuts from __git.init)
    # See fish/functions/__git.init.fish for full list
    type -q __git.init; and __git.init

    # Ruby/Rails
    abbr -a rubo "bundle exec rubocop -a --cache true --server"
    abbr -a be "bundle exec"
    abbr -a rc "bundle exec rails console"
    abbr -a rs "bundle exec rails server"

    # Common commands - eza as ls replacement
    abbr -a ls eza
    abbr -a ll "eza -la --git"
    abbr -a la "eza -a"
    abbr -a lt "eza --tree --level=2"
    abbr -a .. "cd .."
    abbr -a ... "cd ../.."

    # Homebrew - always upgrade everything to avoid dependency mismatches
    abbr -a bu "brew upgrade"
    abbr -a buc "brew upgrade && brew cleanup"

    # LazyGit
    abbr -a lg lazygit

    # Claude / AI tools
    abbr -a cn claude                                              # New session
    abbr -a cr "claude --resume"                                   # Resume last
    abbr -a cc "claude --continue"                                 # Continue last
    abbr -a cy "claude --dangerously-skip-permissions"             # Yolo mode
    abbr -a cry "claude --resume --dangerously-skip-permissions"   # Resume yolo
    abbr -a ccy "claude --continue --dangerously-skip-permissions" # Continue yolo
end
