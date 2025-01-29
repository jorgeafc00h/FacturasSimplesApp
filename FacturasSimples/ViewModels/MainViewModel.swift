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
    }
    
    
    func RefreshRequiresOnboardingPage() {
        
        let descriptor = FetchDescriptor<Company>()
        
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0
         
        viewModel.requiresOnboarding = count == 0
        
        if count == 0 {
            viewModel.selectedTab = 0
            viewModel.displayCompaniesByDefault = true
        }
    }
    
}
