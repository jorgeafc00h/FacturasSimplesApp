import Foundation
import SwiftUI
import SwiftData
import CryptoKit
//import JWTKit

class InvoiceServiceClient
{
    func GetDefaultSesssion() -> URLSession
    {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = TimeInterval(Constants.HttpDefaultTimeOut)
        configuration.timeoutIntervalForResource = TimeInterval(Constants.HttpDefaultTimeOut)

        return URLSession(configuration: configuration)
    }
    
    private let encoder = JSONEncoder()
    
    func getCatalogs()async throws -> [Catalog]
    {
        
        let endpoint = Constants.InvoiceServiceUrl+"/catalog"
        
        guard let url = URL(string: endpoint) else {
            throw ApiErrors.invalidURL
        }
         
        let (data ,response) = try await GetDefaultSesssion().data(from: url)
        
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
        request.setValue(nit, forHTTPHeaderField: Constants.MH_USER)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
               
        request.httpBody = data
        
        let (data, response) = try await GetDefaultSesssion().data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            //throw URLError(.badServerResponse)
            let message = String(data: data, encoding: .utf8)!
            throw ApiErrors.custom(message: message)
        }
        return true;
    }
    
    func validateCertificate(nit: String,key: String) async throws -> Bool
    {
        let endpoint = Constants.InvoiceServiceUrl+"/settings/certificate/validate"
        guard let url = URL(string: endpoint) else {
            throw ApiErrors.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        request.setValue(Constants.Apikey, forHTTPHeaderField: "apiKey")
        request.setValue(key, forHTTPHeaderField: Constants.CertificateKey)
        request.setValue(nit, forHTTPHeaderField: Constants.MH_USER)
        
        let (data, response) = try await GetDefaultSesssion().data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let message = String(data: data, encoding: .utf8)!
            throw ApiErrors.custom(message: message)
        }
        
        let resultMessage = String(data: data, encoding: .utf8)!
        
        print("result validate certificate: \(resultMessage)")
        return resultMessage == "true"
        
    }
    
    func Sync(dte: DTE_Base, credentials: ServiceCredentials)async throws -> DTEResponseWrapper
    {
       // let encoder = JSONEncoder()
        //encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601 // to properly fornat Date as json instead of number.
        
        let jsonData =  try encoder.encode(dte)
        let jsonString = String(data: jsonData, encoding: .utf8)!
            
        print("DTE JSON")
        print(jsonString)
        
        let endpoint = Constants.InvoiceServiceUrl+"/document/dte/sync"
        guard let url = URL(string: endpoint) else {
            throw ApiErrors.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Constants.Apikey, forHTTPHeaderField: Constants.ApiKeyHeaderName)
        request.setValue(credentials.key, forHTTPHeaderField: Constants.CertificateKey)
        
        request.setValue(credentials.user, forHTTPHeaderField: Constants.MH_USER)
        request.setValue(credentials.credential, forHTTPHeaderField: Constants.MH_KEY)
        
        request.setValue(credentials.invoiceNumber, forHTTPHeaderField: Constants.InvoiceNumber)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
               
        request.httpBody = jsonData
        
       
        let (data, response) = try await GetDefaultSesssion().data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let message = String(data: data, encoding: .utf8)!
            
            // try decode into DTE With Error and observations.
            let errorDte = try? JSONDecoder().decode(DTEErrorResponseWrapper.self, from: data)
            
            if let errorModel = errorDte {
                
                var errors = errorModel.response.observaciones
                
                if !errorModel.response.descripcionMsg.isEmpty {
                    errors.append(errorModel.response.descripcionMsg)
                }
                
                let _customErrorMessage = errors.joined(separator: "\n")
               throw ApiErrors.custom(message: _customErrorMessage)
            
            }
            throw ApiErrors.custom(message: message)
        }
        do{
            return try JSONDecoder().decode(DTEResponseWrapper.self, from: data)
        }
        catch(_){
            let message = String(data: data, encoding: .utf8)!
            throw ApiErrors.custom(message: message)
        }
    }
    
    func uploadPDF(data : Data, controlNum: String, nit: String) async throws -> Bool {
        let endpoint = Constants.InvoiceServiceUrl + "/document/pdf/upload"
        guard let url = URL(string: endpoint) else {
            throw ApiErrors.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Constants.Apikey, forHTTPHeaderField: Constants.ApiKeyHeaderName)
        request.setValue(nit, forHTTPHeaderField: Constants.MH_USER)
        request.setValue(controlNum, forHTTPHeaderField: Constants.InvoiceNumber)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = data.base64EncodedString(options: .lineLength64Characters).data(using: .utf8)
       
        let (data, response) = try await GetDefaultSesssion().data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let message = String(data: data, encoding: .utf8)!
            throw ApiErrors.custom(message: message)
        }
        return true
    }
 
    func getDocumentFromStorage(path: String)async throws -> DTE_Base {
        guard let url = URL(string: path) else {
            throw ApiErrors.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        
        let (data, response) = try await GetDefaultSesssion().data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let message = String(data: data, encoding: .utf8)!
            throw ApiErrors.custom(message: message)
        }
        do{
            return try JSONDecoder().decode(DTE_Base.self, from: data)
        }
        catch(let error){
            print("\(error.localizedDescription)")
            let message = String(data: data, encoding: .utf8)!
            throw ApiErrors.custom(message: message)
        }
        
    }
    
    func validateCredentials(nit: String, password: String, forceRefresh: Bool = false)async throws -> Bool {
        let endpoint = Constants.InvoiceServiceUrl + "/account/validate?forceRefresh=\(forceRefresh)"
        guard let url = URL(string: endpoint) else {
            throw ApiErrors.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Constants.Apikey, forHTTPHeaderField: Constants.ApiKeyHeaderName)
        request.setValue(nit, forHTTPHeaderField: Constants.MH_USER)
        request.setValue(password, forHTTPHeaderField: Constants.MH_KEY)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
       
        let (data, response) = try await GetDefaultSesssion().data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let message = String(data: data, encoding: .utf8)!
            throw ApiErrors.custom(message: message)
        }
        return true
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





