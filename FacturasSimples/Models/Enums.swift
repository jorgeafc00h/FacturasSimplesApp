import Foundation
//import UIKit

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
            return NSLocalizedString("El número de documento debe contener 9 dígitos.", comment: "")
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

//enum DeviceType {
//    case iPhone, iPad
//    
//    static var current: DeviceType {
//        UIDevice.current.userInterfaceIdiom == .pad ? .iPad : .iPhone
//    }
//}

enum EnvironmentType{
    case Pruebas
    case Produccion
    
    func stringValue() -> String {
        switch(self) {
        case .Produccion:
            return "Produccion"
        case .Pruebas:
            return "Pruebas"
        }
        
    }
}

enum TipoDocumento: Int, CaseIterable {
    case factura = 1
    case comprobanteCreditoFiscal = 3
    case notaRemision = 4
    case notaCredito = 5
    case notaDebito = 6
    case comprobanteRetencion = 7
    case comprobanteLiquidacion = 8
    case documentoContableLiquidacion = 9
    case facturaExportacion = 11
    case facturaSujetoExcluido = 14
    case comprobanteDonacion = 15

    var description: String {
        switch self {
        case .factura:
            return "Factura"
        case .comprobanteCreditoFiscal:
            return "Comprobante de crédito fiscal"
        case .notaRemision:
            return "Nota de remisión"
        case .notaCredito:
            return "Nota de crédito"
        case .notaDebito:
            return "Nota de débito"
        case .comprobanteRetencion:
            return "Comprobante de retención"
        case .comprobanteLiquidacion:
            return "Comprobante de liquidación"
        case .documentoContableLiquidacion:
            return "Documento contable de liquidación"
        case .facturaExportacion:
            return "Facturas de exportación"
        case .facturaSujetoExcluido:
            return "Factura de sujeto excluido"
        case .comprobanteDonacion:
            return "Comprobante de donación"
        }
    }
    
    
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
