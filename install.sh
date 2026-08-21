#!/usr/bin/env bash
# install.sh — install new-paper to ~/.local/bin and the template to ~/.local/share.
# After running this, 'new-paper <name> [dest]' works from anywhere.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INSTALL_BIN="${HOME}/.local/bin"
INSTALL_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/paper-template"

echo "Installing paper-template..."

# Copy template files (exclude scaffold scripts and git history)
mkdir -p "$INSTALL_DATA"
if command -v rsync &>/dev/null; then
    rsync -a --delete \
        --exclude='.git' \
        --exclude='new-paper.sh' \
        --exclude='install.sh' \
        --exclude='uninstall.sh' \
        "$SCRIPT_DIR/" "$INSTALL_DATA/"
else
    cp -r "$SCRIPT_DIR/." "$INSTALL_DATA/"
    rm -rf "$INSTALL_DATA/.git" "$INSTALL_DATA/new-paper.sh" \
           "$INSTALL_DATA/install.sh" "$INSTALL_DATA/uninstall.sh"
fi
printf '  \033[36m[template]\033[0m %s\n' "$INSTALL_DATA"

# Install the new-paper command
mkdir -p "$INSTALL_BIN"
cp "$SCRIPT_DIR/new-paper.sh" "$INSTALL_BIN/new-paper"
chmod +x "$INSTALL_BIN/new-paper"
printf '  \033[36m[command] \033[0m %s/new-paper\n' "$INSTALL_BIN"

# PATH warning
if [[ ":$PATH:" != *":$INSTALL_BIN:"* ]]; then
    printf '\n  \033[33mWarning:\033[0m %s is not in your PATH.\n' "$INSTALL_BIN"
    printf '  Add this to your shell profile (~/.bashrc, ~/.zshrc, or ~/.config/fish/config.fish):\n\n'
    printf '    # bash/zsh\n'
    printf '    export PATH="$HOME/.local/bin:$PATH"\n\n'
    printf '    # fish\n'
    printf '    fish_add_path ~/.local/bin\n'
fi

printf '\n\033[1mDone.\033[0m\n'
printf '  new-paper <name>              create paper in current directory\n'
printf '  new-paper <name> ~/papers     create paper in ~/papers/\n'
printf '  new-paper --help              show all options\n'
