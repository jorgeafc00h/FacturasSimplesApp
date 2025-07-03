import Foundation

class Extensions
{
    // extension methods
    static func formatPhoneNumber(telefono: String) -> String {
        guard !telefono.isEmpty else {
            return telefono
        }
        
        if telefono.contains("-") {
            return telefono
        }
        
        let middleIndex = telefono.index(telefono.startIndex, offsetBy: telefono.count / 2)
        let firstPart = telefono[..<middleIndex]
        let secondPart = telefono[middleIndex...]
        
        return "\(firstPart)-\(secondPart)"
    }
    
  
 
//
//    private    func generateRandomHex(length: Int) -> String {
//        let characters = "ABCDEF0123456789"
//        return String((0..<length).map { _ in characters.randomElement()! })
//    }
    
    private static let alphanumericChars = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
       private static let numericChars = Array("0123456789")
    private static let hexChars = Array("ABCDEF0123456789")
       
    static func generateString(baseString: String, pattern: String? = nil) throws -> String? {
           guard !baseString.isEmpty else {
               //throw GenerateStringError.invalidBaseString
                return nil
           }
           
           let alphanumericPart = String((0..<8).map { _ in
               alphanumericChars[Int.random(in: 0..<alphanumericChars.count)]
           })
           
           let numericPart = String((0..<15).map { _ in
               numericChars[Int.random(in: 0..<numericChars.count)]
           })
           
           let result: String
           if pattern != nil {
               result = "\(baseString)-01-\(alphanumericPart)-\(numericPart)"
           } else {
               result = "\(baseString)-\(alphanumericPart)-\(numericPart)"
           }
           
           if let pattern = pattern {
               let regex = try NSRegularExpression(pattern: pattern)
               let range = NSRange(location: 0, length: result.utf16.count)
               
               guard regex.firstMatch(in: result, options: [], range: range) != nil else {
                   //throw GenerateStringError.patternMismatch(result)
                   return nil 
               }
           }
           
           return result
       }
    
   
       
       static func getGenerationCode() throws -> String {
           // Generate parts of the string
           let part1 = try generateRandomHex(length: 8)
           let part2 = try generateRandomHex(length: 4)
           let part3 = try generateRandomHex(length: 4)
           let part4 = try generateRandomHex(length: 4)
           let part5 = try generateRandomHex(length: 12)
           
           // Construct the result
           let result = "\(part1)-\(part2)-\(part3)-\(part4)-\(part5)"
           
           // Validate against regex pattern
           let pattern = "^[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}$"
           guard let regex = try? NSRegularExpression(pattern: pattern),
                 regex.firstMatch(in: result,
                                range: NSRange(location: 0, length: result.utf16.count)) != nil else {
               throw GenerationError.invalidFormat(result)
           }
           
           return result
       }
       
       private static func generateRandomHex(length: Int) throws -> String {
           return String((0..<length).map { _ in
               hexChars[Int.random(in: 0..<hexChars.count)]
           })
       }
    
    static func formatNationalId(_ nationalId: String) throws -> String {
        // Ensure the input is numeric and has exactly 9 digits
        guard !nationalId.isEmpty, nationalId.count == 9, let _ = Int(nationalId) else {
            //throw NSError(domain: "El DUI debe contener 9 digitos", code: 0, userInfo: nil)
            throw DTEValidationErrors.invalidDocumentLength
        }
        
        // Format the string to 00000000-0
        let startIndex = nationalId.startIndex
        let endIndex = nationalId.index(startIndex, offsetBy: 8)
        let formattedId = "\(nationalId[startIndex..<endIndex])-\(nationalId[endIndex])"
        
        return formattedId
    }
    
     
    static func generateHourString(date: Date) throws -> String {
        // Format the Date object to match the regex pattern with explicit locale settings
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX") // Use POSIX locale to ensure consistent formatting
        formatter.timeZone = TimeZone.current // Use current timezone
        let hourString = formatter.string(from: date)

        // Validate the result against the regex
        let pattern = "^(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$"
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: hourString.utf16.count)
        
