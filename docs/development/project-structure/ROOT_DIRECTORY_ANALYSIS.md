# Root Directory Analysis - White Room Project

**Date:** 2025-01-17
**Status:** Analysis Complete - Awaiting Approval for Moves

---

## Executive Summary

The root directory has **37 directories** and **28 files**. Many items should be reorganized to follow the established documentation governance standards and improve project structure clarity.

---

## Current State

### Root Level Statistics
- **Directories:** 37
- **Files:** 28
- **Hidden config dirs:** 10 (`.git`, `.beads`, `.claude`, etc.)
- **Build artifacts:** 3 (`.build`, `build`, `CMakeFiles`)

---

## 🟢 BELONGS IN ROOT (Keep As-Is)

### Essential Project Configuration
```
✅ .github/          # GitHub Actions, issue templates
✅ .git/             # Git repository
✅ .gitignore        # Git ignore rules
✅ .gitmodules       # Submodule configuration
✅ .specify/         # SpecKit configuration
✅ README.md         # Project overview (MUST stay in root)
✅ CMakeLists.txt    # Main CMake configuration
✅ Makefile          # Build configuration
```

### Development Tools Config
```
✅ .beads/           # BD task tracking (project-level)
✅ .brv/             # BRV configuration
✅ .claude/          # Claude Code configuration
✅ .serena/          # Serena MCP server state
✅ .artifacts/       # Claude Code build artifacts
```

---

## 🟡 QUESTIONABLE - Should Stay BUT Need Organization

### Build System (Consider consolidating)
```
🤔 build/                    # Build output - should be in .gitignore?
🤔 build_plugin/             # Plugin build output - should be in .gitignore?
🤔 build-config/             # Build configuration - KEEP but consider renaming to build_config/
🤔 CMakeFiles/               # CMake generated - should be in .gitignore
🤔 CMakeCache.txt            # CMake cache - should be in .gitignore
🤔 cmake_install.cmake       # CMake generated - should be in .gitignore
🤔 CMakeUserPresets.json     # User-specific - should be in .gitignore
🤔 .build_backup_*/          # Build backups - should be in .gitignore or cleaned up
```

**Recommendation:** Most build outputs should be in `.gitignore`. Only keep `build-config/` if it contains configuration files (not outputs).

### Build Scripts (Keep in root for convenience)
```
🤔 build.sh                  # Main build script - KEEP
🤔 build_ios_auv3.sh         # iOS build - KEEP
🤔 build_plugin.sh           # Plugin build - KEEP
🤔 setup_juce_project.sh     # JUCE setup - KEEP
🤔 deploy.sh                 # Deployment - KEEP
🤔 deploy_to_appletv.sh      # Apple TV deployment - KEEP
🤔 run_comprehensive_tests.sh # Test runner - KEEP
🤔 verify_ffi_bridge.sh      # FFI verification - KEEP
🤔 organize_docs.sh          # Doc organization - KEEP (recently created)
```

**Recommendation:** Keep these in root for convenience, but consider moving to `infrastructure/scripts/` for consistency.

---

## 🔴 SHOULD MOVE - Has Better Home

### 1. BD Fix Documentation (3 files)
**Current:** Root level
**Should Move To:** `docs/development/tracking/bd-issues/`

```
📦 BD_CONSTRAINT_FIX_SUMMARY.md
📦 BD_FIX_PLAN.md
📦 BD_FIX_SUCCESS.md
```

**Rationale:** These are BD (Beads) task tracking documentation and belong with other tracking docs.

---

### 2. Demo Songs (Directory)
**Current:** Root level
**Should Move To:** `resources/audio/demos/` or `assets/demo-songs/`

```
📦 demo_songs/
```

**Rationale:** Demo songs are assets/resources, not project structure. Should be with other audio assets.

---

