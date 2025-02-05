import Foundation

struct Constants {
    
    static let InvoiceServiceUrl = "https://k-invoices-api-dev.azurewebsites.net/api"
    //static let InvoiceServiceUrl = "https://localhost:7110/api"
    
    static let includedTax : Decimal = 1.13
    static let selectedCompany = "selectedCompany"
    
    static let EnvironmentCode = "00"
    
    static let Apikey = "eyJhbGciOiJFUzI1NiIsImtpZCI6IlVSS0VZSUQwMDEifQ"
    static let ApiKeyHeaderName = "apiKey"
    
    static let CertificateKey  = "key";

    static let InvoiceNumber = "reference";
    static let ApiKeyName = "apiKey";

    static let MH_USER = "MH_USER";

    static let MH_KEY = "MH_KEY";
    
    static let HttpDefaultTimeOut : Int = 60 // seconds
}
