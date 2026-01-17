#!/bin/bash

# Move effects submodules one at a time
set -e

echo "=== Migrating Effects Submodules ==="
echo ""

# Create target directory
mkdir -p juce_backend/effects

# List of effects
effects="biPhase filtergate AetherDrive monument farfaraway dynamics overdrive_pedal pedals"

for effect in $effects; do
  if [ ! -d "effects/$effect" ]; then
    echo "⚠️  effects/$effect not found, skipping..."
    continue
  fi

  echo "📦 Moving: effects/$effect"

  # Get URL
  url=$(git config --file .gitmodules --get submodule.effects.$effect.url)
  if [ -z "$url" ]; then
    echo "  ⚠️  No URL found, skipping..."
    continue
  fi

  # Get branch (default to main)
  branch=$(git config --file .gitmodules --get submodule.effects.$effect.branch || echo "main")

  echo "  URL: $url"
  echo "  Branch: $branch"

  # Deinit from root
  git submodule deinit -f effects/$effect

  # Remove from git index
  git rm -f effects/$effect

  # Move directory
  mv effects/$effect juce_backend/effects/

  # Add to juce_backend
  cd juce_backend
  git submodule add -b $branch $url effects/$effect
  cd ..

  echo "  ✅ Moved effects/$effect → juce_backend/effects/$effect"
  echo ""
done

echo "=== Effects Migration Complete ==="
