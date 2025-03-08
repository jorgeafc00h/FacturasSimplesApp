import Foundation

struct Constants {
    
    static let InvoiceServiceUrl_PRD = "https://k-invoices-api-dev.azurewebsites.net/api"
    
    static let InvoiceServiceUrl = "https://k-invoices-api-prod.azurewebsites.net/api"
    
    static let includedTax : Decimal = 1.13
    
    static let roundingScale = 2
    static let selectedCompany = "selectedCompany"
    
    static let EnvironmentCode =  "00"
    
    static let EnvironmentCode_PRD = "01"
    
    static let Apikey = "eyJhbGciOiJFUzI1NiIsImtpZCI6IlVSS0VZSUQwMDEifQ"
    static let ApiKeyHeaderName = "apiKey"
    
    static let CertificateKey  = "key";
    
    static let InvoiceNumber = "reference";
    static let ApiKeyName = "apiKey";
    
    static let MH_USER = "MH_USER";
    
    static let MH_KEY = "MH_KEY";
    
    static let HttpDefaultTimeOut : Int = 90 // seconds
    
    //static let qrUrlBase =
    static let qrUrlBase_PRD = "https://admin.factura.gob.sv/consultaPublica/"
    
    static let qrUrlBase = "https://test7.mh.gob.sv/ssc/consulta/fe/"
    
    
}
