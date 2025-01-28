//
//import Foundation
//import XMLCoder
//import JWTKit
//
//class DocumentSigner {
//    
//    
// 
//    func signDocument(request: DocumentSigningRequest, certificatePath: String) async throws -> SigningResponse {
//        do {
//            // 1. Validate request
//            guard !request.nit.isEmpty,
//                  !request.passwordPri.isEmpty,
//                  !request.dteJson.isEmpty else {
//                throw SigningError.invalidInput("Required fields are missing")
//            }
//            
//            // 2. Get certificate
////            let certificate = try await getCertificate(nit: request.nit, password: request.passwordPri, path: certificatePath)
////            
////            let signature = try await signJSON(certificate: certificate, content: request.dteJson)
//            
//            return SigningResponse(
//                success: true,
//                signature: nil,
//                error: nil
//            )
//            
//        } catch let error as SigningError {
//            return SigningResponse(
//                success: false,
//                signature: nil,
//                error: error.localizedDescription
//            )
//        } catch {
//            return SigningResponse(
//                success: false,
//                signature: nil,
//                error: "Unexpected error occurred"
//            )
//        }
//    }
//    
//    private func getCertificate(nit: String, password: String,path : String) async throws -> CertificadoMH {
//        do {
//            
//            let crypto = try Cryptographic.encrypt(password, algorithm: "SHA512")
//            
//            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//            
//            let certsURL = documentsURL.appendingPathComponent("Certificates")
//            
//            let certificatePath = certsURL.appendingPathComponent(path)
//            
//            
//            //let xmlData = try String(contentsOf: certificatePath, encoding: .utf8)
//            
//            let xmlData = try Data.init(contentsOf: certificatePath)
//            
//            // 3. Decode certificate
//            let decoder = XMLDecoder()
//            decoder.dateDecodingStrategy = .iso8601
//            let certificate = try decoder.decode(CertificadoMH.self, from: xmlData)
//            print(certificate)
//            
//            // 4. Validate password
//            if certificate.privateKey.clave == crypto {
//                return certificate
//            } else {
//                throw SigningError.certificateError
//            }
//            
//        } catch let error as SigningError {
//            throw error
//        } catch(let error) {
//            print("error al leer el certificado: \(error.localizedDescription)")
//            throw SigningError.certificateError
//        }
//    }
//    
////    private func signJSON(certificate: CertificadoMH, content: String) async throws -> String {
////        do {
////            // Create JWS
////            let jws = try JWS()
////            
////            // Set payload
////            try jws.setPayload(content)
////            
////            // Set algorithm
////            try jws.setAlgorithm(.RS512)
////            
////            // Set private key
////            try jws.setKey(certificate.privateKey.encodied)
////            
////            // Get compact serialization
////            return try await jws.getCompactSerialization()
////            
////        } catch {
////            throw SigningError.signingError
////        }
////    }
////    func getDocumentsDirectory() -> URL {
////        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
////    }
//}
//
//
//// Protocol for resource loading
////protocol ResourceLoader {
////    func readResource(from location: String) async throws -> String
////}
//
//// Default implementation
////class DefaultResourceLoader: ResourceLoader {
////    func readResource(from location: String) async throws -> String {
////        guard let resourcePath = Bundle.main.path(forResource: location, ofType: nil),
////              let content = try? String(contentsOfFile: resourcePath, encoding: .utf8) else {
////            throw SigningError.resourceNotFound
////        }
////        return content
////    }
////}
//
//// JWS implementation (simplified version of Jose4j's JsonWebSignature)
////class JWS {
////    private var payload: String?
////    private var algorithm: JWSAlgorithm?
////    private var key: String?
////    
////    enum JWSAlgorithm {
////        case RS512
////    }
////    
////    func setPayload(_ payload: String) throws {
////        self.payload = payload
////    }
////    
////    func setAlgorithm(_ algorithm: JWSAlgorithm) throws {
////        self.algorithm = algorithm
////    }
////    
////    func setKey(_ key: String) throws {
////        self.key = key
////    }
////    
////    func getCompactSerialization() throws -> String {
////        guard let payload = payload,
////              let keyData = key else {
////            throw SigningError.signingError
////        }
////        
////        struct JWTPayload: JWTKit.JWTPayload {
////                       let content: String
////                       
////                       func verify(using signer: JWTKit.JWTSigner) throws {}
////                   }
////                   
////                   let _payload = JWTPayload(content: payload)
////                   return try signer.sign(_payload)
////           
////        } catch {
////            print("Signing error: \(error)")
////            throw SigningError.signingError
////        }
////    }
////}
////
//// Add new error cases
//extension SigningError {
//    static let resourceNotFound = SigningError.custom("Resource not found")
//    static let cryptographicError = { (message: String) in SigningError.custom("Cryptographic error: \(message)") }
//    static let custom = { (message: String) in SigningError.invalidInput(message) }
//}
