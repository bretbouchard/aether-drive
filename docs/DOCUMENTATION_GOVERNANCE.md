# Documentation Governance Rules

**Version:** 1.0.0
**Last Updated:** 2025-01-16
**Status:** Enforced

---

## Overview

This document defines the rules and standards for organizing and maintaining White Room documentation. All team members must follow these guidelines to keep the documentation library clean and maintainable.

---

## 📁 File Location Rules

### ✅ ALLOWED in Root Directory

Only these files are allowed in the project root:

1. **README.md** - Project overview (required)
2. **CHANGELOG.md** - Version history (optional)
3. **CONTRIBUTING.md** - Contribution guidelines (optional)
4. **LICENSE** - License file (optional)

### ❌ FORBIDDEN in Root Directory

All other markdown (.md) files must be in `docs/` directory.

**Examples of files that MUST be in `docs/`:**
- Build reports
- Migration guides
- Architecture documents
- API documentation
- User guides
- Development workflows
- Security documentation
- Reference materials
- Session summaries
- Status reports

---

## 🗂️ Documentation Structure

```
white_room/
├── README.md                    # ✅ Allowed in root
├── CHANGELOG.md                 # ✅ Allowed (if needed)
├── CONTRIBUTING.md              # ✅ Allowed (if needed)
├── LICENSE                      # ✅ Allowed (if needed)
└── docs/                        # 📚 ALL other documentation
    ├── README.md                # Documentation library index
    ├── architecture/            # System architecture
    ├── development/             # Development workflow
    │   ├── build/              # Build system docs
    │   ├── plugins/            # Plugin development
    │   ├── tracking/           # Issue tracking
    │   └── roadmap/            # Roadmap & next steps
    ├── user/                   # User guides
    ├── reference/              # Reference materials
    │   └── plugin-formats/     # Plugin format guides
    ├── security/               # Security docs
    ├── deployment/             # Deployment guides
    ├── archive/                # Historical docs
    │   ├── completed-sessions/
    │   └── migrations/
    └── testing/                # Testing docs
```

---

## 📝 File Naming Conventions

### Main Documents
- Use `UPPER_CASE_WITH_UNDERSCORES.md`
- Examples: `BUILD_STATUS.md`, `PLUGIN_MIGRATION_PLAN.md`

### Guides and Tutorials
- Use `lowercase-with-hyphens.md`
- Examples: `quickstart.md`, `plugin-development-guide.md`

### Reports
- Include date when relevant
- Examples: `AUDIT_REPORT_2025-01-16.md`, `MIGRATION_SUMMARY_Q1_2025.md`

---

## 🚫 Enforcement: Pre-commit Hook

A pre-commit hook is installed at `.git/hooks/pre-commit` that:

1. **Blocks commits** that add .md files to root (except allowed files)
2. **Warns** about new .md files not in docs/
3. **Provides instructions** for fixing violations

### Installing the Hook

```bash
./infrastructure/hooks/install-hooks.sh
```

### Manual Installation

