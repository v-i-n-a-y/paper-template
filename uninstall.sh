#!/usr/bin/env bash
# uninstall.sh — remove the installed new-paper command and template data.
set -euo pipefail

INSTALL_BIN="${HOME}/.local/bin"
INSTALL_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/paper-template"

removed=0

if [[ -f "$INSTALL_BIN/new-paper" ]]; then
    rm "$INSTALL_BIN/new-paper"
    printf '  \033[36m[removed]\033[0m %s/new-paper\n' "$INSTALL_BIN"
    removed=1
fi

if [[ -d "$INSTALL_DATA" ]]; then
    rm -rf "$INSTALL_DATA"
    printf '  \033[36m[removed]\033[0m %s\n' "$INSTALL_DATA"
    removed=1
fi

if [[ $removed -eq 0 ]]; then
    echo "Nothing to remove — paper-template does not appear to be installed."
else
    echo "Uninstalled."
fi
