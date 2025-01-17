import Foundation
import SwiftUI
import SwiftData

class CatalogServiceClient
{
    
    
    func getCatalogs()async throws -> [Catalog]
    {
        
        let endpoint = Constants.InvoiceServiceUrl+"/catalog"
        
        guard let url = URL(string: endpoint) else {
            throw ApiErrors.invalidURL
        }
        
        let (data ,response) = try await URLSession.shared.data(from: url)
        
        guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
            throw ApiErrors.invalidResponse
        }
        
        do{
            
            let catalogDto = try JSONDecoder().decode(CatalogCollection.self, from: data)
            
            let catalogs =  catalogDto.catalogs.map{
                
                let c = Catalog(id:$0.id,name: $0.name)
                
                c.options = $0.options.map{ CatalogOption(code: $0.code,description: $0.description,departamento: $0.departamento,catalog: c)}
                
                return c
            }
            
            return catalogs
        }
        catch{
            throw ApiErrors.invalidData
        }
    }
    
    
}

