//
//  PreviewSampleData.swift
//  App
//
//  Created by Jorge Flores on 10/22/24.
//

import SwiftData
import SwiftUI

/**
 Preview sample data.
 */
struct SampleData: PreviewModifier {
    static func makeSharedContext() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Customer.self,
            configurations: config
        )
        SampleData.createSampleData(into: container.mainContext)
        return container
    }
    
    func body(content: Content, context: ModelContainer) -> some View {
          content.modelContainer(context)
    }
    
    static func createSampleData(into modelContext: ModelContext) {
        Task { @MainActor in
            let sampleDataCustomers: [Customer] = Customer.previewCustomers
            
            let sampleData: [any PersistentModel] = sampleDataCustomers// + sampleDataLA + sampleDataBLT
            sampleData.forEach {
                modelContext.insert($0)
            }
             
            try? modelContext.save()
        }
    }
}

@available(iOS 18.0, *)
extension PreviewTrait where T == Preview.ViewTraits {
    @MainActor static var sampleCustomers: Self = .modifier(SampleData())
}
