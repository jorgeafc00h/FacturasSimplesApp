import Foundation

struct CatalogDTO: Codable {
    var id: String = ""
    var name: String = ""
    var options: [CatalogOptionDTO] = []
}

struct CatalogOptionDTO: Codable {
    var code: String = ""
    var description: String = ""
    var departamento: String = ""
    
    init(code:String,description: String,departamento:String){
        self.code = code
        self.description = description
        self.departamento = departamento
    }
}

struct CatalogCollection : Codable {
    var catalogs: [CatalogDTO]
}
