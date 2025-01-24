import Foundation
struct DocumentSigningRequest: Codable {
    var nit: String
    var passwordPri: String
    var dteJson: String
}

struct SigningResponse: Codable {
    var success: Bool
    var signature: String?
    var error: String?
}


 
// Helper enums and functions
enum SigningError: LocalizedError {
    case invalidInput(String)
    case certificateError
    case jsonConversionError
    case signingError
    
    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .certificateError:
            return "Fallo al recuperar Certificado digital de hacienda, por favor actualize el certificado"
        case .jsonConversionError:
            return "Failed to convert JSON"
        case .signingError:
            return "Failed to sign document"
        }
    }
}
 

// Mock certificate struct
struct Certificate {
    let nit: String
    let privateKey: Data
}
