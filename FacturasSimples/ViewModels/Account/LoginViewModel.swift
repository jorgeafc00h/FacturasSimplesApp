import SwiftUI
import AuthenticationServices
//import MSAL


extension LoginSectionView {
    
    
    func iniciarSesion() {
        
        isAuthenticated=true
        
    }
    
    func onRequest (_ request: ASAuthorizationAppleIDRequest){
        print("Apple Sign In request initiated")
        isLoading = true
        request.requestedScopes = [.fullName, .email]
        print("Requested scopes: \(request.requestedScopes ?? [])")
        print("Request state: \(request.state ?? "none")")
    }
    
    func Authorize() async{
        print("Authorize function called")
        print("Current userID: \(userID)")
        
        guard !userID.isEmpty else {
            print("No stored userID found, resetting values")
            userName = ""
            userEmail = ""
            accountId = ""
            return
        }
        
        let provider = ASAuthorizationAppleIDProvider()
        do {
            print("Checking credential state for userID: \(userID)")
            let credentialState = try await provider.credentialState(forUserID: userID)
            print("Credential state: \(credentialState)")
            
            switch credentialState {
            case .authorized:
                print("Credential is authorized - auto-logging in")
                userName = storedName
                userEmail = storedEmail 
                DispatchQueue.main.async {
                    self.isAuthenticated = true
                }
                
            case .revoked:
                print("Credential is revoked - clearing stored data")
                userID = ""
                userName = ""
                userEmail = ""
                storedName = ""
                storedEmail = ""
                
            case .notFound:
                print("Credential not found - clearing stored data")
                userID = ""
                userName = ""
                userEmail = ""
                storedName = ""
                storedEmail = ""
                
            case .transferred:
                print("Credential is transferred")
                
            @unknown default:
                print("Unknown credential state")
            }
            
        } catch {
            print("Error checking credential state: \(error.localizedDescription)")
            print("Error details: \(error)")
        }
    }
     
    func onCompletion(_result : Result<ASAuthorization,Error>){
        isLoading = false
        switch _result{
        case .success(let authResult):
            print("Apple Sign In Success: \(authResult)")
            guard let credential = authResult.credential as? ASAuthorizationAppleIDCredential
            else { 
                print("Failed to get Apple ID credential")
                return 
            }
            
            print("User ID: \(credential.user)")
            print("Full Name: \(credential.fullName?.givenName ?? "N/A")")
            print("Email: \(credential.email ?? "N/A")")
            
            storedName = credential.fullName?.givenName ?? ""
            storedEmail = credential.email ?? ""
            userID = credential.user
            identityToken = credential.identityToken?.base64EncodedString() ?? ""
            
            // Set flag to indicate user signed in with Apple
            UserDefaults.standard.set(true, forKey: "didSignInWithApple")
            
            // Check for demo credentials and enable appropriate modes
            if credential.email == "reviewer@apple.com" || credential.email == "demo@facturassimples.com" {
                FeatureFlags.shared.enableDemoMode()
                FeatureFlags.shared.enableAppleIAPOnly()
            }
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.isAuthenticated = true
                print("Authentication set to true")
            }
            
        case .failure(let error):
            print("Apple Sign In Authorization failed: \(error)")
            print("Error code: \((error as NSError).code)")
            print("Error domain: \((error as NSError).domain)")
            
            // Handle specific error cases
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    print("User canceled the authorization")
                case .failed:
                    print("Authorization failed")
                case .invalidResponse:
                    print("Invalid response received")
                case .notHandled:
                    print("Authorization not handled")
                case .unknown:
                    print("Unknown authorization error")
                case .notInteractive:
                    print("Not interactive authorization error")
                case .matchedExcludedCredential:
                    print("Matched excluded credential error")
                case .credentialImport:
                    print("Credential import error")
                case .credentialExport:
                    print("Credential export error")
                @unknown default:
                    print("Unknown authorization error case")
                }
            }
        }
    }
    
}
