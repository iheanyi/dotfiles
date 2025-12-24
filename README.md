# Dotfiles

Personal dotfiles for macOS and Linux, managed with [just](https://github.com/casey/just).

## What's Included

| Tool | Description |
|------|-------------|
| **Fish** | Primary shell with modular conf.d structure |
| **Neovim** | Editor with lazy.nvim plugin manager |
| **Ghostty** | Primary terminal emulator |
| **Starship** | Cross-shell prompt with language indicators |
| **Tmux** | Terminal multiplexer with TPM |

### Modern CLI Tools

These dotfiles include configuration for modern CLI replacements ([reference](https://remysharp.com/2018/08/23/cli-improved)):

| Tool | Replaces | Description |
|------|----------|-------------|
| `bat` | cat | Syntax highlighting, line numbers |
| `fd` | find | Fast file search |
| `rg` (ripgrep) | grep | Fast text search |
| `zoxide` | cd/autojump | Smarter directory jumping |
| `htop` | top | Interactive process viewer |
| `ncdu` | du | Interactive disk usage |
| `tldr` | man | Simplified man pages |
| `delta` | diff | Better git diffs (side-by-side, syntax highlighting) |

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

# Check everything is working
just doctor
```

## Available Commands

```bash
just                    # Show all available recipes
just install            # Full installation on new machine
just link               # Symlink all configs to ~
just update             # Update all packages and plugins
just check              # Verify tools are installed
just doctor             # Diagnose common issues
just backup-brew        # Export current brew packages to Brewfile
```

## Directory Structure

```
dotfiles/
├── config.fish           # Main fish config
├── fish/
│   ├── conf.d/           # Modular fish configuration
│   │   ├── path.fish     # PATH additions (cross-platform)
│   │   ├── env.fish      # Environment variables
│   │   ├── ssh-agent.fish
│   │   └── abbreviations.fish
│   └── functions/        # Fish functions (git aliases, utilities)
├── init.lua              # Neovim config (lazy.nvim)
├── lua/config/           # Neovim modules
├── ghostty/config        # Terminal config
├── starship.toml         # Prompt config
├── .tmux.conf            # Tmux config
├── .gitconfig            # Git config with aliases
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

### Git Configuration

The `.gitconfig` uses `delta` for better diffs (side-by-side view, syntax highlighting). Personal settings (name, email) should go in `~/.gitconfig.local`:

```gitconfig
# ~/.gitconfig.local
[user]
    name = Your Name
    email = your@email.com
```

### SSH Configuration

Copy `.ssh_config.example` to `~/.ssh/config` and customize:

```bash
mkdir -p ~/.ssh/sockets
cp .ssh_config.example ~/.ssh/config
chmod 600 ~/.ssh/config
```

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
- `z <dir>` - Smart directory jump (zoxide)
- Git abbreviations: `gs` (status), `gc` (commit), `gp` (push), etc.

### Neovim
- Leader: `,`
- `<leader>ff` - Find files
- `<leader>fg` - Live grep
- `<leader>e` / `-` - File explorer (oil.nvim - edit filesystem like a buffer)

### Ghostty
- `Cmd+`` ` - Quick terminal toggle (quake-style dropdown)
- `Cmd+D` - Split down
- `Cmd+Shift+D` - Split right
- `Cmd+Shift+Arrow` - Navigate splits
- `Cmd+Shift+Enter` - Zoom split

### Tmux
- Prefix: `Ctrl+a`
- `<prefix>"` - Split horizontal
- `<prefix>%` - Split vertical
- `<prefix>h/j/k/l` - Pane navigation
- `<prefix>r` - Reload config
- `Shift+Left/Right` - Switch windows
- `<prefix>[` then `v` to select, `y` to yank (vi copy mode)

### Git Aliases (from .gitconfig)
- `git s` - Short status
- `git lg` - Pretty log graph
- `git co` - Checkout
- `git cm "msg"` - Commit with message
- `git undo` - Undo last commit
- `n`/`N` in diffs - Jump between sections (delta)
