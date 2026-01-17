#!/bin/bash

# Script to move effects/instruments submodules from root to juce_backend
# This is a delicate operation - please review before running

set -e  # Exit on error

echo "=== Submodule Migration Script ==="
echo "This will move effects/ and instruments/ submodules to juce_backend/"
echo ""
echo "Backup branch: backup-before-submodule-move"
echo ""

# Check we're in the right place
if [ ! -f ".gitmodules" ]; then
  echo "Error: .gitmodules not found. Are you in the repo root?"
  exit 1
fi

# Check clean state
if [ -n "$(git status --porcelain)" ]; then
  echo "Warning: You have uncommitted changes."
  echo "Please commit or stash them before proceeding."
  git status
  exit 1
fi

echo "Step 1: Moving effects submodules..."
echo "======================================"

# List of effect submodules
effects="biPhase filtergate AetherDrive monument farfaraway dynamics overdrive_pedal pedals"

for effect in $effects; do
  echo "Processing: effects/$effect"

  # Check if it exists
  if [ ! -d "effects/$effect" ]; then
    echo "  Warning: effects/$effect not found, skipping..."
    continue
  fi

  # Get URL and branch from current .gitmodules
  url=$(git config --file .gitmodules --get submodule.effects.$effect.url)
  branch=$(git config --file .gitmodules --get submodule.effects.$effect.branch || echo "main")

  if [ -z "$url" ]; then
    echo "  Warning: No URL found for effects/$effect, skipping..."
    continue
  fi

  echo "  URL: $url"
  echo "  Branch: $branch"

  # Deinitialize and remove from root
  git submodule deinit -f effects/$effect
  git rm -f effects/$effect

  # Move the directory
  mv effects/$effect juce_backend/effects/

  # Add to juce_backend
  cd juce_backend
  git submodule add -b $branch $url effects/$effect
  cd ..

  echo "  ✓ Moved effects/$effect to juce_backend/effects/$effect"
  echo ""
done

echo "Step 2: Moving instruments submodules..."
echo "=========================================="

# List of instrument submodules
instruments="kane_marco giant_instruments drummachine Nex_synth Sam_sampler localgal"

for instrument in $instruments; do
  echo "Processing: instruments/$instrument"

  # Check if it exists
  if [ ! -d "instruments/$instrument" ]; then
    echo "  Warning: instruments/$instrument not found, skipping..."
    continue
  fi

  # Get URL and branch from current .gitmodules
  url=$(git config --file .gitmodules --get submodule.instruments.$instrument.url)
  branch=$(git config --file .gitmodules --get submodule.instruments.$instrument.branch || echo "main")

  if [ -z "$url" ]; then
    echo "  Warning: No URL found for instruments/$instrument, skipping..."
    continue
  fi

  echo "  URL: $url"
  echo "  Branch: $branch"

  # Deinitialize and remove from root
  git submodule deinit -f instruments/$instrument
  git rm -f instruments/$instrument

  # Move the directory
  mv instruments/$instrument juce_backend/instruments/

  # Add to juce_backend
  cd juce_backend
  git submodule add -b $branch $url instruments/$instrument
  cd ..

  echo "  ✓ Moved instruments/$instrument to juce_backend/instruments/$instrument"
  echo ""
done

echo "Step 3: Cleaning up..."
echo "======================"

# Remove empty directories if they exist
rmdir effects 2>/dev/null && echo "✓ Removed empty effects/ directory" || echo "  effects/ not empty or doesn't exist"
rmdir instruments 2>/dev/null && echo "✓ Removed empty instruments/ directory" || echo "  instruments/ not empty or doesn't exist"

echo ""
echo "Step 4: Syncing submodules..."
echo "============================"

git submodule sync --recursive
git submodule update --init --recursive

echo ""
echo "✅ Submodule migration complete!"
echo ""
echo "Please verify:"
echo "  1. Check git status"
echo "  2. Run: git submodule status"
echo "  3. Update CMakeLists.txt paths"
echo "  4. Test the build"
echo ""
echo "Then commit with:"
echo '  git commit -m "refactor: Move effects/instruments submodules to juce_backend"'
