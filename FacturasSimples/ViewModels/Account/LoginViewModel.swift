import SwiftUI
import AuthenticationServices
//import MSAL


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
     
    func onCompletion(_result : Result<ASAuthorization,Error>){
        switch _result{
        case .success(let authResult):
            guard let credential = authResult.credential as? ASAuthorizationAppleIDCredential
            else { return }
            storedName = credential.fullName?.givenName ?? ""
            storedEmail = credential.email ?? ""
            userID = credential.user
            identityToken = credential.identityToken?.base64EncodedString() ?? ""
            isAuthenticated = true
            
        case .failure(let error):
            print("Authorization failed "+error.localizedDescription)
        }
    }
    
}
