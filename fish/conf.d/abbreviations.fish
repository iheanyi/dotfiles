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

    # Common commands
    abbr -a ll "ls -la"
    abbr -a la "ls -a"
    abbr -a .. "cd .."
    abbr -a ... "cd ../.."
end
