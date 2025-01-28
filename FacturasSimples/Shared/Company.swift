import Foundation
import SwiftData

@Model class Company {
    
    @Attribute(.unique)
    var id: String = UUID().uuidString
    var nit: String
    var nrc: String
    var nombre: String
    var codActividad: String
    var descActividad: String
    var nombreComercial: String
    var tipoEstablecimiento: String
    
    var telefono: String
    var correo: String
    var codEstableMH: String
    var codEstable: String
    var codPuntoVentaMH: String
    var codPuntoVenta: String
    
    // Dirección
    var departamento: String
    var departamentoCode: String
    var municipio: String
    var municipioCode: String
    var complemento: String
    
    var invoiceLogo: String
    var logoWidht : Double = 100
    var logoHeight: Double = 100
    var certificatePath : String = ""
    var certificatePassword: String = ""
    
    var credentials: String = ""
    
    var actividadEconomicaLabel: String {
        descActividad == "" ? "Seleccione una actividad económica" : descActividad
    }
   
    init(
        nit: String,
        nrc: String,
        nombre: String,
        descActividad: String = "",
        nombreComercial: String = "",
        tipoEstablecimiento: String = "",
        telefono: String = "",
        correo: String = "",
        codEstableMH: String = "",
        codEstable: String = "",
        codPuntoVentaMH: String = "",
        codPuntoVenta: String = "",
        departamento: String = "",
        municipio: String = "",
        complemento: String = "",
        invoiceLogo: String = "",
        departamentoCode: String = "",
        municipioCode: String = "",
        codActividad: String = "",
        certificatePath: String = "",
        certificatePassword: String = "",
        credentials: String = ""
    ) {
        self.nit = nit
        self.nrc = nrc
        self.nombre = nombre
        self.codActividad = codActividad
        self.descActividad = descActividad
        self.nombreComercial = nombreComercial
        self.tipoEstablecimiento = tipoEstablecimiento
        self.telefono = telefono
        self.correo = correo
        self.codEstableMH = codEstableMH
        self.codEstable = codEstable
        self.codPuntoVentaMH = codPuntoVentaMH
        self.codPuntoVenta = codPuntoVenta
        self.departamento = departamento
        self.municipio = municipio
        self.complemento = complemento
        self.departamentoCode = departamentoCode
        self.municipioCode = municipioCode
        self.invoiceLogo = invoiceLogo
        self.certificatePath = certificatePath  
        self.certificatePassword = certificatePassword
        self.credentials = credentials
    }
}



extension Company{
    
    
    
    static var prewiewCompanies: [Company] {
        [
            Company(nit: "1234567890",nrc:"2342342", nombre: "Empresa 1",nombreComercial: "Nombre comercial"),
            Company(nit: "1234567891",nrc:"34563456", nombre: "Empresa 2",nombreComercial: "Nombre comercial"),
            Company(nit: "1234567892",nrc:"345634562", nombre: "Empresa 3",nombreComercial: "Nombre comercial"),
            Company(nit: "1234567893",nrc:"345634563", nombre: "Empresa 4",nombreComercial: "Nombre comercial"),
            Company(nit: "1234567894",nrc:"345634564", nombre: "Empresa 5",nombreComercial: "Nombre comercial")
        ]
    }
}

