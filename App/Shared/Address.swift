

class Address: Codable {
    
    var complemento: String=""
    var departamento: String=""
    var municipio: String=""
    
    var fullAddress: String {
        let address = [complemento, departamento, municipio].joined(separator: ", ")
        return address
    }
    
    init(complemento: String = "", departamento: String = "", municipio: String = "") {
        self.complemento = complemento
        self.departamento = departamento
        self.municipio = municipio
    }
    
    
}
