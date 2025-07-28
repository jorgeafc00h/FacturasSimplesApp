import Foundation
import SwiftUI
import SwiftData
import CryptoKit
//import JWTKit

class InvoiceServiceClient: ObservableObject
{
    
    private let encoder = JSONEncoder()
    
    private func getBaseUrl(_ isProduction: Bool) -> String{
        return  isProduction ? Constants.InvoiceServiceUrl_PRD : Constants.InvoiceServiceUrl
    }
    
    
    func getEnvironmetCode(_ isProduction: Bool) -> String{
        return isProduction ? Constants.EnvironmentCode_PRD : Constants.EnvironmentCode
    }
    
    func GetDefaultSesssion() -> URLSession
    {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = TimeInterval(Constants.HttpDefaultTimeOut)
        configuration.timeoutIntervalForResource = TimeInterval(Constants.HttpDefaultTimeOut)

        return URLSession(configuration: configuration)
    }
    
    
    
    func getCatalogs(isProduction: Bool = false)async throws -> [Catalog]
    {
        
        let endpoint = getBaseUrl(isProduction) + "/catalog"
        
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
    
    func uploadCertificate(data: Data,nit: String, isProduction: Bool) async throws -> Bool
    {
        let endpoint = getBaseUrl(isProduction)+"/document/upload"
        
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
    
    func validateCertificate(nit: String,key: String,isProduction: Bool) async throws -> Bool
    {
        let endpoint = getBaseUrl(isProduction)+"/settings/certificate/validate"
        
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
    
    func Sync(dte: DTE_Base, credentials: ServiceCredentials,isProduction: Bool )async throws -> DTEResponseWrapper
    {
       
        //encoder.dateEncodingStrategy = .iso8601 // to properly fornat Date as json instead of number.
        // Use custom date encoding strategy
        encoder.dateEncodingStrategy = .formatted(DateFormatter.iso8601DateOnly)
          
        
        let jsonData = try encoder.encode(dte)
        let jsonString = String(data: jsonData, encoding: .utf8)!
            
        print("DTE JSON")
        print(jsonString)
        print("END DTE JSON")
        
        var endpoint = getBaseUrl(isProduction)+"/document/dte/sync"
        
        
        if dte.identificacion.tipoDte == "14" {
            endpoint = getBaseUrl(isProduction)+"/document/dte/se/sync/"
        }
        
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
                
                var errors = errorModel.observaciones
                
                if !errorModel.descripcionMsg.isEmpty {
                    errors.append(errorModel.descripcionMsg)
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
    
    func uploadPDF(data : Data, controlNum: String, nit: String,isProduction: Bool) async throws  {
        
        let endpoint = getBaseUrl(isProduction) + "/document/pdf/upload"
        
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
    
    func validateCredentials(nit: String, password: String,isProduction: Bool,  forceRefresh: Bool = false)async throws -> Bool {
        
        let endpoint = getBaseUrl(isProduction) + "/account/validate?forceRefresh=\(forceRefresh)"
        
        guard let url = URL(string: endpoint) else {
            throw ApiErrors.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
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
    
    func deactivateAccount(email: String, userId: String,isProduction: Bool )async throws{
        let endpoint = getBaseUrl(isProduction) + "/account/deactivate"
        
        guard let url = URL(string: endpoint) else {
            throw ApiErrors.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Constants.Apikey, forHTTPHeaderField: Constants.ApiKeyHeaderName)
        request.setValue(userId, forHTTPHeaderField: "userId")
        request.setValue(email, forHTTPHeaderField: Constants.MH_USER)
       
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
         
       
        let (data, response) = try await GetDefaultSesssion().data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let message = String(data: data, encoding: .utf8)!
            throw ApiErrors.custom(message: message)
        }
    }
    
    func deleteAccount(email: String, userId: String,isProduction: Bool )async throws{
        let endpoint = getBaseUrl(isProduction) + "/account/delete"
        
        guard let url = URL(string: endpoint) else {
            throw ApiErrors.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Constants.Apikey, forHTTPHeaderField: Constants.ApiKeyHeaderName)
        request.setValue(userId, forHTTPHeaderField: "userId")
        request.setValue(email, forHTTPHeaderField: Constants.MH_USER)
       
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
         
       
        let (data, response) = try await GetDefaultSesssion().data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let message = String(data: data, encoding: .utf8)!
            throw ApiErrors.custom(message: message)
        }
    }
    
    func invalidateDocumentAsync(dte:  DTE_InvalidationRequest, credentials: ServiceCredentials, isProduction : Bool) async throws -> Bool {
        
        //encoder.dateEncodingStrategy = .iso8601 // to properly fornat Date as json instead of number.
        encoder.dateEncodingStrategy = .formatted(DateFormatter.iso8601DateOnly)
        
        let jsonData = try encoder.encode(dte)
        let jsonString = String(data: jsonData, encoding: .utf8)!
            
        print("DTE JSON")
        print(jsonString)
        print("END DTE JSON")
        
        let endpoint = getBaseUrl(isProduction)+"/document/dte/invalidate"
        
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
                
                var errors = errorModel.observaciones
                
                if !errorModel.descripcionMsg.isEmpty {
                    errors.append(errorModel.descripcionMsg)
                }
                
                let _customErrorMessage = errors.joined(separator: "\n")
               throw ApiErrors.custom(message: _customErrorMessage)
            
            }
            throw ApiErrors.custom(message: message)
        }
        return true
//        do{
//            return try JSONDecoder().decode(DTEResponseWrapper.self, from: data)
//        }
//        catch(_){
//            let message = String(data: data, encoding: .utf8)!
//            throw ApiErrors.custom(message: message)
//        }
    }
    
    /// Sends a contingency request to the Ministry of Finance for invoices that couldn't be processed
    /// - Parameter contingencyRequest: The contingency request containing invoices and metadata
    /// - Returns: True if the request was sent successfully
    /// - Throws: ApiErrors if the request fails
    func sendContingencyRequest(_ contingencyRequest: ContingenciaRequest,credentials: ServiceCredentials, isProduction: Bool) async throws -> Bool {
        print("📋 InvoiceServiceClient: Starting contingency request for \(contingencyRequest.detalleDTE.count) invoices")
        
        let endpoint = getBaseUrl(isProduction) + "/document/contingencia/report"
        
        guard let url = URL(string: endpoint) else {
            print("❌ InvoiceServiceClient: Invalid contingency URL")
            throw ApiErrors.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Constants.Apikey, forHTTPHeaderField: Constants.ApiKeyHeaderName)
        request.setValue(credentials.key, forHTTPHeaderField: Constants.CertificateKey)
        
        request.setValue(credentials.user, forHTTPHeaderField: Constants.MH_USER)
        request.setValue(credentials.credential, forHTTPHeaderField: Constants.MH_KEY)
        request.setValue(credentials.invoiceNumber, forHTTPHeaderField: Constants.InvoiceNumber)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(DateFormatter.iso8601DateOnly)
        
        do {
            let jsonData = try encoder.encode(contingencyRequest)
            request.httpBody = jsonData
             
            let jsonString = String(data: jsonData, encoding: .utf8)!
                
            print("REQUEST JSON")
            print(jsonString)
            print("END REQUEST JSON")
            
            let (data, response) = try await GetDefaultSesssion().data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ InvoiceServiceClient: Invalid response type")
                throw ApiErrors.invalidResponse
            }
            
            print("📋 InvoiceServiceClient: Received contingency response with status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
                print("✅ InvoiceServiceClient: Contingency request sent successfully")
                return true
            } else {
                print("❌  BInvoiceServiceClient: Contingency request failed with status: \(httpResponse.statusCode)")
                
                // Try to parse error response
                do {
                    let errorResponse = try JSONDecoder().decode(DTEErrorResponseWrapper.self, from: data)
                    let errorMessage = errorResponse.descripcionMsg
                    print("❌ InvoiceServiceClient: Error details: \(errorMessage)")
                    throw ApiErrors.custom(message: errorMessage)
                } catch {
                    let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                    print("❌ InvoiceServiceClient: Raw error response: \(message)")
                    throw ApiErrors.custom(message: "Failed to send contingency request: \(message)")
                }
            }
        } catch let encodingError as EncodingError {
            print("❌ InvoiceServiceClient: Encoding error: \(encodingError)")
            throw ApiErrors.custom(message: "Failed to encode contingency request")
        } catch {
            print("❌ InvoiceServiceClient: Network error: \(error)")
            throw error
        }
    }
    
    /// Checks the payment status for an external payment link order
    /// - Parameters:
    ///   - orderId: The order ID to check. If nil, uses the stored order ID from AppStorage
    ///   - isProduction: Whether to use production or test environment
    /// - Returns: PaymentStatusResponse containing payment status and transaction information
    /// - Throws: ApiErrors if the request fails
    func getPaymentStatus(orderId: String? = nil, isProduction: Bool) async throws -> PaymentStatusResponse {
        // Use provided orderId or get from storage
        let orderToCheck: String
        if let providedOrderId = orderId {
            orderToCheck = providedOrderId
        } else if let storedOrderId = InvoiceServiceClient.getCurrentOrderId() {
            orderToCheck = storedOrderId
        } else {
            print("❌ InvoiceServiceClient: No order ID provided and none stored")
            throw ApiErrors.custom(message: "No order ID available for payment status check")
        }
        
        print("💳 InvoiceServiceClient: Checking payment status for order: \(orderToCheck)")
        
        // todo remove this
        //let baseUrl = getBaseUrl(false)
        let baseUrl = getBaseUrl(isProduction)
        
        // Create URL with proper encoding
        var components = URLComponents(string: baseUrl + "/payment/status")!
        components.queryItems = [
            URLQueryItem(name: "orderReference", value: orderToCheck)
        ]
        
        guard let url = components.url else {
            print("❌ InvoiceServiceClient: Invalid payment status URL")
            throw ApiErrors.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Constants.Apikey, forHTTPHeaderField: Constants.ApiKeyHeaderName)
        
        do {
            let (data, response) = try await GetDefaultSesssion().data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ InvoiceServiceClient: Invalid response type for payment status")
                throw ApiErrors.invalidResponse
            }
            
            print("💳 InvoiceServiceClient: Payment status response with status: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                do {
                    let paymentStatus = try JSONDecoder().decode(PaymentStatusResponse.self, from: data)
                    print("✅ InvoiceServiceClient: Payment status retrieved successfully")
                    
                    // Log details based on format
                    if let type = paymentStatus.type {
                        // Legacy format
                        print("💳 Payment Type: \(type)")
                        print("💳 Payment Level: \(paymentStatus.level ?? "N/A")")
                        print("💳 Description: \(paymentStatus.description ?? "N/A")")
                        
                        if let metadata = paymentStatus.metadata {
                            print("💰 Paid Amount: \(metadata.paidAmount ?? "N/A")")
                            print("👤 Buyer Email: \(metadata.buyerEmail ?? "N/A")")
                            print("🔑 Authorization Code: \(metadata.authorizationCode ?? "N/A")")
                        }
                    } else {
                        // New simplified format
                        print("💳 Payment Success: \(paymentStatus.isSuccess ?? false)")
                        print("💳 Order Reference: \(paymentStatus.orderRef ?? "N/A")")
                        print("💳 Date: \(paymentStatus.date ?? "N/A")")
                        print("💳 Invoice Count: \(paymentStatus.invoiceCount ?? 0)")
                        print("💳 SKU: \(paymentStatus.sku ?? "N/A")")
                        print("💰 Paid Amount: \(paymentStatus.paidAmount ?? 0)")
                    }
                    
                    // Process successful payments and add credits automatically
                    if paymentStatus.isPaymentCompleted {
                        print("✅ Payment completed successfully - processing credits")
                        print("💳 InvoiceCount to add: \(paymentStatus.creditsToAdd)")
                        
                        // Add credits through PurchaseDataManager
                        let creditsAdded = await PurchaseDataManager.shared.processPaymentSuccess(paymentStatus)
                        if creditsAdded {
                            print("💰 Credits successfully added to user account")
                            print("📊 New balance: \(await PurchaseDataManager.shared.getCreditBalance())")
                        } else {
                            print("⚠️ Credits were not added (may already exist)")
                        }
                        
                        // Clear stored order ID
                        InvoiceServiceClient.clearCurrentOrderId()
                        print("🧹 Clearing stored order ID")
                    }
                    
                    return paymentStatus
                } catch {
                    print("❌ InvoiceServiceClient: Failed to decode payment status response: \(error)")
                    throw ApiErrors.invalidData
                }
            } else if httpResponse.statusCode == 404 {
                print("⚠️ InvoiceServiceClient: Order not found (still in progress): \(orderToCheck)")
                // Return a "not found" status indicating payment is still in progress
                return PaymentStatusResponse(notFoundOrderId: orderToCheck)
            } else {
                print("❌ InvoiceServiceClient: Payment status request failed with status: \(httpResponse.statusCode)")
                
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ InvoiceServiceClient: Raw error response: \(message)")
                throw ApiErrors.custom(message: "Failed to get payment status: \(message)")
            }
        } catch let error as ApiErrors {
            throw error
        } catch {
            print("❌ InvoiceServiceClient: Network error checking payment status: \(error)")
            throw ApiErrors.custom(message: "Network error: \(error.localizedDescription)")
        }
    }
    
    /// Generates a payment URL for external credit purchase and stores the order ID
    /// - Parameters:
    ///   - emailPrefix: The email prefix from Apple account (e.g., "jorgeafc00h")
    ///   - isProduction: Whether to use production environment
    /// - Returns: The complete payment URL
    static func generatePaymentURL(emailPrefix: String, isProduction: Bool = true) -> String {
        let guid = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(6)
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let orderId = "\(emailPrefix)-\(guid)-\(timestamp)"
        
        // Store the order ID in AppStorage for later validation
        UserDefaults.standard.set(orderId, forKey: "currentPaymentOrderId")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "paymentOrderTimestamp")
        
        let baseURL = isProduction ? "https://www.facturassimples.pro" : "https://www.facturassimples.pro"
        let paymentURL = "\(baseURL)/compra?orderId=\(orderId)"
        
        print("🔗 Generated payment URL: \(paymentURL)")
        print("💾 Stored order ID: \(orderId)")
        return paymentURL
    }
    
    /// Gets the currently stored payment order ID from AppStorage
    /// - Returns: The stored order ID if available
    static func getCurrentOrderId() -> String? {
        return UserDefaults.standard.string(forKey: "currentPaymentOrderId")
    }
    
    /// Clears the stored payment order ID (called after successful payment)
    static func clearCurrentOrderId() {
        UserDefaults.standard.removeObject(forKey: "currentPaymentOrderId")
        UserDefaults.standard.removeObject(forKey: "paymentOrderTimestamp")
        print("🧹 Cleared stored order ID")
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





