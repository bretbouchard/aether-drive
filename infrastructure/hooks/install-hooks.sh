#!/bin/bash

###############################################################################
# Install Documentation Organization Hooks
#
# Installs pre-commit hooks to enforce documentation organization
###############################################################################

set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Installing documentation organization hooks...${NC}"

# Get the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Copy the pre-commit hook
cp "$SCRIPT_DIR/pre-commit-docs.sh" "$PROJECT_ROOT/.git/hooks/pre-commit"
chmod +x "$PROJECT_ROOT/.git/hooks/pre-commit"

echo -e "${GREEN}✅ Pre-commit hook installed!${NC}"
echo ""
echo "The hook will prevent .md files from being committed to root directory"
echo "(except README.md, CHANGELOG.md, CONTRIBUTING.md, LICENSE)"
echo ""
echo "To remove this hook later:"
echo "  rm .git/hooks/pre-commit"
