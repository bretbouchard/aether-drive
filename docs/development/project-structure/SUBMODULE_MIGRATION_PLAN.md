# Submodule Migration Plan - Effects & Instruments

**Date:** 2025-01-17
**Status:** Ready to Execute

---

## Executive Summary

The `effects/` and `instruments/` directories are **already submodules** with their own GitHub repositories. They should be moved to `juce_backend/` to create a logical hierarchy where juce_backend manages all audio plugins.

---

## Current Architecture

### Root Level Submodules (Current)
```
white_room/
├── effects/
│   ├── biPhase (submodule)
│   ├── filtergate (submodule)
│   ├── AetherDrive (submodule)
│   ├── monument (submodule)
│   ├── farfaraway (submodule)
│   ├── dynamics (submodule)
│   ├── overdrive_pedal (submodule)
│   └── pedals (submodule)
└── instruments/
    ├── kane_marco (submodule)
    ├── giant_instruments (submodule)
    ├── drummachine (submodule)
    ├── Nex_synth (submodule)
    ├── Sam_sampler (submodule)
    └── localgal (submodule)
```

### juce_backend Submodules (Existing)
```
juce_backend/
├── daid-core (submodule)
├── sdk (submodule)
└── external/JUCE (submodule)
```

---

## Target Architecture

### Unified juce_backend Submodules (Target)
```
juce_backend/
├── effects/
│   ├── biPhase (submodule)
│   ├── filtergate (submodule)
│   ├── AetherDrive (submodule)
│   ├── monument (submodule)
│   ├── farfaraway (submodule)
│   ├── dynamics (submodule)
│   ├── overdrive_pedal (submodule)
│   └── pedals (submodule)
├── instruments/
    ├── kane_marco (submodule)
    ├── giant_instruments (submodule)
    ├── drummachine (submodule)
    ├── Nex_synth (submodule)
    ├── Sam_sampler (submodule)
    └── localgal (submodule)
├── daid-core (submodule)
├── sdk (submodule)
└── external/JUCE (submodule)
```

---

## Migration Strategy

### Phase 1: Preparation (READ ONLY)

1. **Backup Current State**
   ```bash
   git branch backup-before-submodule-move
   git push origin backup-before-submodule-move
   ```

2. **Document Current Submodule URLs**
   - Already documented in `.gitmodules`
   - All submodules have their own repos

3. **Verify No Uncommitted Changes**
   ```bash
   git status
   git submodule status
   ```

### Phase 2: Move Submodules

1. **Create New Structure in juce_backend**
   ```bash
   cd juce_backend
   mkdir -p effects instruments
   ```

2. **Move Submodule Definitions**
   - Update root `.gitmodules` to remove effects/instruments
   - Add to `juce_backend/.gitmodules`
   - Use `git submodule add` with new paths

3. **Physical Move of Submodule Directories**
   ```bash
   # From root
   git submodule deinit -f effects
   git rm -f effects
   mv effects/* juce_backend/effects/

   git submodule deinit -f instruments
   git rm -f instruments
   mv instruments/* juce_backend/instruments/
   ```

4. **Re-register Submodules in juce_backend**
   ```bash
   cd juce_backend
   for dir in effects/* instruments/*; do
     url=$(git config --file ../.gitmodules --get submodule.$dir.url)
     git submodule add $url $dir
   done
   ```

### Phase 3: Update Build System

1. **Update CMakeLists.txt**
   - Change paths: `effects/` → `juce_backend/effects/`
   - Change paths: `instruments/` → `juce_backend/instruments/`

2. **Update Build Scripts**
   - Update any hardcoded paths to effects/instruments

3. **Update IDE Project Files**
   - Regenerate CMake projects
   - Update Xcode/VS Code configurations

### Phase 4: Test and Verify

1. **Submodule Health Check**
   ```bash
   git submodule update --init --recursive
   git submodule status
   ```

2. **Build Test**
   ```bash
   cmake --preset=macos-clang-release
   cmake --build --preset=macos-clang-release
   ```

3. **Plugin Loading Test**
   - Verify all plugins load correctly
   - Test audio processing
   - Check preset loading

### Phase 5: Cleanup

1. **Remove Old Directories**
   ```bash
   rm -rf effects/ instruments/
   ```

2. **Update Documentation**
   - Update any references to old paths
   - Update README files

3. **Commit and Push**
   ```bash
   git add .
   git commit -m "refactor: Move effects/instruments submodules to juce_backend"
   git push origin main
   ```

---

## Detailed Commands

### Step-by-Step Migration

