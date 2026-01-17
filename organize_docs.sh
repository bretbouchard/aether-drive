#!/bin/bash

###############################################################################
# Documentation Organization Script
#
# Moves all markdown files from root to proper docs/ locations
###############################################################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}📚 Organizing White Room Documentation${NC}"

# Change to root directory
cd "$(dirname "$0")"

# Create directories
echo -e "${YELLOW}Creating directory structure...${NC}"
mkdir -p docs/development/build
mkdir -p docs/development/plugins
mkdir -p docs/development/tracking
mkdir -p docs/development/roadmap
mkdir -p docs/archive/completed-sessions
mkdir -p docs/archive/migrations
mkdir -p docs/reference/plugin-formats
mkdir -p docs/security
mkdir -p docs/architecture/persistence
mkdir -p docs/architecture/submodules

# Move BUILD files
echo -e "${YELLOW}Moving BUILD files to docs/development/build/${NC}"
mv BUILD_AUDIT_REPORT.md docs/development/build/
mv BUILD_COMPLETE_SUCCESS.md docs/development/build/
mv BUILD_COMPLETE.md docs/development/build/
mv BUILD_ORGANIZATION_SUMMARY.md docs/development/build/
mv BUILD_STATUS.md docs/development/build/
mv BUILD_STRUCTURE.md docs/development/build/
mv BUILD_SUCCESS_REPORT.md docs/development/build/
mv FINAL_BUILD_REPORT.md docs/development/build/
mv MULTI_FORMAT_BUILD_STATUS.md docs/development/build/

# Move PLUGIN MIGRATION files
echo -e "${YELLOW}Moving PLUGIN files to docs/development/plugins/${NC}"
mv BIPHASE_PLUGIN_IMPLEMENTATION_COMPLETE.md docs/development/plugins/
mv COMPLETE_MIGRATION_REPORT.md docs/development/plugins/
mv FILTERGATE_MIGRATION_REPORT.md docs/development/plugins/
mv INSTRUMENT_MIGRATION_REQUIREMENTS.md docs/development/plugins/
mv INSTRUMENTS_EFFECTS_STATUS_REPORT.md docs/development/plugins/
mv PLUGIN_MIGRATION_PHASE_1_SUMMARY.md docs/development/plugins/
mv PLUGIN_MIGRATION_PLAN.md docs/development/plugins/
mv PLUGIN_MIGRATION_STATUS.md docs/development/plugins/
mv FINAL_MULTI_FORMAT_REPORT.md docs/development/plugins/

# Move ARCHITECTURE files
echo -e "${YELLOW}Moving ARCHITECTURE files to docs/architecture/${NC}"
mv ARCHITECTURE_FIX_PROGRESS.md docs/architecture/
mv PERSISTENCE_ARCHITECTURE.md docs/architecture/persistence/
mv PERSISTENCE_IMPLEMENTATION_PLAN.md docs/architecture/persistence/
mv SUBMODULE_ARCHITECTURE_ASSESSMENT.md docs/architecture/submodules/
mv SUBMODULE_ARCHITECTURE_FIX_GUIDE.md docs/architecture/submodules/

# Move SESSION/COMPLETION reports
echo -e "${YELLOW}Moving SESSION reports to docs/archive/completed-sessions/${NC}"
mv FINAL_SESSION_COMPLETE.md docs/archive/completed-sessions/
mv SESSION_COMPLETE_SUMMARY.md docs/archive/completed-sessions/
mv PRODUCTION_READINESS_REPORT.md docs/archive/completed-sessions/
mv SUCCESS_REPORT.md docs/archive/completed-sessions/
mv WORKFLOW_SUMMARY.md docs/archive/completed-sessions/

# Move SECURITY files
echo -e "${YELLOW}Moving SECURITY files to docs/security/${NC}"
mv SECURITY_FIXES.md docs/security/

# Move REFERENCE files
echo -e "${YELLOW}Moving REFERENCE files to docs/reference/plugin-formats/${NC}"
mv JUCE_PLUGIN_FORMATS_GUIDE.md docs/reference/plugin-formats/
mv PLUGIN_FORMATS_GUIDE.md docs/reference/plugin-formats/

# Move TRACKING files
echo -e "${YELLOW}Moving TRACKING files to docs/development/tracking/${NC}"
mv BD_ISSUES_MIGRATION_TRACKING.md docs/development/tracking/

# Move NEXT STEPS
echo -e "${YELLOW}Moving NEXT_STEPS to docs/development/roadmap/${NC}"
mv NEXT_STEPS.md docs/development/roadmap/

# Move QUICKSTART
echo -e "${YELLOW}Moving QUICKSTART to docs/user/${NC}"
mv QUICKSTART.md docs/user/quickstart.md

echo -e "${GREEN}✅ Documentation organized successfully!${NC}"
echo ""
echo "Summary:"
echo "  - BUILD files → docs/development/build/"
echo "  - PLUGIN files → docs/development/plugins/"
echo "  - ARCHITECTURE files → docs/architecture/"
echo "  - SESSION reports → docs/archive/completed-sessions/"
echo "  - SECURITY files → docs/security/"
echo "  - REFERENCE files → docs/reference/plugin-formats/"
echo "  - TRACKING files → docs/development/tracking/"
echo "  - NEXT_STEPS → docs/development/roadmap/"
echo "  - QUICKSTART → docs/user/quickstart.md"
echo ""
echo "Root directory now contains only README.md"