        // Check if the hourString matches the regex pattern
        if regex.firstMatch(in: hourString, options: [], range: range) == nil {
            // Generate a valid hour string as fallback
            let components = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
            let hour = max(0, min(23, components.hour ?? 0))
            let minute = max(0, min(59, components.minute ?? 0))
            let second = max(0, min(59, components.second ?? 0))
            
            let validHourString = String(format: "%02d:%02d:%02d", hour, minute, second)
            
            // Validate the generated string
            let validRange = NSRange(location: 0, length: validHourString.utf16.count)
            if regex.firstMatch(in: validHourString, options: [], range: validRange) != nil {
                return validHourString
            }
            
            // If still invalid, throw error
            throw DTEValidationErrors.stringGeneratedDoesntMatchExpectedPattern
        }

        return hourString
    }
    
    static func numberToWords(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        formatter.locale = Locale(identifier: "es_SV")
        
        let integerPart = Int(number)
        let decimalPart = Int((number * 100).truncatingRemainder(dividingBy: 100))
        
        var result = formatter.string(from: NSNumber(value: integerPart))?.uppercased() ?? ""
        result += " DÓLARES"
        
        if decimalPart > 0 {
            result += " Y " + (formatter.string(from: NSNumber(value: decimalPart))?.uppercased() ?? "")
            result += " CENTAVOS"
        }
        //return result.uppercased()
        return result.uppercased()
    }
    
    public static func documentTypeFromInvoiceType(_ invoicetype: InvoiceType) -> String {
        switch invoicetype {
        case .Factura: return "01"
        case .CCF: return  "03"
        case .NotaCredito: return "05"
        case .SujetoExcluido: return "14"
        case .NotaDebito: return "06"
        }
    }
    

    public static func generateDateString(date:Date = Date())-> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }
    public static func generateTimeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        return dateFormatter.string(from: Date())
    }
    
    public static func generateControlNumberAndCode(_ invoice: Invoice){
        //check if has valid controlnumber in case of edit
        if invoice.controlNumber != nil ,
           invoice.controlNumber != "" {
            
            let hasInvalidControlNumberPrefix =
            (invoice.invoiceType == .Factura && !invoice.controlNumber!.hasPrefix("DTE-01")) ||
            (invoice.invoiceType == .CCF && !invoice.controlNumber!.hasPrefix("DTE-03")) ||
            (invoice.invoiceType == .NotaCredito && !invoice.controlNumber!.hasPrefix("DTE-05")) ||
            (invoice.invoiceType == .SujetoExcluido && !invoice.controlNumber!.hasPrefix("DTE-14")) ||
            (invoice.invoiceType == .NotaDebito && !invoice.controlNumber!.hasPrefix("DTE-06"))
            
            
            
            if (hasInvalidControlNumberPrefix){
                invoice.controlNumber = nil
                invoice.documentType  = Extensions.documentTypeFromInvoiceType(invoice.invoiceType)
            }
        }
        
        
        if invoice.controlNumber == nil || invoice.controlNumber == "" {
            invoice.controlNumber =  invoice.isCCF ?
            try? Extensions.generateString(baseString: "DTE-03",pattern: nil) :
            invoice.invoiceType == .NotaCredito ?
            try? Extensions.generateString(baseString: "DTE-05",pattern: nil) :
            invoice.invoiceType == .SujetoExcluido ?
            try? Extensions.generateString(baseString: "DTE-14",pattern: nil) :
            invoice.invoiceType == .NotaDebito ?
            try? Extensions.generateString(baseString: "DTE-06",pattern: nil) :
            try? Extensions.generateString(baseString: "DTE",pattern: "^DTE-01-[A-Z0-9]{8}-[0-9]{15}$")
        }
        
        if invoice.generationCode == nil || invoice.generationCode == "" {
            invoice.generationCode = try? Extensions.getGenerationCode()
        }
    }
}

// Extension for Decimal rounding
extension Decimal {
//    func rounded(scale: Int = 2) -> Decimal {
//        var result = self
//        var rounded = Decimal()
//        NSDecimalRound(&rounded, &result, scale, .plain)
//        return rounded
//    }
    func rounded(to scale: Int = 2, mode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
           var result = self
           var rounded = Decimal()
           NSDecimalRound(&rounded, &result, scale, mode)
           return rounded
       }
    func toDouble(roundingMode: NSDecimalNumber.RoundingMode = .plain) -> Double {
            var result = self
            var rounded = Decimal()
            NSDecimalRound(&rounded, &result, 2, roundingMode)
            return NSDecimalNumber(decimal: rounded).doubleValue
        }
        
        // Convenience method for most common use case
        var asDoubleRounded: Double {
            toDouble(roundingMode: .plain)
        }
}
extension DateFormatter {
    static let iso8601DateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
