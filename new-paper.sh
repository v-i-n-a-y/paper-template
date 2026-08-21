#!/usr/bin/env bash
# new-paper — create a new paper from the template.
#
# No-install usage (run directly from the cloned repo):
#   ./new-paper.sh <name> [destination]
#
# After running install.sh:
#   new-paper <name> [destination]
#
set -euo pipefail

# ── Locate template ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -f "$SCRIPT_DIR/Makefile" && -f "$SCRIPT_DIR/.env" ]]; then
    # Running directly from the cloned template repo.
    DEFAULT_TEMPLATE="$SCRIPT_DIR"
else
    # Running as an installed command — template was copied to XDG data dir.
    DEFAULT_TEMPLATE="${XDG_DATA_HOME:-$HOME/.local/share}/paper-template"
fi

# ── Argument parsing ──────────────────────────────────────────────────────────
TEMPLATE_DIR="$DEFAULT_TEMPLATE"
NAME=""
DEST="."

usage() {
    cat <<EOF
Usage: $(basename "$0") [--template DIR] <name> [destination]

  name           Paper name — used as the directory name and PAPER_NAME in .env
  destination    Parent directory in which to create the paper (default: .)
  --template     Override the template directory
  --help         Show this help

Examples:
  $(basename "$0") my-paper                 creates ./my-paper/
  $(basename "$0") my-paper ~/papers        creates ~/papers/my-paper/
  $(basename "$0") --template /t my-paper . use a custom template
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --template|-t) TEMPLATE_DIR="$2"; shift 2 ;;
        --help|-h)     usage; exit 0 ;;
        -*)            echo "Unknown option: $1"; usage; exit 1 ;;
        *)
            if   [[ -z "$NAME" ]]; then NAME="$1"
            elif [[ "$DEST" == "." ]]; then DEST="$1"
            else echo "Unexpected argument: $1"; usage; exit 1
            fi
            shift ;;
    esac
done

if [[ -z "$NAME" ]]; then
    usage; exit 1
fi

TARGET="$(cd "$DEST" 2>/dev/null && pwd || mkdir -p "$DEST" && cd "$DEST" && pwd)/$NAME"

# ── Validate ──────────────────────────────────────────────────────────────────
if [[ ! -d "$TEMPLATE_DIR" ]]; then
    echo "Error: template not found at $TEMPLATE_DIR"
    [[ "$TEMPLATE_DIR" != "$DEFAULT_TEMPLATE" ]] || \
        echo "Hint:  run install.sh first, or pass --template <path>"
    exit 1
fi

if [[ -d "$TARGET" ]]; then
    echo "Error: $TARGET already exists"
    exit 1
fi

# ── Copy template (exclude scaffold scripts and git history) ───────────────────
mkdir -p "$TARGET"
if command -v rsync &>/dev/null; then
    rsync -a \
        --exclude='.git' \
        --exclude='new-paper.sh' \
        --exclude='install.sh' \
        --exclude='uninstall.sh' \
        "$TEMPLATE_DIR/" "$TARGET/"
else
    cp -r "$TEMPLATE_DIR/." "$TARGET/"
    rm -rf "$TARGET/.git" "$TARGET/new-paper.sh" "$TARGET/install.sh" "$TARGET/uninstall.sh"
fi

cd "$TARGET"

# ── Configure ─────────────────────────────────────────────────────────────────
python3 - <<PYEOF
import re, pathlib
p = pathlib.Path('.env')
p.write_text(re.sub(r'^PAPER_NAME=.*', 'PAPER_NAME=$NAME', p.read_text(), flags=re.M))
PYEOF

echo "1.0" > .version

# ── Git init ──────────────────────────────────────────────────────────────────
git init -q
git add .
git commit -q -m "Initial scaffold: $NAME"

# ── Done ──────────────────────────────────────────────────────────────────────
printf '\nCreated \033[36m%s\033[0m\n' "$TARGET"
printf '  cd %s\n' "$TARGET"
printf '  make pdf      # build at current version\n'
printf '  make draft    # bump version and archive to drafts/\n'
printf '  make setup    # install LaTeX tools if needed\n'
