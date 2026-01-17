# White Room Auto-Save System

## Overview

The White Room auto-save system prevents data loss by automatically saving song state at regular intervals and when changes occur. The system uses intelligent debouncing to avoid excessive writes while ensuring data is never lost.

## Features

- **Debounced Saves**: 2-second delay after changes before saving
- **Periodic Saves**: Automatic saves every 60 seconds if data is dirty
- **Automatic Pruning**: Maintains maximum 10 autosaves per song
- **Restore Functionality**: Restore from any previous autosave
- **Thread-Safe**: Swift implementation uses actors for safety
- **Event-Driven**: TypeScript implementation emits events for notifications

## Architecture

### Components

1. **AutoSaveRepository**: Database operations for autosaves
2. **AutoSaveManager**: Business logic for debouncing and pruning
3. **AutoSaveCoordinator**: SwiftUI integration layer
4. **Database Schema**: SQLite table with indexes for performance

### Data Flow

```
User edits song
    ↓
markDirty(song)
    ↓
Debounce timer starts (2 seconds)
    ↓
[Another edit? Reset timer]
    ↓
2 seconds pass without edits
    ↓
performAutoSave()
    ↓
Encode song to JSON
    ↓
Save to database
    ↓
Prune old autosaves (if > 10)
    ↓
Update UI state
```

## Usage

### Swift (SwiftUI)

#### Basic Setup

```swift
import SwiftUI
import SwiftFrontendShared

struct SongEditorView: View {
  @StateObject private var autoSaveCoordinator: AutoSaveCoordinator
  @State private var song: Song

  init(autoSaveManager: AutoSaveManager, song: Song) {
    self._autoSaveCoordinator = StateObject(wrappedValue: AutoSaveCoordinator(autoSaveManager: autoSaveManager))
    self._song = State(initialValue: song)
  }

  var body: some View {
    VStack {
      // Your song editor UI
      SongEditor(song: $song)

      // Auto-save indicator
      AutoSaveIndicator(coordinator: autoSaveCoordinator)
    }
    .autoSave(coordinator: autoSaveCoordinator, song: $song)
  }
}
```

#### Manual Save

```swift
Button("Save Now") {
  Task {
    try await autoSaveCoordinator.saveNow()
  }
}
```

#### Restore from Autosave

```swift
Button("Restore Previous") {
  Task {
    let autosaves = try await autoSaveCoordinator.autoSaveManager.getAutosaves()
    if let latestAutosave = autosaves.first {
      let restoredSong = try await autoSaveCoordinator.restoreFromAutosave(latestAutosave.id)
      song = restoredSong
    }
  }
}
```

### TypeScript

#### Basic Setup

```typescript
import { AutoSaveManager } from '@schillinger-sdk/shared';
import { AutoSaveRepository } from '@schillinger-sdk/shared';

// Initialize repository
const autoSaveRepository = new AutoSaveRepository('./database.db');

// Initialize manager
const autoSaveManager = new AutoSaveManager(autoSaveRepository);

// Listen to events
autoSaveManager.on('autosave', (autosave) => {
  console.log('Auto-saved:', autosave.description);
});

autoSaveManager.on('error', (error) => {
  console.error('Auto-save error:', error);
});
```

#### Track Changes

```typescript
function onSongChanged(song: SongModel_v2) {
  autoSaveManager.markDirty(song);
}
```

#### Manual Save

```typescript
function saveNow() {
  autoSaveManager.saveNow();
}
```

#### Restore from Autosave

```typescript
function restoreLatest() {
  const autosaves = autoSaveManager.getAutosaves();
  if (autosaves.length > 0) {
    const restoredSong = autoSaveManager.restoreFromAutosave(autosaves[0].id);
    // Use restored song
  }
}
```

#### Cleanup

```typescript
// Cleanup when done
autoSaveManager.destroy();
autoSaveRepository.close();
```

## Configuration

### Swift Configuration

Edit properties in `AutoSaveManager.swift`:

