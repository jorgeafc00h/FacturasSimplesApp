import Foundation
import SwiftUI
import SwiftData
import CryptoKit
//import JWTKit

class InvoiceServiceClient
{
    
    
    func getCatalogs()async throws -> [Catalog]
    {
        
        let endpoint = Constants.InvoiceServiceUrl+"/catalog"
        
        guard let url = URL(string: endpoint) else {
            throw ApiErrors.invalidURL
        }
        
        let (data ,response) = try await URLSession.shared.data(from: url)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw ApiErrors.invalidResponse
        }
        
        do{
            
            let catalogDto = try JSONDecoder().decode(CatalogCollection.self, from: data)
            
            let catalogs =  catalogDto.catalogs.map{
                
                let c = Catalog(id:$0.id,name: $0.name)
                
                c.options = $0.options.map{ CatalogOption(code: $0.code,description: $0.description,departamento: $0.departamento,catalog: c)}
                
                return c
            }
            
            return catalogs
        }
        catch{
            throw ApiErrors.invalidData
        }
    }
    
    func uploadCertificate(data: Data,nit: String) async throws -> Bool
    {
        let endpoint = Constants.InvoiceServiceUrl+"/document/upload"
        guard let url = URL(string: endpoint) else {
            throw ApiErrors.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Constants.Apikey, forHTTPHeaderField: "apiKey")
        request.setValue(nit, forHTTPHeaderField: "MH_USER")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
               
        request.httpBody = data
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return true;
    }
    
}
//        let token = try await generateToken(teamId: "62V6DQB2H6",
//                                  clientId: "com.kandangalabs.App",
//                                  keyId: "XQX4HH9KMP",
//                                  privateKey:"-----BEGIN PRIVATE KEY-----\n" +
//                                  "MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg1Mswn8jEblM7n0hP\n" +
//                                  "kzjUGBgcnJBX/hfvjThJ851NmfqgCgYIKoZIzj0DAQehRANCAAShTGVzbZ9Din+D\n" +
//                                  "Nu3oy3X20jPMML8wPpDQLuFiqh4HdhKAr+TxCXvLbtpWoOF4m2bNizTdfOTd5iSQ\n" +
//                                  "yl/8Tgec\n" +
//                                  "-----END PRIVATE KEY-----"
//        )

//    /// Generates a client secret token for Sign in with Apple
//    /// - Parameters:
//    ///   - teamId: Your Apple Developer Team ID
//    ///   - clientId: Your Services ID identifier
//    ///   - keyId: The key ID from your private key
//    ///   - privateKey: The private key content from the .p8 file
//    /// - Returns: A JWT token string to use as client_secret
//    func generateToken(teamId: String, clientId: String, keyId: String, privateKey: String) async throws -> String {
//        let currentTime = Date()
//        let expiration = currentTime.addingTimeInterval(15777000) // 6 months in seconds
//        
//        // Create the claims according to Apple's requirements
//        let claims = AppleTokenClaims(
//            iss: .init(value: teamId),           // Your 10-character Team ID
//            iat: .init(value: currentTime),       // Current time
//            exp: .init(value: expiration),        // Expiration time
//            aud: .init(value: "https://appleid.apple.com"), // Fixed audience
//            sub: .init(value: clientId)           // Your Services ID identifier
//        )
//        
//        // Create JWT key collection
//        let keys = JWTKeyCollection()
//        
//        // Load and validate the private key
//        guard let privateKey = try? ES256PrivateKey(pem: privateKey) else {
//            throw ApiTokenErrors.invalidKey
//        }
//        
//        // Add the key with its identifier
//        try await keys.add(ecdsa: privateKey, kid: JWKIdentifier(string: keyId))
//        
//        // Generate the signed JWT
//        let token = try await keys.sign(
//            claims,
//            header: [
//                "kid": .string(keyId),
//                "alg": .string("ES256")
//            ]
//        )
//        
//        return token
//    }
//}

// Claims structure as per Apple's requirements
//struct AppleTokenClaims: JWTPayload {
//    var iss: IssuerClaim      // Team ID
//    var iat: IssuedAtClaim    // Issued at time
//    var exp: ExpirationClaim  // Expiration time
//    var aud: AudienceClaim    // Audience
//    var sub: SubjectClaim     // Client ID
//    
//    func verify(using signer: some JWTAlgorithm) throws {
//        try exp.verifyNotExpired()
//    }
//}





