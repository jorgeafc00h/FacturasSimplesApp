//
//  CustomerListItem.swift
//  App
//
//  Created by Jorge Flores on 10/22/24.
//

import SwiftUI
import SwiftData

struct CustomersListItem: View {
    var customer: Customer
    let isUnread: Bool
    
    var body: some View {
        NavigationLink(value: customer) {
            HStack {
                Circle()
                    .fill(customer.color)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Text(String(customer.initials))
                            .font(.system(size: 38))
                            .foregroundStyle(.background)
                    }
                
                Circle()
                    .fill(isUnread ? .blue : .clear)
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading) {
                    Text(customer.fullName)
                        .font(.headline)
                    Text(customer.email)
                        .font(.subheadline)
                    
                    if case let (id?, p?) = (customer.nationalId, customer.phone) {
                        Divider()
                        HStack {
                            Text(id)
                            //Image(systemName: "arrow.right")
                            Text(p)
                        }
                        .font(.caption)
                    }
                }
            }
        }
    }
}

#Preview(traits: .sampleCustomers) {
    @Previewable @Query var customers: [Customer]
    List {
        CustomersListItem(customer: customers.first!, isUnread: true)
    }
}