```bash
# 1. Backup
git branch backup-before-submodule-move
git push origin backup-before-submodule-move

# 2. Ensure clean state
git status
git submodule status
git submodule update --init --recursive

# 3. Create target directories
mkdir -p juce_backend/effects juce_backend/instruments

# 4. Document current submodule configurations
cat .gitmodules > /tmp/root-gitmodules-backup.txt
cat juce_backend/.gitmodules > /tmp/juce-gitmodules-backup.txt

# 5. Move effects submodules
cd juce_backend/effects

# For each effect submodule
for effect in biPhase filtergate AetherDrive monument farfaraway dynamics overdrive_pedal pedals; do
  # Get URL from root .gitmodules
  url=$(git config --file ../../.gitmodules --get submodule.effects/$effect.url)
  branch=$(git config --file ../../.gitmodules --get submodule.effects/$effect.branch || echo "main")

  # Remove from root
  cd ../..
  git submodule deinit -f effects/$effect
  git rm -f effects/$effect

  # Move directory
  mv effects/$effect juce_backend/effects/

  # Add to juce_backend
  cd juce_backend
  git submodule add -b $branch $url effects/$effect
  cd ..
done

# 6. Move instruments submodules
cd juce_backend/instruments

# For each instrument submodule
for instrument in kane_marco giant_instruments drummachine Nex_synth Sam_sampler localgal; do
  # Get URL from root .gitmodules
  url=$(git config --file ../../.gitmodules --get submodule.instruments/$instrument.url)
  branch=$(git config --file ../../.gitmodules --get submodule.instruments/$instrument.branch || echo "main")

  # Remove from root
  cd ../..
  git submodule deinit -f instruments/$instrument
  git rm -f instruments/$instrument

  # Move directory
  mv instruments/$instrument juce_backend/instruments/

  # Add to juce_backend
  cd juce_backend
  git submodule add -b $branch $url instruments/$instrument
  cd ..
done

# 7. Remove empty directories
rmdir effects instruments 2>/dev/null || true

# 8. Update .gitmodules
# Root .gitmodules will have effects/instruments removed
# juce_backend/.gitmodules will have them added

# 9. Update submodules
git submodule sync
git submodule update --init --recursive

# 10. Test
git status
git submodule status

# 11. Update CMakeLists.txt (manual step)
# Search for effects/ and instruments/ paths and update to juce_backend/effects/ and juce_backend/instruments/

# 12. Build test
cmake --preset=macos-clang-release
cmake --build --preset=macos-clang-release

# 13. Commit if successful
git add .
git commit -m "refactor: Move effects/instruments submodules to juce_backend

- Moved 8 effect plugin submodules to juce_backend/effects/
- Moved 6 instrument plugin submodules to juce_backend/instruments/
- Updated .gitmodules in both root and juce_backend
- Updated CMakeLists.txt paths
- All plugins now logically organized under juce_backend/

This creates a cleaner hierarchy where juce_backend manages all
audio plugin development (effects, instruments, daid-core, sdk)."

git push origin main
```

---

## Benefits of This Migration

### 1. **Logical Hierarchy**
- All audio plugins under `juce_backend/`
- Clear separation: backend (JUCE) vs frontend (Swift)
- Matches mental model of the architecture

### 2. **Cleaner Root**
- Removes 14 submodule directories from root
- Reduces root directory clutter
- Root focuses on project-level concerns

### 3. **Better Organization**
- `juce_backend/` becomes the complete audio engine
- Easier to understand project structure
- Easier for new developers to navigate

### 4. **Scalability**
- Easy to add more plugins in future
- Clear where new plugins should go
- Consistent with existing patterns

---

## Risks and Mitigations

### Risk 1: Build Breakage
**Mitigation:**
- Comprehensive CMakeLists.txt update
- Build testing before committing
- Backup branch ready for rollback

### Risk 2: Submodule Detachment
**Mitigation:**
- Careful `git submodule` commands
- Verify submodule status after move
- Test `git submodule update --init --recursive`

### Risk 3: Path References in Code
**Mitigation:**
- Search all codebase for `effects/` and `instruments/` paths
- Update documentation
- Update any hardcoded paths

### Risk 4: CI/CD Pipeline Issues
**Mitigation:**
- Update GitHub Actions workflows
- Test CI builds before merging
- Update deployment scripts

---

## Rollback Plan

If anything goes wrong:

```bash
# Checkout backup branch
git checkout backup-before-submodule-move

# Or reset to before migration
git reset --hard HEAD~1

# Restore submodules manually if needed
git submodule deinit --all
git submodule update --init --recursive
```

---

## Post-Migration Checklist

- [ ] All submodules moved successfully
- [ ] `.gitmodules` updated in both root and juce_backend
- [ ] CMakeLists.txt paths updated
- [ ] Build succeeds without errors
- [ ] All plugins load correctly
- [ ] Audio processing works
- [ ] Preset loading works
- [ ] CI/CD pipeline passes
- [ ] Documentation updated
- [ ] Team notified of structural changes
- [ ] Backup branch pushed to origin

---

## Related Documentation

- [ROOT_DIRECTORY_ANALYSIS.md](./ROOT_DIRECTORY_ANALYSIS.md) - Overall project structure analysis
- [CMakeLists.txt](../../CMakeLists.txt) - Main build configuration
- [.gitmodules](../../.gitmodules) - Root submodule configuration
- [juce_backend/.gitmodules](../../juce_backend/.gitmodules) - JUCE backend submodule configuration

---

## Questions?

1. **Should `plugins/` and `pedalboard_plugin/` also move?**
   - These appear to be non-submodule plugin code
   - Should they move to `juce_backend/plugins/` as well?

2. **Should `src/` and `include/` move?**
   - These appear to be root-level C++ code
   - Should move to `juce_backend/src/` and `juce_backend/include/`

3. **What about `clap-juce-extensions/` and `JUCE/`?**
   - Move to `juce_backend/external/` for consistency?

---

**Status:** ✅ Plan Complete - Ready to Execute
**Estimated Time:** 30-60 minutes
**Risk Level:** Medium (submodule operations are delicate but reversible)
