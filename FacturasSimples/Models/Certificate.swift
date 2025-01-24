import Foundation
import CryptoKit

// Models matching the Java implementation
struct CertificadoMH: Codable {
    let nit: String
    let publicKey: Llave
    let privateKey: Llave
    let activo: Bool
    
    struct Llave: Codable {
        let clave: String
        let encodied: String
    }
}

// Cryptographic helper
class Cryptographic {
    static func encrypt(_ text: String, algorithm: String) throws -> String {
        guard algorithm == "SHA512" else {
            throw SigningError.cryptographicError("Unsupported algorithm")
        }
        
        let inputData = text.data(using: .utf8)!
        let hashed = SHA512.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}

//struct CertificadoMH: Codable {
//    var id: String
//    var nit: String
//    var publicKey: Llave
//    var privateKey: Llave
//    var activo: Bool
//    var verificado: Bool?
//    var fechaVerificacion: Date?
//    var certificado: Certificado
//
//    enum CodingKeys: String, CodingKey {
//        case id = "_id"
//        case nit
//        case publicKey
//        case privateKey
//        case activo
//        case verificado
//        case fechaVerificacion
//        case certificado
//    }
//}
//
//struct Llave: Codable {
//    var keyType: String
//    var algorithm: String
//    var encodied: String
//    var format: String
//    var clave: String
//}
//
//struct Certificado: Codable {
//    var basicEstructure: BasicEstructure
//    var extensions: ExtensionsCertificate
//}
//
//struct BasicEstructure: Codable {
//    var version: Int
//    var serial: String
//    var signatureAlgorithm: SignatureAlgorithm
//    var issuer: Issuer
//    var validity: Validity
//    var subject: Subject
//    var subjectPublicKeyInfo: SubjectPublicKeyInfo
//}
//
//struct SignatureAlgorithm: Codable {
//    var algorithm: String
//    var parameters: String?
//}
//
//struct Issuer: Codable {
//    var countryName: String
//    var localilyName: String
//    var organizationalUnit: String
//    var organizationalName: String
//    var commonName: String
//    var organizationIdentifier: String
//}
//
//struct Validity: Codable {
//    var notBefore: Double
//    var notAfter: Double
//}
//
//struct Subject: Codable {
//    var countryName: String
//    var organizationName: String
//    var organizationUnitName: String
//    var organizationIdentifier: String
//    var surname: String
//    var givenName: String
//    var commonName: String
//    var description: String
//}
//
//struct SubjectPublicKeyInfo: Codable {
//    var algorithmIdenitifier: AlgorithmIdentifier
//    var subjectPublicKey: String
//}
//
//struct AlgorithmIdentifier: Codable {
//    var algorithm: String
//    var parameters: String?
//}
//
//struct ExtensionsCertificate: Codable {
//    var authorityKeyIdentifier: KeyIdentifier
//    var subjectKeyIdentifier: KeyIdentifier
//    var keyUsage: KeyUsage
//    var certificatePolicies: CertificatePolicies
//    var subjectAlternativeNames: SubjectAlternativeNames
//    var extendedKeyUsage: ExtendedKeyUsage
//    var crlDistributionPoint: CRLDistributionPoint
//    var authorityInfoAccess: AuthorityInfoAccess
//    var qualifiedCertificateStatements: QualifiedCertificateStatements
//    var basicConstraints: BasicConstraints
//}
//
//struct KeyIdentifier: Codable {
//    var keyIdentifier: String
//}
//
//struct KeyUsage: Codable {
//    var digitalSignature: Int
//    var contentCommintment: Int
//    var dataEncipherment: Int
//    var keyAgreement: Int
//    var keyCertificateSignature: Int
//    var crlSignature: Int
//    var encipherOnly: Int
//    var decipherOnly: Int
//}
//
//struct CertificatePolicies: Codable {
//    var policyInformations: String?
//}
//
//struct SubjectAlternativeNames: Codable {
//    var rfc822Name: String
//}
//
//struct ExtendedKeyUsage: Codable {
//    var clientAuth: String?
//    var emailProtection: String?
//}
//
//struct CRLDistributionPoint: Codable {
//    var distributionPoint: [String]
//}
//
//struct AuthorityInfoAccess: Codable {
//    var accessDescription: [AccessDescription]
//}
//
//struct AccessDescription: Codable {
//    var accessMethod: String?
//    var accessLocation: AccessLocation
//}
//
//struct AccessLocation: Codable {
//    var accessLocation: String
//}
//
//struct QualifiedCertificateStatements: Codable {
//    var qcCompliance: String?
//    var qcEuRetentionPeriod: Int
//    var qcPDS: QCPDS
//    var qcType: String
//}
//
//struct QCPDS: Codable {
//    var pdsLocation: String?
//    var url: String
//    var language: String
//}
//
//struct BasicConstraints: Codable {
//    var ca: Bool
//}
