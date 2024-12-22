import SwiftUI
import AuthenticationServices

extension LoginSectionView {
    
    
    func iniciarSesion() {
        
        isAuthenticated=true
        
    }
    
    func onRequest (_ request: ASAuthorizationAppleIDRequest){
        request.requestedScopes = [.fullName, .email]
        print("scopes \(request.description)")
    }
    
     
    
    func Authorize() async{
        guard !userID .isEmpty else {
            userName = ""
            userEmail = ""
            accountId = ""
            return
        }
        
        let provider = ASAuthorizationAppleIDProvider()
        do {
            let credentialState = try await provider.credentialState(forUserID: userID)
            switch credentialState {
            case .authorized:
                print("Credential is authorized")
                userName = storedName
                userEmail = storedEmail
                
                _ = await DataModel.shared.saveProfileData(email: userEmail, userName: userName, userId: userID)
                isAuthenticated = true
                
            case .revoked:
                print("Credential is revoked")
            case .notFound:
                print("Credential not found")
            case .transferred:
                print("Credential is transferred")
            @unknown default:
                print("Unknown credential state")
            }
            
            
            
        } catch  {
            print("Error: \(error.localizedDescription)")
            
            //userName = ""
            //userEmail = ""
            //handleCredentialState(credentialState: .notFound, error: error)
        }
    }
     
    
    func handleSuccessfulLogin(with authorization: ASAuthorization) {
        if let userCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            print(userCredential.user)
            
            if userCredential.authorizedScopes.contains(.fullName) {
                print(userCredential.fullName?.givenName ?? "No given name")
            }
            
            if userCredential.authorizedScopes.contains(.email) {
                print(userCredential.email ?? "No email")
            }
            let name = userCredential.fullName?.givenName ?? ""
            let email = userCredential.email ?? ""
            
            if(!email.isEmpty){
                
                userEmail = email
                userName = name
                // _ = await DataModel.shared.saveProfileData(email: userEmail, userName: userName, userId: userID)
            }
            else{
                userEmail = "Apple@id.com"
                userName = "Apple User"
            }
            isAuthenticated = true
        }
    }
    
    func handleLoginError(with error: Error) {
        print("Could not authenticate: \\(error.localizedDescription)")
    }
    
    
}
