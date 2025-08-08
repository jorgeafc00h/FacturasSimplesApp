import Foundation

class FeatureFlags {
    static let shared = FeatureFlags()
    
    private init() {}
    
    // Demo mode for App Store reviewers
    var isDemoMode: Bool {
        #if DEBUG
        return true // Always enable in debug for testing
        #else
        // Check for demo credentials or specific flag
        return UserDefaults.standard.bool(forKey: "isDemoMode") || 
               checkForDemoCredentials()
        #endif
    }
    
    // Force only Apple In-App Purchases for App Store compliance
    var shouldUseOnlyAppleInAppPurchases: Bool {
        // Always return true for App Store compliance
        return true
    }
    
    private func checkForDemoCredentials() -> Bool {
        // Check if specific demo email is being used
        let storedEmail = UserDefaults.standard.string(forKey: "storedEmail") ?? ""
        return storedEmail == "reviewer@apple.com" || 
               storedEmail == "demo@facturassimples.com" ||
               storedEmail == "danielsandovaleu@gmail.com"
    }
    
    // Enable demo mode programmatically
    func enableDemoMode() {
        UserDefaults.standard.set(true, forKey: "isDemoMode")
    }
    
    // Disable demo mode
    func disableDemoMode() {
        UserDefaults.standard.set(false, forKey: "isDemoMode")
    }
    
    // Force Apple IAP only
    func enableAppleIAPOnly() {
        UserDefaults.standard.set(true, forKey: "forceAppleIAPOnly")
    }
}