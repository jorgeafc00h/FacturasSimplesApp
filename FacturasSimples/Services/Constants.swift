import Foundation

struct Constants {
    
    static let InvoiceServiceUrl =
    IS_PRODUCTION ?
    "https://k-invoices-api.azurewebsites.net/api" :
    "https://k-invoices-api-dev.azurewebsites.net/api"
    //static let InvoiceServiceUrl = "https://localhost:7110/api"
    
    static let includedTax : Decimal = 1.13
    
    static let roundingScale = 2
    static let selectedCompany = "selectedCompany"
    
    static let EnvironmentCode = IS_PRODUCTION ? "01" : "00"
    
    static let Apikey = "eyJhbGciOiJFUzI1NiIsImtpZCI6IlVSS0VZSUQwMDEifQ"
    static let ApiKeyHeaderName = "apiKey"
    
    static let CertificateKey  = "key";
    
    static let InvoiceNumber = "reference";
    static let ApiKeyName = "apiKey";
    
    static let MH_USER = "MH_USER";
    
    static let MH_KEY = "MH_KEY";
    
    static let HttpDefaultTimeOut : Int = 90 // seconds
    
    //static let qrUrlBase =
    static let qrUrlBase  =
    IS_PRODUCTION ?
    "https://admin.factura.gob.sv/consultaPublica/":
    "https://test7.mh.gob.sv/ssc/consulta/fe/"
    
    static var IS_PRODUCTION : Bool = false
}
