#!/bin/sh
# Install git hooks

set -e

SCRIPT_DIR="$(dirname "$0")"
GIT_DIR="$(git rev-parse --git-dir)"

echo "Installing git hooks..."

# Configure git to use our hooks directory
git config core.hooksPath "$SCRIPT_DIR"

echo "Git hooks installed successfully!"
echo "Hooks directory: $SCRIPT_DIR"
