import Foundation

struct InvoiceSummary: Identifiable,Hashable{
    var id: UUID = .init()
    var total: Int
    var invoiceType: String
}
