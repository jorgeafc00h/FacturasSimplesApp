import Foundation

enum ApiErrors : LocalizedError {
    case invalidResponse
    case invalidData
    case invalidURL
    case custom(message: String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return NSLocalizedString("La respuesta es invalida verifique los parametros", comment: "")
        case .invalidURL:
            return NSLocalizedString("URL invalida", comment: "")
        case .invalidData:
            return NSLocalizedString("no coincide con el formato esperado.", comment: "")
        
        case .custom(let message):
        
        
            return message
        }
    }
}


enum DTEValidationErrors: LocalizedError {
    case fileNotFound
    case invalidDocumentLength
    case stringGeneratedDoesntMatchExpectedPattern
    case stringPrefixCantBeEmpty
    case custom(message: String)

    var errorDescription: String? {
        switch self {
        case .invalidDocumentLength:
            return NSLocalizedString("El numero de documento debe contener 9 digitos.", comment: "")
        case .fileNotFound:
            return NSLocalizedString("The data is invalid.", comment: "")
        case .stringGeneratedDoesntMatchExpectedPattern:
            return NSLocalizedString("La cadena generada no coincide con el formato esperado.", comment: "")
        case .stringPrefixCantBeEmpty:
            return NSLocalizedString("El prefijo no puede ser vacio.",comment: "")
        case .custom(let message):
        
        
            return message
        }
    }
}

enum GenerateStringError: Error {
    case invalidBaseString
    case patternMismatch(String)
}

enum GenerationError: Error {
    case invalidFormat(String)
}


//enum DTEValidationErrors: LocalizedError {
//    case invalidInput(String)
//    case certificateError
//    case jsonConversionError
//    case signingError
//    
//    var errorDescription: String? {
//        switch self {
//        case .invalidInput(let message):
//            return "Invalid input: \(message)"
//        case .certificateError:
//            return "Fallo al recuperar Certificado digital de hacienda, por favor actualize el certificado"
//        case .jsonConversionError:
//            return "Failed to convert JSON"
//        case .signingError:
//            return "Failed to sign document"
//        }
//    }
//}
