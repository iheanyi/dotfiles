# PATH additions - only add paths that exist
# fish_add_path handles deduplication automatically

# Cross-platform Homebrew detection
switch (uname)
    case Darwin
        # macOS - check both Intel and Apple Silicon paths
        for brew_path in /opt/homebrew/bin /usr/local/bin
            test -d $brew_path; and fish_add_path $brew_path
        end
        test -d /opt/homebrew/sbin; and fish_add_path /opt/homebrew/sbin
        test -d /opt/homebrew/opt/openjdk/bin; and fish_add_path /opt/homebrew/opt/openjdk/bin
        test -d /Applications/Ghostty.app/Contents/MacOS; and fish_add_path /Applications/Ghostty.app/Contents/MacOS
    case Linux
        # Linux - Linuxbrew path
        test -d /home/linuxbrew/.linuxbrew/bin; and fish_add_path /home/linuxbrew/.linuxbrew/bin
        test -d /home/linuxbrew/.linuxbrew/sbin; and fish_add_path /home/linuxbrew/.linuxbrew/sbin
end

# Common paths (cross-platform)
for p in \
    $HOME/development/go/bin \
    $HOME/.local/bin \
    $HOME/.cargo/bin \
    $HOME/.humanlog/bin \
    $HOME/.bun/bin \
    $HOME/.antigravity/antigravity/bin
    test -d $p; and fish_add_path $p
end
