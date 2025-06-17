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
    }
    
    
    func RefreshRequiresOnboardingPage() {
        // Use the new DataSyncFilterManager for better logic
        viewModel.requiresOnboarding = DataSyncFilterManager.shared.shouldShowOnboarding(context: modelContext)
        
        if viewModel.requiresOnboarding {
            viewModel.selectedTab = 0
            viewModel.displayCompaniesByDefault = true
        }
        else{
            if companyIdentifier.isEmpty {
                viewModel.selectedTab = 0
            }
        }
    }
    
}
