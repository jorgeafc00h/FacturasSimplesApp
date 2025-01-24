import Foundation

class Extensions
{
    // extension methods
    func formatPhoneNumber(telefono: String) -> String {
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
    
    func generateString(baseString: String) throws -> String {
        guard !baseString.isEmpty else {
            //fatalError("Base string cannot be null or empty")
            //throw NSError(domain: "El prefijo no puede ser vacio", code: 0, userInfo: nil)
            throw DTEValidationErrors.stringPrefixCantBeEmpty
        }
        
        // Generate 8 random alphanumeric characters
        let first = generateRandomAlphanumeric(length: 8)
        
        // Generate 15 random digits
        let numericPart = try generateRandomDigits(length: 15)
        
        // Construct the final string
        let result = "\(baseString)-\(first)-\(numericPart)"
        
        return result
    }
    
    func generateString(baseString: String, pattern: String) throws -> String {
        guard !baseString.isEmpty else {
            //fatalError("Base string cannot be null or empty")
            throw DTEValidationErrors.stringPrefixCantBeEmpty
        }
        
        // Generate 8 random alphanumeric characters
        let alphanumericPart = generateRandomAlphanumeric(length: 8)
        
        // Generate 15 random digits
        let numericPart = try generateRandomDigits(length: 15)
        
        // Construct the final string
        let result = "\(baseString)-01-\(alphanumericPart)-\(numericPart)"
        
        // Validate the result against the regex
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: result.utf16.count)
        if regex.firstMatch(in: result, options: [], range: range) == nil {
            throw DTEValidationErrors.stringGeneratedDoesntMatchExpectedPattern
        }
        
        return result
    }
    
    
    private   func generateRandomAlphanumeric(length: Int) -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    
    private   func generateRandomDigits(length: Int) throws -> String {
        let digits = "0123456789"
        return String((0..<length).map { _ in digits.randomElement()! })
    }
    func getGenerationCode() throws -> String {
        // Generate parts of the string according to the regex pattern
        let part1 = generateRandomHex(length: 8)
        let part2 = generateRandomHex(length: 4)
        let part3 = generateRandomHex(length: 4)
        let part4 = generateRandomHex(length: 4)
        let part5 = generateRandomHex(length: 12)
        
        // Construct the final string
        let result = "\(part1)-\(part2)-\(part3)-\(part4)-\(part5)"
        
        // Validate the result against the regex
        let pattern = "^[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}$"
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: result.utf16.count)
        if regex.firstMatch(in: result, options: [], range: range) == nil {
            throw DTEValidationErrors.stringGeneratedDoesntMatchExpectedPattern
        }
        
        return result
    }
    
    private    func generateRandomHex(length: Int) -> String {
        let characters = "ABCDEF0123456789"
        return String((0..<length).map { _ in characters.randomElement()! })
    }
    
    func formatNationalId(_ nationalId: String) throws -> String {
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
    
     
    func generateHourString(date: Date)throws -> String {
        // Format the Date object to match the regex pattern
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let hourString = formatter.string(from: date)

        // Validate the result against the regex
        let pattern = "^(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]?$"
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(location: 0, length: hourString.utf16.count)
        if regex.firstMatch(in: hourString, options: [], range: range) == nil {
            
            throw DTEValidationErrors.stringGeneratedDoesntMatchExpectedPattern
        }

        return hourString
    }
    
    func numberToWords(_ number: Double) -> String {
           if number == 0 {
               return "cero"
           }

           let integerPart = Int(floor(number))
           let decimalPart = Int((number - Double(integerPart)) * 100)

           return "\(numberToWords(integerPart)) DÓLARES CON \(decimalPart)/100"
       }

       private  func numberToWords(_ number: Int) -> String {
           if number == 0 {
               return "cero"
           }

           if number < 0 {
               return "menos " + numberToWords(abs(number))
           }

           var num = number
           var words = ""

           if (num / 1000000) > 0 {
               words += numberToWords(num / 1000000) + " millón "
               if (num / 1000000) > 1 {
                   words += "es "
               }
               num %= 1000000
           }

           if (num / 1000) > 0 {
               words += numberToWords(num / 1000) + " mil "
               num %= 1000
           }

           if (num / 100) > 0 {
               if num / 100 == 1 && num % 100 == 0 {
                   words += "cien "
               } else {
                   words += numberToWords(num / 100) + "cientos "
               }
               num %= 100
           }

           if num > 0 {
               if words != "" {
                   words += "y "
               }

               let unitsMap = ["", "uno", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve", "diez", "once", "doce", "trece", "catorce", "quince", "dieciséis", "diecisiete", "dieciocho", "diecinueve"]
               let tensMap = ["", "", "veinte", "treinta", "cuarenta", "cincuenta", "sesenta", "setenta", "ochenta", "noventa"]

               if num < 20 {
                   words += unitsMap[num]
               } else {
                   words += tensMap[num / 10]
                   if (num % 10) > 0 {
                       words += " y " + unitsMap[num % 10]
                   }
               }
           }

           return words.trimmingCharacters(in: .whitespacesAndNewlines)
       }
    
}
