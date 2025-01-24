// 
//import JWTKit
//import Foundation
//
//// snippet.EXAMPLE_PAYLOAD
//struct AppleClaims: JWTPayload {
//    var iss: IssuerClaim
//    var sub: SubjectClaim
//    var aud: AudienceClaim
//    var exp: ExpirationClaim
//    
//    func verify(using _: some JWTAlgorithm) throws {
//        try exp.verifyNotExpired()
//    }
//}
//
enum ApiTokenErrors: Error {
    case invalidURL
    case invalidResponse
    case invalidData
    case invalidKey
}
//
//
//
//class AuthenticationService{
//    
//    func getAppleClientSecret(teamId: String, clientId: String, keyId: String, p8key: String) async throws -> String {
//        let audience = "https://appleid.apple.com"
//        let issuer = teamId
//        let subject = clientId
//        
//        // Create payload with required claims
//        let payload = AppleClaims(
//            iss: .init(value: issuer),
//            sub: .init(value: subject),
//            aud: .init(value: audience),
//            exp: .init(value: Date().addingTimeInterval(180 * 24 * 60 * 60)) // 180 days from now
//        )
//        
//        // Create JWT key collection
//        let keys = JWTKeyCollection()
//        
//        // Load the private key from p8 string
//        guard let privateKey = try? ES256PrivateKey(pem: p8key) else {
//            throw ApiTokenErrors.invalidKey
//        }
//        
//        // Add the key to collection with the specified key ID
//        try await keys.add(ecdsa: privateKey, kid: JWKIdentifier(string: keyId))
//        
//        // Sign the payload and get the token
//        let token = try await keys.sign(
//            payload,
//            header: [
//                "kid": .string(keyId),
//                "typ": .null // Remove typ header
//            ]
//        )
//        
//        return token
//    }
//    
//}
