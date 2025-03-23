struct DTEResponseWrapper: Codable {
   
        let version: Int?
        let ambiente: String?
        let versionApp: Int
        let estado: String
        let codigoGeneracion: String
        let selloRecibido: String
        let fhProcesamiento: String
        let clasificaMsg: String
        let codigoMsg: String
        let descripcionMsg: String
        let observaciones: [String] 
   
}

//
//struct DTE: Codable {
//    let receptor: Receptor
//    let identificacion: Identificacion
//    let documentoRelacionado: String?
//    let emisor: Emisor
//   let otrosDocumentos: String?
//    let ventaTercero: String?
//   let cuerpoDocumento: [CuerpoDocumento]
////       let resumen: Resumen
//    //let extensionField: String?
//    let apendice: String?
//    
////        enum CodingKeys: String, CodingKey {
////            case identificacion
////            case documentoRelacionado
////            case emisor
////            case receptor
////            case otrosDocumentos
////            case ventaTercero
////            case cuerpoDocumento
////            case resumen
////            //case extensionField = "extension"
////            case apendice
////        }
//}
//
//struct Receptor: Codable {
//    let descActividad: String?
//    let tipoDocumento: String??
//    let telefono: String
//    let numDocumento: String??
//    let codActividad: String?
//    let nombre: String
//    let direccion: Direccion
//    let nrc: String?
//    let correo: String
//    let nombreComercial: String?
//    let nit: String? // Added missing field
//}
//
//struct Direccion: Codable {
//    let municipio: String
//    let complemento: String
//    let departamento: String
//}
//
//struct Identificacion: Codable {
//    let version: Int?
//    let ambiente: String
//    let tipoDte: String
//    let numeroControl: String
//    let codigoGeneracion: String
//    let tipoModelo: Int
//    let tipoOperacion: Int
//    let tipoContingencia: String?
//    let motivoContin: String?
//    let fecEmi: String
//    let horEmi: String
//    let tipoMoneda: String
//}
//
//struct Emisor: Codable {
//    let nit: String
//    let nrc: String
//    let nombre: String
//    let codActividad: String
//    let descActividad: String
//    let nombreComercial: String
//    let tipoEstablecimiento: String
//    let direccion: Direccion
//    let telefono: String
//    let correo: String
//    let codEstableMH: String?
//    let codEstable: String?
//    let codPuntoVentaMH: String?
//    let codPuntoVenta: String?
//}
//
//struct CuerpoDocumento: Codable {
//    let psv: Double
//    let noGravado: Double
//    let ivaItem: Double??
//    let numItem: Int
//    let tipoItem: Int
//    let numeroDocumento: String?
//    let cantidad: Int
//    let codigo: String??
//    let codTributo: String?
//    let uniMedida: Int
//    let descripcion: String
//    let precioUni: Double
//    let montoDescu: Double
//    let ventaNoSuj: Double
//    let ventaExenta: Double
//    let ventaGravada: Double
//    let tributos: [String]?
//     
//}
//
//struct Resumen: Codable {
//    let totalNoSuj: Double
//    let totalExenta: Double
//    let totalGravada: Double
//    let subTotalVentas: Double
//    let descuNoSuj: Double
//    let descuExenta: Double
//    let descuGravada: Double
//    let porcentajeDescuento: Double
//    let totalDescu: Double
//    let tributos: [String]??
//    let subTotal: Double
//    let ivaRete1: Double
//    let reteRenta: Double
//    let montoTotalOperacion: Double
//    let totalNoGravado: Double
//    let totalPagar: Double
//    let totalLetras: String
//    let totalIva: Double
//    let saldoFavor: Double
//    let condicionOperacion: Int
//    let pagos: [String]?
//    let numPagoElectronico: String?
//    let ivaPerci1: Double??
//}
//}
//
 

struct DTEErrorResponseWrapper: Codable {
    let version: Int
    let ambiente: String
    let versionApp: Int
    let estado: String
    let codigoGeneracion: String?
    let selloRecibido: String?
    let fhProcesamiento: String
    let clasificaMsg: String
    let codigoMsg: String
    let descripcionMsg: String
    let observaciones: [String]
}