```swift
private var autoSaveEnabled: Bool { true }
private var debounceDelay: TimeInterval { 2.0 }  // 2 seconds
private var periodicInterval: TimeInterval { 60.0 }  // 1 minute
private var maxAutosaves: Int { 10 }
```

### TypeScript Configuration

Edit properties in `AutoSaveManager.ts`:

```typescript
private autoSaveEnabled = true;
private debounceDelay = 2000;  // 2 seconds
private periodicInterval = 60000;  // 1 minute
private maxAutosaves = 10;
```

## Database Schema

### Autosaves Table

```sql
CREATE TABLE autosaves (
  id TEXT PRIMARY KEY,
  song_id TEXT NOT NULL,
  song_json TEXT NOT NULL,
  timestamp REAL NOT NULL,
  description TEXT NOT NULL,
  FOREIGN KEY (song_id) REFERENCES songs(id) ON DELETE CASCADE
);

CREATE INDEX idx_autosaves_song_id ON autosaves(song_id);
CREATE INDEX idx_autosaves_timestamp ON autosaves(timestamp DESC);
CREATE INDEX idx_autosaves_song_timestamp ON autosaves(song_id, timestamp DESC);
```

## Performance

### Targets

- **Auto-save operation**: <100ms
- **Restore from autosave**: <50ms
- **Pruning operation**: <200ms
- **Memory overhead**: <10MB for autosave metadata

### Optimization

- Debouncing prevents excessive saves during rapid edits
- Periodic saves ensure data is saved even if user forgets
- Pruning prevents database bloat
- Indexes ensure fast queries
- WAL mode for concurrent access

## Testing

### Swift Tests

Run Swift tests:

```bash
cd swift_frontend
swift test --filter AutoSaveManagerTests
```

### TypeScript Tests

Run TypeScript tests:

```bash
cd sdk/packages/shared
npm test -- AutoSaveManager.test.ts
```

## Troubleshooting

### Autosaves Not Appearing

1. Check if auto-save is enabled
2. Verify database path is correct
3. Check for error messages in console
4. Ensure song is being marked as dirty

### Poor Performance

1. Reduce autosave frequency
2. Decrease max autosaves limit
3. Check database file size
4. Consider compression for large JSON

### Restore Failures

1. Verify autosave ID is valid
2. Check JSON is not corrupted
3. Ensure Song model matches schema
4. Check for deserialization errors

## Best Practices

1. **Always mark songs as dirty** when changes occur
2. **Provide UI feedback** for unsaved changes
3. **Test restore functionality** regularly
4. **Monitor database size** and prune if needed
5. **Handle errors gracefully** with user notifications
6. **Cleanup resources** when shutting down

## Migration

### From Manual Save to Auto-Save

1. Initialize `AutoSaveManager`
2. Replace manual save calls with `markDirty()`
3. Add auto-save indicator to UI
4. Test restore functionality
5. Monitor performance and adjust configuration

## Future Enhancements

- [ ] Compression for large autosaves
- [ ] Cloud sync for autosaves
- [ ] Autosave export/import
- [ ] Autosave comparison/diff view
- [ ] Autosave scheduling (e.g., every 5 edits)
- [ ] Autosave tagging and descriptions
- [ ] Autosave search and filtering

## References

- **Swift Implementation**: `swift_frontend/SwiftFrontendShared/Services/AutoSaveManager.swift`
- **TypeScript Implementation**: `sdk/packages/shared/src/services/AutoSaveManager.ts`
- **Repository**: `swift_frontend/SwiftFrontendShared/Repositories/AutoSaveRepository.swift`
- **Tests**: `swift_frontend/WhiteRoomiOS/Tests/SwiftFrontendCoreTests/AutoSave/`
- **Migration**: `design_system/database/migrations/001_create_autosaves_table.sql`

## Support

For issues or questions:
1. Check this documentation
2. Review test files for examples
3. Check error messages in console
4. File issue on GitHub with details
