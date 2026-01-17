#!/bin/bash

###############################################################################
# Pre-commit Hook: Documentation Organization Enforcement
#
# Prevents .md files from being committed to the root directory
# Ensures all documentation lives in docs/
###############################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# Get list of staged .md files in root
ROOT_MD_FILES=$(git diff --cached --name-only | grep -E "^[^/]+\.md$" || true)

# Allow these files in root
ALLOWED_ROOT_FILES="README.md|CHANGELOG.md|CONTRIBUTING.md|LICENSE"

if [ -n "$ROOT_MD_FILES" ]; then
    echo -e "${RED}❌ Documentation organization error detected!${NC}"
    echo ""
    echo "The following markdown files are in the root directory:"
    echo "$ROOT_MD_FILES" | while read -r file; do
        if [[ ! "$file" =~ ^($ALLOWED_ROOT_FILES)$ ]]; then
            echo -e "  ${RED}✗${NC} $file"
        fi
    done
    echo ""
    echo -e "${YELLOW}Documentation policy:${NC}"
    echo "  - All documentation must be in docs/ directory"
    echo "  - Only these files allowed in root: $ALLOWED_ROOT_FILES"
    echo ""
    echo -e "${YELLOW}How to fix:${NC}"
    echo "  1. Move files to appropriate docs/ subdirectory:"
    echo "     • Architecture → docs/architecture/"
    echo "     • Development → docs/development/"
    echo "     • User guides → docs/user/"
    echo "     • Reference → docs/reference/"
    echo "     • Archive → docs/archive/"
    echo ""
    echo "  2. Update docs/README.md if adding new categories"
    echo "  3. Stage the moved files: git add docs/"
    echo "  4. Unstage root files: git reset HEAD <filename>"
    echo ""
    echo -e "${YELLOW}Example:${NC}"
    echo "  mkdir -p docs/development"
    echo "  mv MY_FILE.md docs/development/"
    echo "  git add docs/development/MY_FILE.md"
    echo "  git reset HEAD MY_FILE.md"
    echo ""
    echo -e "${GREEN}For documentation organization help, see:${NC}"
    echo "  docs/README.md"
    echo ""
    exit 1
fi

# Check for files that should be in docs/ but aren't
NEW_DOC_FILES=$(git diff --cached --name-only --diff-filter=A | grep "\.md$" || true)

if [ -n "$NEW_DOC_FILES" ]; then
    echo "$NEW_DOC_FILES" | while read -r file; do
        # Skip if in docs/ or allowed root files
        if [[ "$file" == docs/* ]] || [[ "$file" =~ ^($ALLOWED_ROOT_FILES)$ ]]; then
            continue
        fi

        # Check if it looks like documentation
        if [[ "$file" =~ \.md$ ]]; then
            echo -e "${YELLOW}⚠️  Warning: $file${NC}"
            echo "    This markdown file is not in docs/ directory"
            echo "    Are you sure it belongs in root? If not, move it to docs/"
        fi
    done
fi

exit 0
