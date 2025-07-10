// Swift Codable classes for ContingenciaRequest

import Foundation

struct ContingenciaRequest: Codable {
    let identificacion: ContingenciaIdentificacion
    let emisor: ContingenciaEmisor
    let detalleDTE: [ContingenciaDetalleDTE]
    let motivo: ContingenciaMotivo
}

struct ContingenciaIdentificacion: Codable {
    let version: Int
    let ambiente: String
    let codigoGeneracion: String
    let fTransmision: String
    let hTransmision: String
}

struct ContingenciaEmisor: Codable {
    let nit: String
    let nombre: String
    let nombreResponsable: String
    let tipoDocResponsable: String
    let numeroDocResponsable: String
    let tipoEstablecimiento: String
    let codEstableMH: String?
    let codPuntoVenta: String?
    let telefono: String
    let correo: String
}

struct ContingenciaDetalleDTE: Codable {
    let noItem: Int
    let codigoGeneracion: String
    let tipoDoc: String
}

struct ContingenciaMotivo: Codable {
    let fInicio: String
    let fFin: String
    let hInicio: String
    let hFin: String
    let tipoContingencia: Int
    let motivoContingencia: String?
}
