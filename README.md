# Dotfiles

Personal dotfiles for macOS and Linux, managed with [just](https://github.com/casey/just).

## What's Included

| Tool | Description |
|------|-------------|
| **Fish** | Primary shell with modular conf.d structure |
| **Neovim** | Editor with lazy.nvim plugin manager |
| **Ghostty** | Primary terminal emulator |
| **Starship** | Cross-shell prompt |
| **Tmux** | Terminal multiplexer |

## Quick Start

```bash
# Install just (task runner)
brew install just

# Clone the repo
git clone https://github.com/iheanyi/dotfiles.git ~/development/dotfiles
cd ~/development/dotfiles

# Full installation (Homebrew, packages, symlinks)
just install

# Or just link configs (if tools already installed)
just link
```

## Available Commands

```bash
just              # Show all available recipes
just install      # Full installation on new machine
just link         # Symlink all configs to ~
just update       # Update all packages and plugins
just check        # Verify tools are installed
just backup-brew  # Export current brew packages to Brewfile
```

## Directory Structure

```
dotfiles/
├── config.fish           # Main fish config
├── fish/
│   ├── conf.d/           # Modular fish configuration
│   │   ├── path.fish     # PATH additions
│   │   ├── env.fish      # Environment variables
│   │   ├── ssh-agent.fish
│   │   └── abbreviations.fish
│   └── functions/        # Fish functions (git aliases, utilities)
├── init.lua              # Neovim config (lazy.nvim)
├── lua/config/           # Neovim modules
│   ├── options.lua
│   ├── keymaps.lua
│   └── autocmds.lua
├── ghostty/config        # Terminal config
├── starship.toml         # Prompt config
├── .tmux.conf
├── justfile              # Task runner recipes
└── Brewfile              # Homebrew packages
```

## Customization

### Private Configuration

Create `~/.private.fish` for machine-specific or sensitive configuration:

```fish
# ~/.private.fish - not tracked in git
set -gx GITHUB_TOKEN "your-token"
set -gx WORK_DIR ~/work
```

See `.private.fish.example` for a template.

### Adding Packages

Edit `Brewfile` and run:

```bash
just install-packages
```

Or add packages manually and update the Brewfile:

```bash
brew install <package>
just backup-brew
```

## Platform Support

- **macOS**: Full support (primary platform)
- **Linux**: Supported with automatic path detection

The fish configuration automatically detects the OS and adjusts paths accordingly.

## Key Bindings

### Fish Shell
- `Ctrl+R` - Fuzzy search history (via atuin/fzf)
- `Ctrl+T` - Fuzzy find files
- Git abbreviations: `gs` (status), `gc` (commit), `gp` (push), etc.

### Neovim
- Leader: `,`
- `<leader>ff` - Find files
- `<leader>fg` - Live grep
- `<leader>e` - File explorer

### Tmux
- Prefix: `Ctrl+a`
- `<prefix>|` - Split vertical
- `<prefix>-` - Split horizontal
- `hjkl` - Pane navigation
