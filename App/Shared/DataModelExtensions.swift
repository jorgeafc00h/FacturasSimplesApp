// 
//import SwiftUI
//import SwiftData
//
//extension DataModel {
//    struct UserDefaultsKey {
//        static let unreadCustomerIdentifiers = "unreadCustomersIdentifiers"
//        static let historyToken = "historyToken"
//    }
//    /**
//     Getter and setter of the unread trip identifiers in the standard `UserDefaults`. This makes the identifiers avaiable for the next launch session.
//     DataModel is isolated, and `setUnreadTripIdentifiersInUserDefaults` provides a way to set the value using `await`.
//     */
//    var unreadCustomersIdentifiersInUserDefaults: [PersistentIdentifier] {
//        guard let data = UserDefaults.standard.data(forKey: UserDefaultsKey.unreadCustomerIdentifiers) else {
//            return []
//        }
//        let results = try? JSONDecoder().decode([PersistentIdentifier].self, from: data)
//        return results ?? []
//    }
//    
//    func setUnreadCustomersIdentifiersInUserDefaults(_ newValue: [PersistentIdentifier]) {
//        let data = try? JSONEncoder().encode(newValue)
//        UserDefaults.standard.set(data, forKey: UserDefaultsKey.unreadCustomerIdentifiers)
//    }
//    
//    /**
//     Find the unread trip identifiers by parsing the history.
//     */
////    func findUnreadTripIdentifiers() -> [PersistentIdentifier] {
////        let unreadTrips = findUnreadTrips()
////        return Array(unreadTrips).map { $0.persistentModelID }
////    }
//    
//    private func findUnreadCustomers() -> Set<Customer> {
//        let tokenData = UserDefaults.standard.data(forKey: UserDefaultsKey.historyToken)
//        
//        var historyToken: DefaultHistoryToken? = nil
//        if let data = tokenData {
//            historyToken = try? JSONDecoder().decode(DefaultHistoryToken.self, from: data)
//        }
//        let transactions = findTransactions(after: historyToken, author: TransactionAuthor.widget)
//        let (unreadCustomers, newToken) = findCustomers(in: transactions)
//        
//        if let token = newToken {
//            let newTokenData = try? JSONEncoder().encode(token)
//            UserDefaults.standard.set(newTokenData, forKey: UserDefaultsKey.historyToken)
//        }
//        return unreadCustomers
//    }
//    
//    private func findTransactions(after historyToken: DefaultHistoryToken?, author: String) -> [DefaultHistoryTransaction] {
//        var historyDescriptor = HistoryDescriptor<DefaultHistoryTransaction>()
//        if let token = historyToken {
//            historyDescriptor.predicate = #Predicate { transaction in
//                (transaction.token > token) && (transaction.author == author)
//            }
//        }
//        var transactions: [DefaultHistoryTransaction] = []
//        let taskContext = ModelContext(modelContainer)
//        do {
//            transactions = try taskContext.fetchHistory(historyDescriptor)
//        } catch let error {
//            print(error)
//        }
//        return transactions
//    }
//    
//    private func findCustomers(in transactions: [DefaultHistoryTransaction]) -> (Set<Customer>, DefaultHistoryToken?) {
//        let taskContext = ModelContext(modelContainer)
//        var resultCustomers: Set<Customer> = []
//        
//        for transaction in transactions {
//            for change in transaction.changes where isProductChange(change: change) {
//            }
//        }
//        return (resultCustomers, transactions.last?.token)
//    }
//    
//    private func isProductChange(change: HistoryChange) -> Bool {
//        switch change {
//        case .insert(let historyInsert):
//            if historyInsert is any HistoryInsert<Product> {
//                return true
//            }
//        case .update(let historyUpdate):
//            if historyUpdate is any HistoryUpdate<Product> {
//                return true
//            }
//        case .delete(let historyDelete):
//            if historyDelete is any HistoryDelete<Product> {
//                return true
//            }
//        default:
//            break
//        }
//        return false
//    }
//}

import SwiftUI

struct EnumPicker<T: Hashable & CaseIterable, V: View>: View {
    
    @Binding var selected: T
    var title: String? = nil
    
    let mapping: (T) -> V
    
    var body: some View {
        Picker(selection: $selected, label: Text(title ?? "")) {
            ForEach(Array(T.allCases), id: \.self) {
                mapping($0).tag($0)
            }
        }
    }
}

extension EnumPicker where T: RawRepresentable, T.RawValue == String, V == Text {
    init(selected: Binding<T>, title: String? = nil) {
        self.init(selected: selected, title: title) {
            Text($0.rawValue)
        }
    }
}
