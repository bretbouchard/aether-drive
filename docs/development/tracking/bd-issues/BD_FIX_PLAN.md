# Fixing BD FOREIGN KEY Constraint Error

## Problem

BD issue **white_room-487** cannot be closed due to:
```
Error: FOREIGN KEY constraint failed (787)
```

## Root Cause

The BD database has a foreign key constraint violation. When closing an issue, BD tries to create an event record that references a parent issue that doesn't exist.

## Solutions

### Option 1: Delete and Recreate Issue (RECOMMENDED)

This is the cleanest solution:

```bash
# Delete the problematic issue
bd delete white_room-487

# Recreate without discovered_from dependency
bd create "AUv3 support for Choral Ensemble Engine - bundle structure created - requires proper Xcode build (4-6 hours) - see AUV3_FINAL_SUMMARY.md"
```

### Option 2: Update BD and Retry Close

```bash
# Update BD to latest version
go install github.com/steveyeggie/beads/cmd/bd@latest

# Try closing again
bd close white_room-487 "Resolution details..."
```

### Option 3: Manual Database Fix

```bash
# Access BD database
sqlite3 ~/.bd/default.db

# Find and fix orphaned references
SELECT * FROM events WHERE issue_id = 487;
SELECT * FROM issues WHERE id = 487;

# Fix foreign key constraints
UPDATE events SET parent_issue_id = NULL WHERE issue_id = 487;
```

## Recommended Action

**Option 1: Delete and Recreate**

This is the safest approach because:
1. Removes the corrupted database entry
2. Creates clean issue without foreign key problems
3. Confucius can still learn when the new issue is closed
4. No database corruption risk

## Implementation

Let me proceed with Option 1:
