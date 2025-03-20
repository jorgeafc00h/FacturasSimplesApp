import Foundation

struct DTE_Base: Codable {
    var identificacion: Identificacion
    var documentoRelacionado: [DocumentoRelacionado]??
    var emisor: Emisor
    var receptor: Receptor
    var otrosDocumentos: [OtroDocumento]??
    var ventaTercero: VentaTercero??
    var cuerpoDocumento: [CuerpoDocumento]??
    var resumen: Resumen
    var extensionField: ExtensionObject??
    var apendice: [Apendice]??

    init(identificacion: Identificacion, documentoRelacionado: [DocumentoRelacionado]? = nil, emisor: Emisor, receptor: Receptor, otrosDocumentos: [OtroDocumento]? = nil, ventaTercero: VentaTercero? = nil, cuerpoDocumento: [CuerpoDocumento]? = nil, resumen: Resumen, extensionField: ExtensionObject? = nil, apendice: [Apendice]? = nil) {
        self.identificacion = identificacion
        self.documentoRelacionado = documentoRelacionado
        self.emisor = emisor
        self.receptor = receptor
        self.otrosDocumentos = otrosDocumentos
        self.ventaTercero = ventaTercero
        self.cuerpoDocumento = cuerpoDocumento
        self.resumen = resumen
        self.extensionField = extensionField
        self.apendice = apendice
    }

    enum CodingKeys: String, CodingKey {
        case identificacion
        case documentoRelacionado
        case emisor
        case receptor
        case otrosDocumentos
        case ventaTercero
        case cuerpoDocumento
        case resumen
        case extensionField = "extension"
        case apendice
    }
    
    // Custom encoder to conditionally include otrosDocumentos
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Always encode these fields
        try container.encode(identificacion, forKey: .identificacion)
        try container.encode(emisor, forKey: .emisor)
        try container.encode(receptor, forKey: .receptor)
        try container.encode(resumen, forKey: .resumen)
        
        // Conditionally encode optional fields
        if let documentoRelacionado = documentoRelacionado {
            try container.encode(documentoRelacionado, forKey: .documentoRelacionado)
        }
        
        // Only include otrosDocumentos if tipoDte is not "05" (credit note)
        if identificacion.tipoDte != "05", let otrosDocumentos = otrosDocumentos {
            try container.encode(otrosDocumentos, forKey: .otrosDocumentos)
        }
        
        if let ventaTercero = ventaTercero {
            try container.encode(ventaTercero, forKey: .ventaTercero)
        }
        
        if let cuerpoDocumento = cuerpoDocumento {
            try container.encode(cuerpoDocumento, forKey: .cuerpoDocumento)
        }
        
        if let extensionField = extensionField {
            try container.encode(extensionField, forKey: .extensionField)
        }
        
        if let apendice = apendice {
            try container.encode(apendice, forKey: .apendice)
        }
    }
}
 
struct Receptor: Codable {
    
    var nrc: String?? = nil
    var nombre: String
    var nombreComercial: String?
    var codActividad: String??
    var descActividad: String??
    var direccion: Direccion??
    var telefono: String??
    var correo: String??
    var tipoDocumento: String??
    var numDocumento: String??
    var nit: String?
//    var idExtranjero: String?
//    var nombreExtranjero: String?
//    var pais: String?
//    var departamento: String?
//    var municipio: String?
//    var complemento: String?
}

struct ReceptorCCF: Codable {
    var nrc: String
    var nombre: String
    var correo: String
    var codActividad: String??
    var descActividad: String??
    var nombreComercial: String??
    var direccion: Direccion
    var telefono: String
    var nit: String?
}
 
struct ExtensionObject : Codable {
    
}

struct Identificacion: Codable {
    var version: Int
    var ambiente: String
    var tipoDte: String
    var numeroControl: String?
    var codigoGeneracion: String?
    var tipoModelo: Int
    var tipoOperacion: Int
    var tipoContingencia: Int??
    var motivoContin: String??
    var fecEmi: Date
    var horEmi: String
    var tipoMoneda: String
}

 
struct DocumentoRelacionado: Codable {
    var tipoDocumento: String
    var tipoGeneracion: Int
    var numeroDocumento: String
    var fechaEmision: Date
}

struct Emisor: Codable {
    var nit: String
    var nrc: String
    var nombre: String
    var codActividad: String
    var descActividad: String?? = nil
    var nombreComercial: String?? = nil
    var tipoEstablecimiento: String
    var direccion: Direccion
    var telefono: String
    var correo: String
    var codEstableMH: String?? = nil
    var codEstable: String?? = nil
    var codPuntoVentaMH: String?? = nil
    var codPuntoVenta: String?? = nil
    
}
 
struct Direccion: Codable {
    var departamento: String?
    var municipio: String?
    var complemento: String?
}


struct OtroDocumento: Codable {
    var codDocAsociado: Int
    var descDocumento: String
    var detalleDocumento: String
    var medico: Medico?
}

 

struct Medico: Codable {
    var nombre: String
    var nit: String
    var docIdentificacion: String
    var tipoServicio: Double
}


struct VentaTercero: Codable {
    var nit: String
    var nombre: String
}
 

struct CuerpoDocumento: Codable {
    var ivaItem: Decimal?? = nil
    var cantidad: Decimal
    var numItem: Int
    var codigo: String??
    var codTributo: String?? = nil
    var descripcion: String
    var precioUni: Decimal
    var ventaGravada: Decimal
    var psv: Decimal?? = nil
    var noGravado: Decimal
    var montoDescu: Decimal
    var ventaNoSuj: Decimal
    var uniMedida: Int
    var tributos: [String]?? = nil
    var ventaExenta: Decimal
    var tipoItem: Int
    var numeroDocumento: String?? = nil
    
    
}
 
struct Resumen: Codable {
    var totalNoSuj: Decimal
    var totalExenta: Decimal
    var totalGravada: Decimal
    var subTotalVentas: Decimal
    var descuNoSuj: Decimal
    var descuExenta: Decimal
    var descuGravada: Decimal
    var porcentajeDescuento: Decimal?? = nil
    var totalDescu: Double
    var tributos: [Tributo]?? = nil
    var subTotal: Decimal
    var ivaRete1: Decimal
    var reteRenta: Decimal
    var montoTotalOperacion: Decimal
    var totalNoGravado: Double?? = nil
    var totalPagar: Decimal?? = nil
    var totalLetras: String
    var totalIva: Decimal??
    var saldoFavor: Decimal?? = nil
    var condicionOperacion: Int
    var pagos: [Pago]?? = nil
    var numPagoElectronico: PagoElectronico?? = nil
    var ivaPerci1 : Decimal? = nil
}

struct Tributo: Codable {
    var codigo: String
    var descripcion: String
    var valor: Decimal
}

  
struct Pago: Codable {
    var codigo: String
    var montoPago: Double
    var referencia: String
    var plazo: String
    var periodo: Double
}

import Foundation

struct Apendice: Codable {
    var campo: String
    var etiqueta: String
    var valor: String
}

struct PagoElectronico : Codable{
    
}


