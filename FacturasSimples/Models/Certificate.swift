import Foundation
import CryptoKit

// Models matching the Java implementation
//struct CertificadoMH: Codable {
//    let nit: String
//    let publicKey: Llave
//    let privateKey: Llave
//    let activo: Bool
//    
//    struct Llave: Codable {
//        let clave: String
//        let encodied: String
//    }
//}

// Cryptographic helper
class Cryptographic {
    static func encrypt(_ text: String) throws -> String {
         
        let inputData = text.data(using: .utf8)!
        let hashed = SHA512.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
} 
