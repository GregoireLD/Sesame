# Point 1 Implementation - Build & Test Checklist

## Pre-Build Verification

- [x] LocationManager.swift imports SwiftData
- [x] Removed cached `allAccessCodes` and `activeSet` arrays
- [x] Added `modelContext: ModelContext?` property
- [x] Added `activeSetIDs: Set<UUID>` for lightweight caching
- [x] Created `fetchAllAccessCodes()` helper method
- [x] Updated `restartAllMonitoring()` to accept ModelContext
- [x] Updated `recalculateActiveSet()` to fetch fresh data
- [x] Added ID comparison optimization in `recalculateActiveSet()`
- [x] Updated `updateSafetyGeofence()` to accept activeSet parameter
- [x] Simplified `stopMonitoring()` to remove array mutation
- [x] Updated SesameApp.swift call site

## Build Steps

1. Open Xcode project
2. Clean build folder (⇧⌘K)
3. Build project (⌘B)
4. Verify no compilation errors

## Expected Compilation Results

✅ **Should compile successfully** - All changes are type-safe and backward compatible

⚠️ **If you see errors:**
- Check that SwiftData is imported in LocationManager.swift
- Verify Item.swift defines `AccessCode` model correctly
- Ensure deployment target supports SwiftData (iOS 17+)

## Runtime Testing

### Test 1: Fresh Install
1. Delete app from simulator/device
2. Install and launch
3. Grant location permissions
4. Add 3-5 entries with different addresses
5. **Expected**: Geofences register, notifications trigger when entering radius

### Test 2: Existing User Upgrade
1. Install old version (if available)
2. Add 10+ entries
3. Update to new version
4. **Expected**: All entries still visible, geofences continue working

### Test 3: Dynamic Mode (>15 entries)
1. Add 20 entries
2. Launch app
3. Check Console for geofence registration
4. **Expected**: Only 15 closest entries monitored, safety geofence active

### Test 4: Edit Entry Coordinates
1. Create entry "Home" at current location
2. Move away (or simulate movement)
3. Edit "Home" address to new location
4. Trigger recalculation (move or relaunch app)
5. **Expected**: Geofence uses NEW coordinates (this was broken before!)

### Test 5: Delete Entry
1. Create entry
2. Verify it's monitored (check Console)
3. Delete entry
4. **Expected**: Geofence stops immediately, recalculation happens

## Console Monitoring

Watch for these log messages:
```
✅ "Monitoring started for region: <UUID>"
✅ "Monitoring stopped for region: <UUID>"
❌ "LocationManager error: ..." (should not appear)
❌ "Monitoring failed for region: ..." (should not appear)
```

## Performance Check

**Before**: LocationManager held 100+ AccessCode objects in memory
**After**: LocationManager holds only 15 UUIDs

To verify:
1. Add 50+ entries
2. Use Xcode Memory Graph (Debug > View Memory > Memory Graph)
3. Filter for "AccessCode"
4. **Expected**: ~50 instances (from SwiftData), not 50+50+15 (cached copies)

## Edge Cases to Test

- [ ] Launch app with 0 entries → Should not crash
- [ ] Launch app with location disabled → Should handle gracefully
- [ ] Launch app in airplane mode → Should queue geofences for later
- [ ] Rapidly add/delete entries → Should not crash or leak memory
- [ ] Silence an entry → Should recalculate active set (if in dynamic mode)

## Rollback Plan (If Needed)

If critical bugs appear:

1. Revert LocationManager.swift changes:
   - Restore `allAccessCodes` and `activeSet` properties
   - Change `restartAllMonitoring(context:)` back to `restartAllMonitoring(accessCodes:)`
   
2. Revert SesameApp.swift changes:
   - Re-add `FetchDescriptor` and array passing

3. No data migration needed — user data unaffected

## Success Criteria

✅ App builds without errors
✅ Existing users see no behavioral changes
✅ Geofences trigger correctly
✅ Memory usage improved
✅ Edited entries use fresh coordinates (bug fix verified!)

---

**Ready for Point 2?** Once you've verified the build, we can move on to:
→ Point 2: Encryption Key Availability Race Condition
