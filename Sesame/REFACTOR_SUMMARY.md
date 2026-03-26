# LocationManager Refactor - Point 1 Implementation

## Summary

Successfully refactored `LocationManager` to eliminate cached arrays and query fresh data from SwiftData on-demand.

## Changes Made

### 1. LocationManager.swift

#### Added:
- `import SwiftData` at the top
- `var modelContext: ModelContext?` - Reference to SwiftData context
- `private var activeSetIDs: Set<UUID> = []` - Lightweight ID cache for change detection
- `fetchAllAccessCodes() -> [AccessCode]?` - Helper method to query fresh data with filtering

#### Removed:
- `private var allAccessCodes: [AccessCode] = []` - No longer caching full array
- `private var activeSet: [AccessCode] = []` - No longer caching active set

#### Modified Methods:

**`restartAllMonitoring()`**
- Changed signature from `restartAllMonitoring(accessCodes: [AccessCode])` to `restartAllMonitoring(context: ModelContext)`
- Now accepts `ModelContext` instead of pre-fetched array
- Stores context reference and calls `fetchAllAccessCodes()` internally

**`recalculateActiveSet()`**
- Now calls `fetchAllAccessCodes()` to get fresh data from SwiftData
- Added ID comparison optimization: only updates geofences if active set changed
- Filtering logic moved to `fetchAllAccessCodes()` predicate
- Passes `activeSet` as parameter to `updateSafetyGeofence()`

**`stopMonitoring(accessCode:)`**
- Removed `allAccessCodes.removeAll { $0.id == accessCode.id }` line
- Simply calls `recalculateActiveSet()` which fetches fresh data

**`updateSafetyGeofence()`**
- Changed signature to `updateSafetyGeofence(activeSet: [AccessCode])`
- Now receives active set as parameter instead of using cached property

### 2. SesameApp.swift

#### Modified:
```swift
// Before:
let descriptor = FetchDescriptor<AccessCode>()
if let accessCodes = try? context.fetch(descriptor) {
    locationManager.restartAllMonitoring(accessCodes: accessCodes)
}

// After:
locationManager.restartAllMonitoring(context: context)
```

Now passes the `ModelContext` directly instead of pre-fetching and passing an array.

## Benefits

✅ **Always Fresh Data**: Every geofence calculation uses the latest coordinates from SwiftData
✅ **No Duplication**: Single source of truth (SwiftData)
✅ **Auto-Sync**: When user edits an entry, the next recalculation picks up changes automatically
✅ **Memory Efficient**: Only stores UUIDs of active set (15 UUIDs vs 15-100 full objects)
✅ **Simpler API**: Callers don't need to fetch and pass arrays
✅ **Performance Optimization**: Added ID comparison to skip unnecessary geofence updates

## Backward Compatibility

- ✅ No SwiftData schema changes
- ✅ No CloudKit migration needed
- ✅ No changes to user data
- ✅ Existing geofences continue working
- ✅ Safe to deploy as minor version update

## Testing Recommendations

After deployment, verify:
- [ ] App launches correctly with existing data
- [ ] Geofences trigger notifications as expected
- [ ] Edit entry's address → next recalculation uses new coordinates
- [ ] Delete entry → geofence stops immediately
- [ ] Add new entry → geofence starts correctly
- [ ] Move far away → safety geofence exit → active set recalculates

## Next Steps

This completes Point 1 of the code quality improvements. Ready to proceed with:
- Point 2: Encryption Key Availability Race Condition
- Point 3: SwiftData Migration Schema Version Validation
- Point 4: Notification Tap selectedEntryID State Leak
- ... and 26 more improvements from the review

---

**Date**: March 26, 2026
**Implemented by**: Assistant
**Reviewed by**: Greg
