# PATH additions - only add paths that exist
# fish_add_path handles deduplication automatically

for p in \
    $HOME/development/go/bin \
    /opt/homebrew/bin \
    /opt/homebrew/sbin \
    /opt/homebrew/opt/openjdk/bin \
    /Applications/Ghostty.app/Contents/MacOS \
    $HOME/.local/bin \
    $HOME/.humanlog/bin \
    $HOME/.bun/bin \
    $HOME/.antigravity/antigravity/bin
    test -d $p; and fish_add_path $p
end
