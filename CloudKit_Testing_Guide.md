# CloudKit Sync Testing Guide

## Overview
The FacturasSimples app now includes comprehensive CloudKit sync functionality for production company data. This guide outlines how to test the sync implementation and verify that customer data syncs properly across devices.

## Build Status
✅ **Project builds successfully** with all CloudKit sync features implemented.

## Key Features Implemented

### 1. Automatic Sync on App Launch
- **File**: `CloudKitSyncManager.swift`
- **Function**: Initializes CloudKit sync when app starts
- **UI**: `CloudKitInitializationView.swift` shows sync progress
- **Integration**: Connected to `Home.swift` and `MainViewModel.swift`

### 2. Diagnostic Tools
- **CloudKit Diagnostic View**: Shows account status, companies, customers, and sync state
- **Company ID Sync Checker**: Verifies company ID consistency
- **Navigation**: Accessible from Account > CloudKit Settings > Diagnostics

### 3. Manual Sync Controls
- **Force Customer Sync**: Button in CloudKit Settings
- **Refresh from iCloud**: Manual refresh button
- **Files**: `CloudKitSettingsView.swift`, `CloudKitConfiguration.swift`

### 4. Data Model Configuration
- **SwiftData + CloudKit**: Properly configured for iCloud sync
- **Conditional Logic**: Only production companies (isTestAccount = false) should sync
- **Models**: `DataModel.swift`, `Customer.swift`, `Company.swift`

## Testing Steps

### Prerequisites
1. **iCloud Account**: Ensure both devices use the same iCloud account
2. **Development Team**: App must be signed with your development team
3. **CloudKit Container**: Verify container `iCloud.kandangalabs.facturassimples` exists

### Phase 1: Initial Setup Testing

#### Step 1: Clean State
1. Delete app from both devices (Mac and iPhone)
2. Reset CloudKit data (see manual reset instructions below)
3. Install fresh build on both devices

#### Step 2: First Device Setup (Mac)
1. Launch app on Mac
2. Watch `CloudKitInitializationView` for sync status
3. Complete onboarding if shown
4. Create a **production company** (ensure isTestAccount = false)
5. Navigate to Account > CloudKit Settings > Diagnostics
6. Verify:
   - CloudKit account status is "Available"
   - Company appears in sync diagnostics
   - No errors shown

#### Step 3: Add Customers on Mac
1. Create 2-3 customers for the production company
2. Use CloudKit Diagnostics to verify customers appear
3. Check that customer company IDs match production company ID

#### Step 4: Second Device Sync (iPhone)
1. Launch app on iPhone
2. Watch initialization screen for sync status
3. Check if:
   - Production company syncs automatically
   - Customers appear for the company
   - No onboarding shown (since company exists)

### Phase 2: Ongoing Sync Testing

#### Test 1: Add Customer on iPhone
1. Add new customer on iPhone
2. Use "Force Customer Sync" on iPhone
3. Switch to Mac and use "Refresh from iCloud"
4. Verify customer appears on Mac

#### Test 2: Edit Customer on Mac
1. Edit existing customer on Mac
2. Use sync tools to force sync
3. Verify changes appear on iPhone

#### Test 3: Test Company Limitations
1. Create a **test company** (isTestAccount = true) on one device
2. Add customers to test company
3. Verify test company data does NOT sync to other device
4. Verify only production company data syncs

### Phase 3: Diagnostic Verification

#### CloudKit Diagnostic View Tests
1. Navigate to Account > CloudKit Settings > Diagnostics
2. Verify the following information is accurate:
   - **Account Status**: Should show "Available" 
   - **Companies**: Lists all companies with sync status
   - **Customers**: Shows customers linked to each company
   - **Sync State**: Indicates last sync times and any errors

#### Company ID Sync Checker Tests
1. Use the Company ID Sync Checker tool
2. Verify it reports:
   - Company ID consistency across customers
   - Any orphaned customers (customers without valid company)
   - Sync state validation

## Manual CloudKit Reset (If Needed)

### Option 1: CloudKit Console (Recommended)
1. Visit [CloudKit Console](https://icloud.developer.apple.com/dashboard)
2. Sign in with Apple Developer account
3. Select your app and container
4. Go to Development > Data
5. Delete all records for Company and Customer record types
6. Reset the schema if needed

### Option 2: Device Settings
1. On each device: Settings > [Your Name] > iCloud > Manage Storage
2. Find your app and delete its data
3. Restart devices
4. Re-enable iCloud for the app

### Option 3: App-Level Reset
1. Delete app from all devices
2. Clean build folder in Xcode: Product > Clean Build Folder
3. Fresh install and setup

## Common Issues and Solutions

### Issue: Customers Not Syncing
**Potential Causes:**
- Customer's company ID doesn't match production company
- Test company data (isTestAccount = true) won't sync
- iCloud account not properly configured

**Solutions:**
1. Use Company ID Sync Checker to verify linkage
2. Force Customer Sync from CloudKit Settings
3. Check CloudKit Diagnostics for errors

### Issue: Onboarding Always Shows
**Potential Causes:**
- No production companies in local or CloudKit data
- Sync not completing before onboarding check

**Solutions:**
1. Ensure at least one production company exists
2. Wait for sync initialization to complete
3. Use CloudKit Diagnostics to verify company sync status

### Issue: CloudKit Account Unavailable
**Potential Causes:**
- Not signed into iCloud
- CloudKit not enabled for app
- Network connectivity issues

**Solutions:**
1. Check device iCloud settings
2. Verify app has iCloud permission
3. Check network connection
4. Try signing out/in to iCloud

## Expected Behavior

### What Should Sync
✅ Production companies (isTestAccount = false)
✅ Customers belonging to production companies
✅ Customer edits and updates

### What Should NOT Sync
❌ Test companies (isTestAccount = true)
❌ Customers belonging to test companies
❌ Local app settings/preferences

## Files Modified/Created

### Core Sync Implementation
- `/FacturasSimples/Services/CloudKitSyncManager.swift` - Main sync logic
- `/FacturasSimples/Services/CloudKitConfiguration.swift` - Sync utilities
- `/FacturasSimples/Shared/DataModel.swift` - SwiftData + CloudKit config

### Diagnostic Tools
- `/FacturasSimples/Views/Account/CloudKitDiagnosticView.swift`
- `/FacturasSimples/Views/Account/CompanyIDSyncChecker.swift`
- `/FacturasSimples/Views/Account/CloudKitSettingsView.swift`

### UI Integration
- `/FacturasSimples/Views/Common/CloudKitInitializationView.swift`
- `/FacturasSimples/Views/Home.swift`
- `/FacturasSimples/ViewModels/MainViewModel.swift`

## Next Steps

1. **Test the complete flow** using the steps above
2. **Monitor CloudKit Console** for sync activity and errors
3. **Verify data consistency** across devices using diagnostic tools
4. **Test edge cases** like network interruptions and app backgrounding
5. **Optimize sync timing** if needed based on user experience

## Support Resources

- [CloudKit Documentation](https://developer.apple.com/documentation/cloudkit)
- [SwiftData CloudKit Integration](https://developer.apple.com/documentation/swiftdata/synchronizing-data-with-cloudkit)
- [CloudKit Console](https://icloud.developer.apple.com/dashboard)

The implementation is now complete and ready for testing. The diagnostic tools should help identify any sync issues quickly, and the manual sync controls provide fallback options for users experiencing sync problems.
