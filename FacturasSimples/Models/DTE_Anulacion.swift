import Foundation

// Root Model
struct DTE_InvalidationRequest: Codable {
    let identificacion: IdentificationInvalidate
    let emisor: EmisorInvalidate
    let documento: Documento
    let motivo: Motivo
    
   
}


// Identificacion Model
struct IdentificationInvalidate: Codable {
    let version: Int
    let ambiente: String
    let codigoGeneracion: String
    let fecAnula: String // Format: yyyy-MM-dd
    let horAnula: String // Format: HH:mm:ss
}

// Emisor Model
struct EmisorInvalidate: Codable {
    let nit: String
    let nombre: String
    let tipoEstablecimiento: String
    let nomEstablecimiento: String?
    var codEstableMH: String?? = nil
    var codEstable: String?? = nil
    var codPuntoVentaMH: String?? = nil
    var codPuntoVenta: String?? = nil
    let telefono: String?
    let correo: String
}

// Documento Model
struct Documento: Codable {
    let tipoDte: String
    let codigoGeneracion: String
    let selloRecibido: String
    let numeroControl: String
    let fecEmi: String // Format: yyyy-MM-dd
    let montoIva: Decimal?
    let codigoGeneracionR: String?
    let tipoDocumento: String
    let numDocumento: String
    let nombre: String
    let telefono: String?
    let correo: String
}

// Motivo Model
struct Motivo: Codable {
    let tipoAnulacion: Int
    let motivoAnulacion: String?
    let nombreResponsable: String
    let tipDocResponsable: String
    let numDocResponsable: String
    let nombreSolicita: String
    let tipDocSolicita: String
    let numDocSolicita: String
}



