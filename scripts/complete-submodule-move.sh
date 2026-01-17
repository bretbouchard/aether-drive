#!/bin/bash

# Complete the submodule move after .gitmodules is updated
set -e

echo "=== Moving Submodule Directories ==="
echo ""

# Ensure target directories exist
mkdir -p juce_backend/effects
mkdir -p juce_backend/instruments

# Move effects
echo "Moving effects..."
for effect in biPhase filtergate AetherDrive monument farfaraway dynamics overdrive_pedal pedals; do
  if [ -d "effects/$effect" ]; then
    echo "  Moving effects/$effect → juce_backend/effects/$effect"
    mv effects/$effect juce_backend/effects/
  fi
done

# Move instruments (skip localgal - it's already there with ios-auv3)
echo "Moving instruments..."
for instrument in kane_marco giant_instruments drummachine Nex_synth Sam_sampler; do
  if [ -d "instruments/$instrument" ]; then
    echo "  Moving instruments/$instrument → juce_backend/instruments/$instrument"
    mv instruments/$instrument juce_backend/instruments/
  fi
done

# Remove empty directories
rmdir effects 2>/dev/null && echo "✓ Removed empty effects/" || true

# localgal stays (has ios-auv3)
echo "✓ instruments/ remains (contains localgal with ios-auv3)"

echo ""
echo "=== Updating Git Index ==="
echo ""

# Remove old paths from git index
git rm --cached effects/biPhase effects/filtergate effects/AetherDrive effects/monument effects/farfaraway effects/dynamics effects/overdrive_pedal effects/pedals 2>/dev/null || true
git rm --cached instruments/kane_marco instruments/giant_instruments instruments/drummachine instruments/Nex_synth instruments/Sam_sampler 2>/dev/null || true

# Add new paths
git add juce_backend/effects/* juce_backend/instruments/*

echo ""
echo "=== Syncing Submodules ==="
echo ""

git submodule sync --recursive
git submodule update --init --recursive

echo ""
echo "✅ Submodule migration complete!"
echo ""
echo "Next steps:"
echo "1. Check: git status"
echo "2. Check: git submodule status"
echo "3. Commit changes"
