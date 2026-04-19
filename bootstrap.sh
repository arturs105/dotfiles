#!/usr/bin/env bash
#
# Idempotent — safe to run multiple times.
# Existing non-symlink files are backed up with a timestamped suffix.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
    local src="$1"
    local dest="$2"

    if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
        echo "✓ $dest (already linked)"
        return
    fi

    if [[ -e "$dest" || -L "$dest" ]]; then
        local backup="$dest.backup-$(date +%Y%m%d-%H%M%S)"
        mv "$dest" "$backup"
        echo "  backed up existing $dest -> $backup"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    echo "✓ $dest -> $src"
}

echo "Linking from $DOTFILES"
echo ""

# Shell
link "$DOTFILES/zshrc"    "$HOME/.zshrc"
link "$DOTFILES/zprofile" "$HOME/.zprofile"

# Git
link "$DOTFILES/gitconfig" "$HOME/.gitconfig"

# Vim
link "$DOTFILES/vimrc" "$HOME/.vimrc"
link "$DOTFILES/vim"   "$HOME/.vim"

# Tmux
link "$DOTFILES/tmux.conf" "$HOME/.tmux.conf"

# Claude Code
mkdir -p "$HOME/.claude"
link "$DOTFILES/claude/settings.json" "$HOME/.claude/settings.json"
link "$DOTFILES/claude/CLAUDE.md"     "$HOME/.claude/CLAUDE.md"
link "$DOTFILES/claude/agents"        "$HOME/.claude/agents"
link "$DOTFILES/claude/hooks"         "$HOME/.claude/hooks"
link "$DOTFILES/claude/skills"        "$HOME/.claude/skills"

echo ""
echo "Done."
echo ""
echo "Next steps (if not already set up on this machine):"
echo "  1. Install Homebrew:  https://brew.sh"
echo "  2. Install Oh My Zsh: https://ohmyz.sh"
echo "     (run BEFORE opening a new shell — OMZ's installer overwrites ~/.zshrc,"
echo "      but this script already linked yours, so you'll be prompted)"
echo "  3. Create ~/.secrets with any API keys (see zprofile for the loader)"
echo "  4. Open a new terminal tab to pick up the new config"
