import Foundation
import SwiftUI
import SwiftData

@Model
class Catalog : Identifiable
{
    @Attribute(.unique)
    var id: String = ""
    var name: String = ""
    
    @Relationship(deleteRule: .cascade,inverse: \CatalogOption.catalog)
    var options: [CatalogOption] = []
    
    init(id: String, name: String,
        options: [CatalogOption] = []) {
        self.id = id
        self.name = name
        self.options = options
    }
}

@Model
class CatalogOption : Identifiable{


    var code: String = ""
    var details: String = ""
    var departamento: String = ""


    var catalog : Catalog

    init(code: String, description: String, departamento: String, catalog: Catalog) {
        self.code = code
        self.details = description
        self.departamento = departamento
        self.catalog = catalog
    }
}
