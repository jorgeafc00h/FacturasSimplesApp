# Testing CloudKit Troubleshooting Tools

## Overview
We've implemented several tools to diagnose and fix the CloudKit sync issue where production company customers are not syncing across devices. The issue appears to be that there are multiple companies with the same name but different IDs, and test companies that shouldn't sync.

## Testing Steps

### 1. Launch the App and Check Initial State
1. Launch the app on iPhone simulator
2. Navigate to Account tab → CloudKit Settings
3. Check if the "CloudKit Diagnostics" button is available

### 2. Run CloudKit Diagnostics
1. Tap "CloudKit Diagnostics" to see current state:
   - CloudKit account status
   - Production companies count
   - Test companies count
   - Customers count and linkage
   - Current company status

### 3. Use Sync Troubleshooting Tools
1. Go back to CloudKit Settings
2. Tap "Sync Troubleshooting" to access quick fixes:
   - Set Current Company (if needed)
   - Remove Test Companies
   - Force Sync

### 4. Use Data Cleanup Tools
1. In CloudKit Settings, tap "Data Cleanup"
2. Use cleanup options:
   - Remove Test Companies
   - Remove Duplicate Companies
   - Remove Orphaned Customers
   - Force Full Sync

### 5. Verify Results
1. Return to CloudKit Diagnostics
2. Check that:
   - Only production companies remain
   - Current company is set correctly
   - Customers are properly linked
   - No orphaned data exists

### 6. Test Cross-Device Sync
1. Force sync on one device
2. Wait a few moments
3. Check if data appears on other devices

## Expected Outcomes

After cleanup:
- Only one production company should exist
- All test companies should be removed
- Current company should be set to the production company
- The "no production account" error should be resolved
- Customers should sync across devices

## Error Resolution

If the "no production account" error persists:
1. Use "Set Current Company" in Sync Troubleshooting
2. Ensure only production companies exist using Data Cleanup
3. Force a full sync
4. Restart the app to see if onboarding is resolved

## Manual CloudKit Reset (If Needed)

If in-app tools don't resolve the issue:
1. Delete app from all devices
2. Go to CloudKit Console (developer.apple.com)
3. Select your container: `iCloud.kandangalabs.facturassimples`
4. Go to Database → Public Database
5. Delete all records from Company and Customer record types
6. Reinstall the app and set up fresh data

## Notes

- The app checks for production companies on startup
- Only production companies should sync via CloudKit
- Test companies should remain local only
- Customer data is linked to companies via companyID
