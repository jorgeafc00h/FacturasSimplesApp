//
//  InvoicesView.swift
//  App
//
//  Created by Jorge Flores on 10/25/24.
//

import SwiftUI
import SwiftData

struct InvoicesView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var showAddTrip = false
    @State private var selection: Invoice?
    @State private var searchText: String = ""
    @State private var invoicesCount = 0
    @State private var unreadInvoicesIdentifiers: [PersistentIdentifier] = []
    var body: some View {
        
        NavigationStack {
            InvoicesListView(selection:$selection,
                             invoicesCount: $invoicesCount,
                              unreadInvoicesIdentifiers: $unreadInvoicesIdentifiers,
                              searchText: searchText)
        }
        .task {
            print("getting unread inovices")
            //let custIdentifiers = await DataModel.shared.unreadCustomersIdentifiers()
            // unreadTripIdentifiers = custIdentifiers
             
        }
        .searchable(text: $searchText, placement: .sidebar)
       
//        .onChange(of: selection) { _, newValue in
//            if let newSelection = newValue {
//                if let index = unreadInvoicesIdentifiers.firstIndex(where: {
//                    $0 == newSelection.persistentModelID
//                }) {
//                    unreadInvoicesIdentifiers.remove(at: index)
//                }
//            }
//        }
//        .onChange(of: scenePhase) { _, newValue in
//            Task {
//                if newValue == .active {
//                    //unreadCustomersIdentifiers += await DataModel.shared.findUnreadTripIdentifiers()
//                } else {
//                    // Persist the unread trip identifiers for the next launch session.
//                    let identifiers = unreadInvoicesIdentifiers
//                    //await DataModel.shared.(identifiers)
//                }
//            }
//        }
   }
}

#Preview {
    InvoicesView()
}
