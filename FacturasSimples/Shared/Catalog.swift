import Foundation
import SwiftUI
import SwiftData

@Model
class Catalog : Identifiable, @unchecked Sendable
{
    // Remove unique constraint for CloudKit compatibility
    var id: String = ""
    var name: String = ""
    
    // Make relationship optional for CloudKit
    @Relationship(deleteRule: .cascade,inverse: \CatalogOption.catalog)
    var options: [CatalogOption]?
    
    init(id: String, name: String,
        options: [CatalogOption] = []) {
        self.id = id
        self.name = name
        self.options = options
    }
}

@Model
class CatalogOption : Identifiable, @unchecked Sendable{

    var code: String = ""
    var details: String = ""
    var departamento: String = ""

    var catalog : Catalog?

    init(code: String, description: String, departamento: String, catalog: Catalog? = nil) {
        self.code = code
        self.details = description
        self.departamento = departamento
        self.catalog = catalog
    }
}



extension CatalogOption {
   
    
    static var previewCatalogOptions: [CatalogOption] {
        [
            CatalogOption(code: "02",
                          description:"Servicio de beneficiado de plantas textiles (incluye el beneficiado cuando este es realizado en la misma explotación agropecuaria)",
                          departamento: "",
                          catalog: Catalog(id:"CAT-013",name:"",options:[])),
            CatalogOption(code: "01",
                          description:"Actividades para mejorar la reproducción, el crecimiento y el rendimiento de los animales y sus productos",
                          departamento: "",
                          catalog: Catalog(id:"CAT-012",name:"",options:[])),
            
            
            CatalogOption(code:"45209",
                          description: "Reparaciones de vehículos n.c.p.",
                          departamento:"" ,
                          catalog: Catalog(id:"CAT-019",name:"Código de Actividad Económica Valores",options:[])),
            
            CatalogOption(code:"310149",
                          description: "Actividades para mejorar la reproducción, el crecimiento y el rendimiento de los animales y sus productos",
                          departamento:"" ,
                          catalog: Catalog(id:"CAT-019",name:"Código de Actividad Económica Valores",options:[])),
            
            CatalogOption(code:"01",
                          description: "Ahuachapán",
                          departamento:"" ,
                          catalog: Catalog(id:"CAT-012",name: "Departamento",options:[])),
            CatalogOption(code:"02",
                          description: "Santa Ana",
                          departamento:"" ,
                          catalog: Catalog(id:"CAT-012",name: "Departamento",options:[])),
            
            CatalogOption(code:"01",
                          description: "AHUACHAPÁN",
                          departamento:"01" ,
                          catalog: Catalog(id:"CAT-013",name: "Municipio",options:[])),
            CatalogOption(code:"01",
                          description: "APANECA",
                          departamento:"01" ,
                          catalog: Catalog(id:"CAT-013",name: "Municipio",options:[])),
            CatalogOption(code:"01",
                          description: "ATIQUIZAYA",
                          departamento:"01" ,
                          catalog: Catalog(id:"CAT-013",name: "Municipio",options:[])),
            
        ]
    }
}