```bash
cp infrastructure/hooks/pre-commit-docs.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

### Bypassing the Hook (Not Recommended)

If you absolutely must bypass:

```bash
git commit --no-verify -m "Your commit message"
```

**Only use this if you know what you're doing!**

---

## ✅ Adding New Documentation

### Step 1: Choose Category

Determine where your document belongs:

| Category | Directory | Contents |
|----------|-----------|----------|
| Architecture | `docs/architecture/` | System design, technical decisions |
| Development | `docs/development/` | Build, workflows, setup |
| User Guides | `docs/user/` | Tutorials, how-to guides |
| Reference | `docs/reference/` | API docs, format guides |
| Security | `docs/security/` | Security policies, audits |
| Deployment | `docs/deployment/` | CI/CD, releases |
| Archive | `docs/archive/` | Historical documents |

### Step 2: Create File

```bash
# Example: Adding a build guide
vim docs/development/build/OPTIMIZATION_GUIDE.md
```

### Step 3: Update Index

Update `docs/README.md` to include your new document in the appropriate section.

### Step 4: Commit

```bash
git add docs/development/build/OPTIMIZATION_GUIDE.md
git add docs/README.md
git commit -m "docs: Add build optimization guide"
```

---

## 📋 Documentation Categories

### Architecture (`docs/architecture/`)

**Purpose:** System design and technical architecture

**Includes:**
- System architecture diagrams
- Technical decision records
- Integration patterns
- Submodule architecture
- Data flow diagrams

### Development (`docs/development/`)

**Purpose:** Development workflow and processes

**Subdirectories:**
- `build/` - Build system documentation
- `plugins/` - Plugin development guides
- `tracking/` - Issue tracking and status
- `roadmap/` - Development roadmap

**Includes:**
- Build instructions
- Development setup
- Workflow guides
- Migration plans
- Status reports

### User (`docs/user/`)

**Purpose:** User-facing documentation

**Includes:**
- Quick start guides
- Feature tutorials
- How-to guides
- Troubleshooting
- FAQ

### Reference (`docs/reference/`)

**Purpose:** Reference materials

**Subdirectories:**
- `plugin-formats/` - JUCE plugin format guides

**Includes:**
- API documentation
- Format specifications
- Technical references
- Glossaries

### Security (`docs/security/`)

**Purpose:** Security documentation

**Includes:**
- Security policies
- Audit reports
- Threat models
- Compliance documentation
- Best practices

### Deployment (`docs/deployment/`)

**Purpose:** Deployment and release documentation

**Includes:**
- CI/CD workflows
- Release procedures
- Production readiness
- Test reports
- Launch guides

### Archive (`docs/archive/`)

**Purpose:** Historical documentation

**Subdirectories:**
- `completed-sessions/` - Session completion reports
- `migrations/` - Migration documentation

**Includes:**
- Old version docs
- Historical reports
- Deprecated features
- Past project summaries

---

## 🔄 Maintenance

### Regular Tasks

**Weekly:**
- Review new documentation for proper placement
- Update docs/README.md with new files
- Archive outdated documents

**Monthly:**
- Check for orphaned files
- Update index files
- Review archive for cleanup candidates

**Quarterly:**
- Full documentation audit
- Update standards if needed
- Review pre-commit hook effectiveness

### Moving Files to Archive

When documentation becomes outdated:

1. Don't delete - move to `docs/archive/`
2. Add a note explaining why it was archived
3. Update references to point to new documents
4. Update docs/README.md

---

## 🧪 Testing the Hook

### Test 1: Should Block

```bash
# Try to add a .md file to root
echo "# Test" > TEST_FILE.md
git add TEST_FILE.md
git commit -m "test: Add test file"

# Expected: ❌ Blocked by pre-commit hook
```

### Test 2: Should Allow

```bash
# Add .md file to docs/
echo "# Test" > docs/test.md
git add docs/test.md
git commit -m "docs: Add test document"

# Expected: ✅ Commit succeeds
```

### Test 3: Should Allow Root Files

```bash
# Update README.md
echo "# Update" >> README.md
git add README.md
git commit -m "docs: Update README"

# Expected: ✅ Commit succeeds
```

---

## 📊 Statistics

**Before Organization:**
- Root directory: 38 .md files
- docs/ directory: 153 .md files
- **Total:** 191 .md files

**After Organization:**
- Root directory: 1 .md file (README.md)
- docs/ directory: 190 .md files (organized)
- **Files moved:** 37 files from root to docs/

**Organization Achievement:**
- ✅ 100% compliance with documentation standards
- ✅ Clear category structure
- ✅ Enforced by pre-commit hook
- ✅ Maintainable going forward

---

## 🆘 Troubleshooting

### Problem: Hook blocks legitimate commit

**Solution:**
1. Check if file should really be in root
2. If yes, use `git commit --no-verify`
3. If no, move file to `docs/` and commit again

### Problem: Don't know where to put file

**Solution:**
1. Review categories in this document
2. Check `docs/README.md` for examples
3. Ask team for guidance
4. When in doubt, use `docs/development/` or `docs/archive/`

### Problem: File needs to be in multiple categories

**Solution:**
1. Choose primary category
2. Add cross-references in other locations
3. Update `docs/README.md` with links

---

## 📚 Related Documentation

- **[docs/README.md](../README.md)** - Documentation library index
- **[docs/organization_plan.md](organization_plan.md)** - Organization plan
- **[infrastructure/hooks/pre-commit-docs.sh](../../infrastructure/hooks/pre-commit-docs.sh)** - Pre-commit hook

---

## 🎯 Success Criteria

Documentation organization is successful when:

- ✅ No .md files in root except allowed files
- ✅ All documentation categorized properly
- ✅ Pre-commit hook active and working
- ✅ Team follows naming conventions
- ✅ docs/README.md kept up-to-date
- ✅ New team members can find documents easily

---

**Document Status:** ✅ Active
**Last Updated:** 2025-01-16
**Maintained By:** Development Team
**Enforced By:** Pre-commit hook

---

*This governance document ensures documentation stays organized and maintainable. All team members must follow these rules.*