### 3. Hardware (Directory)
**Current:** Root level
**Should Move To:** Keep in root OR move to dedicated `hardware/` (it's already there)

```
📦 hardware/
```

**Rationale:** This is a legitimate top-level directory for hardware projects. However, it should be clearly marked as a separate subsystem from the software.

**Verdict:** ✅ **KEEP IN ROOT** - Hardware is a separate major subsystem.

---

### 4. Design System (Directory)
**Current:** Root level
**Should Move To:** `design_system/` is fine, but what's inside?

```
📦 design_system/
```

**Issue:** Only contains `database/` - what is this?
**Rationale:** Needs investigation. If it's UI design system, move to `swift_frontend/WhiteRoomiOS/DesignSystem/`. If it's component library, keep.

**Verdict:** 🤔 **INVESTIGATE FIRST** - Unclear purpose from current structure.

---

### 5. Marketing (Directory)
**Current:** Root level
**Should Move To:** Keep or move to `docs/marketing/`

```
📦 marketing/
```

**Rationale:** Marketing materials are project documentation. However, if this contains active campaigns/assets, it might belong in root.

**Verdict:** 🤔 **CONDITIONAL** - If it's documentation, move to `docs/marketing/`. If it's operational marketing assets, keep in root.

---

### 6. Plugin/Effect Directories (4 directories)
**Current:** Root level
**Should Move To:** `juce_backend/plugins/` or `plugins/`

```
📦 effects/
📦 instruments/
📦 plugins/
📦 pedalboard_plugin/
```

**Rationale:** These are all audio plugin related. They should be organized under `juce_backend/` or a consolidated `plugins/` directory.

**Recommendation:**
- `effects/` → `juce_backend/effects/` (already exists as submodule)
- `instruments/` → `juce_backend/instruments/` (already exists as submodule)
- `plugins/` → `juce_backend/plugins/` (consolidate)
- `pedalboard_plugin/` → `juce_backend/pedalboard/` (consolidate)

**Verdict:** 🔴 **MOVE** - All plugin code belongs under `juce_backend/`.

---

### 7. DAW Compatibility Testing
**Current:** Root level
**Should Move To:** `tests/daw-compatibility/` or `infrastructure/testing/daw/`

```
📦 daw_compatibility_testing/
```

**Rationale:** This is testing infrastructure and belongs with test suites.

**Verdict:** 🔴 **MOVE** - Testing infrastructure belongs in `tests/` or `infrastructure/testing/`.

---

### 8. Developer Scripts/Templates
**Current:** Root level
**Should Move To:** `infrastructure/scripts/developer/`

```
📦 developer/
```

**Rationale:** Developer resources are infrastructure.

**Verdict:** 🔴 **MOVE** - Belongs in `infrastructure/developer/` or `infrastructure/scripts/`.

---

### 9. Ingest Directory
**Current:** Root level
**Should Move To:** Investigate first

```
📦 ingest/
```

**Issue:** What is this? Data ingestion? Audio ingestion?
**Rationale:** Unknown purpose needs investigation before deciding.

**Verdict:** 🤔 **INVESTIGATE FIRST** - Unclear purpose.

---

### 10. Test Reports
**Current:** Root level
**Should Move To:** `infrastructure/test-reports/` or `TestReports/` (already there)

```
📦 TestReports/
```

**Rationale:** Test reports are infrastructure/output.

**Verdict:** 🤔 **CONDITIONAL** - Keep if actively used, move to `infrastructure/test-reports/` for organization.

---

### 11. Web UI
**Current:** Root level
**Should Move To:** `web_ui/` is fine, or move to `swift_frontend/web/`

```
📦 web_ui/
```

**Rationale:** Web UI is a separate frontend. Could be under `swift_frontend/` for consistency.

**Verdict:** 🤔 **CONDITIONAL** - If it's the main web interface, keep in root. If it's a SwiftUI web view, move to `swift_frontend/`.

---

### 12. iOS Directory
**Current:** Root level
**Should Move To:** `swift_frontend/` (already has iOS code)

```
📦 ios/
```

**Rationale:** iOS code is in `swift_frontend/WhiteRoomiOS/`. This might be redundant.

**Verdict:** 🔴 **MOVE OR MERGE** - Likely redundant with `swift_frontend/WhiteRoomiOS/`.

---

### 13. Source/Include Directories
**Current:** Root level
**Should Move To:** `juce_backend/src/` or `juce_backend/include/`

```
📦 src/
📦 include/
```

**Rationale:** These look like C++ source files and should be under `juce_backend/`.

**Verdict:** 🔴 **MOVE** - Belong under `juce_backend/`.

---

### 14. Resources
**Current:** Root level
**Should Move To:** Keep or move to `resources/`

```
📦 Resources/
```

**Rationale:** If this contains shared resources, keep in root. If it's plugin-specific, move to `juce_backend/Resources/`.

**Verdict:** 🤔 **INVESTIGATE FIRST** - Need to see what's inside.

---

### 15. Test Files/Output
**Current:** Root level
**Should Move To:** `infrastructure/test-output/` or `.gitignore`

```
📦 test_failures_complete.txt
```

**Rationale:** Test output files should be in `.gitignore` or a dedicated test output directory.

**Verdict:** 🔴 **MOVE OR GITIGNORE** - Test output doesn't belong in root.

---

### 16. JUCE Extensions
**Current:** Root level
**Should Move To:** `juce_backend/external/clap-juce-extensions/`

```
📦 clap-juce-extensions/
📦 JUCE/
```

**Rationale:** These are dependencies for juce_backend and should be under it.

**Verdict:** 🔴 **MOVE** - Dependencies belong under the module that uses them.

---

### 17. Build Artifacts/Outputs
**Current:** Root level
**Should Move To:** `.gitignore` or clean up

```
📦 FarFarAway_artefacts/
📦 FarFarAway_vst3_helper
📦 JucePluginDefines.h
📦 PedalboardEditor.cpp
📦 PedalboardEditor.h
```

**Rationale:** These appear to be build outputs or generated files and should not be in the repository root.

**Verdict:** 🔴 **MOVE OR GITIGNORE** - Build outputs don't belong in git.

---

### 18. Plans Directory
**Current:** Root level
**Should Move To:** Already exists in root, but check if it should be in `docs/development/plans/`

```
📦 plans/
```

**Rationale:** Implementation plans are documentation and should be in `docs/development/plans/`.

**Verdict:** 🔴 **MOVE** - Documentation belongs in `docs/`.

---

### 19. Specs Directory
**Current:** Root level
**Should Move To:** Should be in `docs/specifications/` or keep if used by tools

```
📦 specs/
```

**Rationale:** Specs are documentation. However, if SpecKit expects them in root, keep them.

**Verdict:** 🤔 **CONDITIONAL** - If SpecKit requires root location, keep. Otherwise, move to `docs/specifications/`.

---

### 20. Tests Directory
**Current:** Root level
**Should Move To:** Keep or move to `infrastructure/testing/`

```
📦 tests/
```

**Rationale:** Test suites are infrastructure. However, top-level `tests/` is a common pattern.

**Verdict:** ✅ **KEEP IN ROOT** - Top-level `tests/` is a standard pattern.

---

---

## 📊 Summary by Action Required

### 🔴 High Priority - Should Move

| Item | Current Location | Should Move To | Reason |
|------|-----------------|----------------|--------|
| `BD_*.md` (3 files) | Root | `docs/development/tracking/bd-issues/` | Documentation organization |
| `effects/` | Root | `juce_backend/effects/` | Plugin code organization |
| `instruments/` | Root | `juce_backend/instruments/` | Plugin code organization |
| `plugins/` | Root | `juce_backend/plugins/` | Plugin code organization |
| `pedalboard_plugin/` | Root | `juce_backend/pedalboard/` | Plugin code organization |
| `daw_compatibility_testing/` | Root | `infrastructure/testing/daw/` | Test infrastructure |
| `developer/` | Root | `infrastructure/scripts/developer/` | Infrastructure organization |
| `src/` | Root | `juce_backend/src/` | Source code organization |
| `include/` | Root | `juce_backend/include/` | Header organization |
| `clap-juce-extensions/` | Root | `juce_backend/external/` | Dependency organization |
| `JUCE/` | Root | `juce_backend/external/` | Dependency organization |
| `plans/` | Root | `docs/development/plans/` | Documentation organization |
| `ios/` | Root | Merge with `swift_frontend/` | Likely redundant |
| `test_failures_complete.txt` | Root | `infrastructure/test-output/` | Test output |
| `FarFarAway_artefacts/` | Root | `.gitignore` | Build artifacts |
| `FarFarAway_vst3_helper` | Root | `.gitignore` | Build output |
| `JucePluginDefines.h` | Root | Generated by CMake | Build output |
| `PedalboardEditor.cpp/.h` | Root | Should be in plugin dir | Source file location |

### 🟡 Medium Priority - Should Stay But Need Review

| Item | Action | Notes |
|------|--------|-------|
| `build/`, `build_plugin/` | Add to `.gitignore` | Build outputs shouldn't be in git |
| `CMakeFiles/`, `CMakeCache.txt` | Add to `.gitignore` | CMake generated files |
| `.build_backup_*/` | Clean up or gitignore | Backup build directories |
| `build.sh`, `build_plugin.sh`, etc. | Keep or move to `infrastructure/scripts/` | Convenient in root, but inconsistent |
| `design_system/` | Investigate contents | What is this? |
| `ingest/` | Investigate contents | What is this? |
| `Resources/` | Investigate contents | What resources? |
| `marketing/` | Move to `docs/marketing/` | Unless operational assets |
| `specs/` | Keep if SpecKit requires | Otherwise move to `docs/` |

### 🟢 Low Priority - Keep As-Is

| Item | Reason |
|------|--------|
| `.github/`, `.git/`, `.gitignore` | Essential git/config |
| `.beads/`, `.claude/`, `.serena/` | Development tools |
| `README.md`, `CMakeLists.txt`, `Makefile` | Project configuration |
| `hardware/` | Separate major subsystem |
| `tests/` | Standard top-level pattern |
| `demo_songs/` | Assets (consider moving to `resources/`) |
| `infrastructure/` | Already organized |
| `docs/` | Already organized |
| `juce_backend/` | Main backend module |
| `swift_frontend/` | Main frontend module |
| `sdk/` | Shared SDK |
| `web_ui/` | Separate frontend |

---

## 🎯 Recommended Target Structure

```
white_room/
├── .github/                    # GitHub config
├── .git/                       # Git repository
├── .beads/                     # BD tracking
├── .claude/                    # Claude Code config
├── .serena/                    # Serena MCP
├── infrastructure/             # Build, CI/CD, testing, scripts
│   ├── scripts/                # All build/deploy scripts
│   ├── testing/                # Test infrastructure
│   │   └── daw/               # DAW compatibility testing
│   └── test-output/           # Test results
├── juce_backend/              # JUCE audio plugin
│   ├── effects/               # All effects plugins
│   ├── instruments/           # All instrument plugins
│   ├── plugins/               # General plugins
│   ├── pedalboard/            # Pedalboard plugin
│   ├── external/              # Dependencies (JUCE, clap-extensions)
│   ├── src/                   # C++ sources
│   └── include/               # C++ headers
├── swift_frontend/            # SwiftUI interface
│   ├── WhiteRoomiOS/          # iOS app
│   └── web/                   # Web UI (if applicable)
├── hardware/                  # Hardware projects (KiCad, firmware)
├── sdk/                       # Shared TypeScript SDK
├── docs/                      # All documentation
│   ├── specifications/        # Feature specs (move from specs/)
│   ├── development/
│   │   ├── plans/            # Implementation plans (move from plans/)
│   │   ├── tracking/
│   │   │   └── bd-issues/    # BD documentation (move BD_*.md)
│   │   └── marketing/        # Marketing docs (move from marketing/)
│   └── user/                 # User documentation
├── tests/                     # Test suites
├── resources/                 # Assets (demo songs, samples)
├── specs/                     # KEEP if SpecKit requires root
├── build.sh, build_plugin.sh, # KEEP in root for convenience
├── deploy.sh, deploy_to_appletv.sh
├── run_comprehensive_tests.sh
├── CMakeLists.txt
├── Makefile
├── README.md
└── .gitignore
```

---

## 🚀 Implementation Plan

### Phase 1: Easy Wins (Low Risk)
1. Move BD documentation files
2. Move test output files
3. Clean up build artifacts

### Phase 2: Plugin Consolidation (Medium Risk)
1. Move `effects/`, `instruments/`, `plugins/`, `pedalboard_plugin/`
2. Move `src/`, `include/`
3. Move JUCE dependencies
4. Update all import paths

### Phase 3: Infrastructure Organization (Low Risk)
1. Move build scripts to `infrastructure/scripts/`
2. Move DAW testing to `infrastructure/testing/`
3. Move developer resources

### Phase 4: Documentation Consolidation (Low Risk)
1. Move `plans/` to `docs/development/plans/`
2. Move `marketing/` to `docs/marketing/`
3. Investigate `specs/` location requirements

### Phase 5: Investigation Required
1. Investigate `design_system/` contents
2. Investigate `ingest/` purpose
3. Investigate `Resources/` contents
4. Determine if `ios/` is redundant
5. Check if `demo_songs/` should move to `resources/`

---

## ⚠️ Important Notes

1. **Don't move anything yet** - This is analysis only
2. **Check git history** - Some files might have been moved before
3. **Update imports** - Moving code requires updating all import statements
4. **Test thoroughly** - After each move, run build/tests
5. **Communicate** - If working with a team, get buy-in first
6. **Backup** - Create a branch before making moves

---

## 📋 Decision Matrix

| Directory | Move? | Priority | Risk | Dependencies |
|-----------|------|----------|------|--------------|
| `effects/` | ✅ Yes | High | Medium | Import paths, CMake |
| `instruments/` | ✅ Yes | High | Medium | Import paths, CMake |
| `plugins/` | ✅ Yes | High | Medium | Import paths, CMake |
| `pedalboard_plugin/` | ✅ Yes | High | Medium | Import paths, CMake |
| `BD_*.md` | ✅ Yes | High | Low | None |
| `src/` | ✅ Yes | High | High | Import paths, CMake |
| `include/` | ✅ Yes | High | High | Import paths, CMake |
| `clap-juce-extensions/` | ✅ Yes | Medium | Medium | CMake |
| `JUCE/` | ✅ Yes | Medium | Medium | CMake |
| `plans/` | ✅ Yes | Medium | Low | Documentation links |
| `marketing/` | ✅ Yes | Medium | Low | Documentation links |
| `daw_compatibility_testing/` | ✅ Yes | Medium | Low | Test runner |
| `developer/` | ✅ Yes | Medium | Low | Scripts |
| `ios/` | 🤔 Investigate | Low | High | iOS build |
| `design_system/` | 🤔 Investigate | Low | Unknown | Unknown |
| `ingest/` | 🤔 Investigate | Low | Unknown | Unknown |
| `Resources/` | 🤔 Investigate | Low | Low | Asset loading |
| `specs/` | ❌ Keep | N/A | N/A | SpecKit tool |
| `tests/` | ❌ Keep | N/A | N/A | Standard pattern |
| `hardware/` | ❌ Keep | N/A | N/A | Separate subsystem |
| `demo_songs/` | ❌ Keep | N/A | N/A | Assets (or move to resources/) |

---

## ✅ Next Steps

1. **Review this analysis** and decide on moves
2. **Create branches** for each phase
3. **Update CMakeLists.txt** and build scripts
4. **Update all import paths**
5. **Test builds** after each phase
6. **Update documentation** with new structure
7. **Communicate changes** to team

---

**Generated:** 2025-01-17
**Status:** ✅ Analysis Complete - Awaiting Approval
