function tailscale --wraps=tailscale --description 'Run the Tailscale CLI for the current platform'
    if test (uname) = Darwin; and test -x /Applications/Tailscale.app/Contents/MacOS/Tailscale
        command /Applications/Tailscale.app/Contents/MacOS/Tailscale $argv
    else
        command tailscale $argv
    end
end
