import SwiftUI
import SwiftData

extension mainView{
     
    
    @Observable
    class MainViewModel {
        var requiresOnboarding : Bool = false
        var selectedTab : Int = 2
        var selectedCompanyId: String = ""
        var isAuthenticated: Bool = false
        var displayCompaniesByDefault: Bool = false
        var needsCloudKitSync: Bool = true
        var cloudKitSyncCompleted: Bool = false
        
        func skipCloudKitSync() {
            needsCloudKitSync = false
            cloudKitSyncCompleted = true
        }
        
        /// Force a refresh of the onboarding state - useful for debugging or manual refresh
        @MainActor
        func forceRefreshOnboardingState(context: ModelContext) {
            let shouldShow = DataSyncFilterManager.shared.shouldShowOnboarding(context: context)
            print("🔄 Force refresh: shouldShow = \(shouldShow)")
            requiresOnboarding = shouldShow
        }
    }
    
    
    @MainActor
    func RefreshRequiresOnboardingPage() async {
        // Force a context refresh to ensure we have the latest synced data
        do {
            try modelContext.save()
        } catch {
            print("⚠️ Failed to save model context: \(error)")
        }
        
        // Use the new DataSyncFilterManager for better logic
        let shouldShow = DataSyncFilterManager.shared.shouldShowOnboarding(context: modelContext)
        
        // Debug logging
        let descriptor = FetchDescriptor<Company>()
        let companyCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        print("🔄 RefreshRequiresOnboardingPage: Company count = \(companyCount), shouldShow = \(shouldShow)")
        
        viewModel.requiresOnboarding = shouldShow
        
        if viewModel.requiresOnboarding {
            print("📋 Showing onboarding - no companies found")
            viewModel.selectedTab = 0
            viewModel.displayCompaniesByDefault = true
        }
        else{
            print("✅ Skipping onboarding - companies exist")
            if companyIdentifier.isEmpty {
                viewModel.selectedTab = 0
            }
        }
    }
    
}
