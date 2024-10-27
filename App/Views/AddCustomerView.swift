/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that adds a new trip.
*/

import SwiftUI
import WidgetKit

struct AddCustomerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.calendar) private var calendar
    @Environment(\.dismiss) private var dismiss
    @Environment(\.timeZone) private var timeZone
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var company: String = ""
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    
    @State private var email: String = ""
    
    @State private var phone: String = ""
    @State private var nationalId: String = ""
    @State private var contributorId: String = ""
    @State private var nit: String = ""
    @State private var documentType: String = ""
    @State private var codActividad: String = ""
    @State private var descActividad: String = ""
    @State private var departamentoCode: String = ""
    @State private var municipioCode: String = ""
    @State private var departammento: String = ""
    @State private var municipio: String = ""
//    var dateRange: ClosedRange<Date> {
//        let start = Date.now
//        let components = DateComponents(calendar: calendar, timeZone: timeZone, year: 1)
//        let end = calendar.date(byAdding: components, to: start)!
//        return start ... end
//    }
//    
    var body: some View {
        CustomerForm {
            Section(header: Text("Cliente")) {
                TripGroupBox {
                    TextField("Nombre", text: $firstName)
                    TextField("Apellido", text: $lastName)
                    
                    TextField("DUI", text: $nationalId)
                    TextField("Telefono", text: $phone)
                    TextField("Email", text: $email)
                }
            }
            
            Section(header: Text("Direccion")) {
                TripGroupBox {
                    TextField("Departamento", text: $departammento)
                    TextField("Municipio", text: $municipio)
                    TextField("Direccion",text: $address)
                }
            }
            
            Section(header: Text("Information del Negocio")) {
                TripGroupBox {
                    TextField("Empresa", text: $company)
                }
            }
            
//            Section(header: Text("Trip Dates")) {
//                TripGroupBox {
//                    HStack {
//                        VStack(alignment: .leading) {
//                            Text("Start Date:")
//                                .font(.caption)
//                                .foregroundStyle(.secondary)
//                            
//                            DatePicker(selection: $startDate, in: dateRange,
//                                       displayedComponents: .date) {
//                                Label("Start Date", systemImage: "calendar")
//                            }
//                            .labelsHidden()
//                        }
//                        Spacer()
//                        VStack(alignment: .trailing) {
//                            Text("End Date:")
//                                .font(.caption)
//                                .foregroundStyle(.secondary)
//                            
//                            DatePicker(selection: $endDate, in: dateRange,
//                                       displayedComponents: .date) {
//                                Label("End Date", systemImage: "calendar")
//                            }
//                            .labelsHidden()
//                        }
//                    }
//                }
//            }
        }
        .frame(idealWidth: LayoutConstants.sheetIdealWidth,
               idealHeight: LayoutConstants.sheetIdealHeight)
        .navigationTitle("Nuevo Cliente" )
        .navigationBarTitleDisplayMode(.automatic)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Guardar") {
                    addCustomer()
                    //WidgetCenter.shared.reloadTimelines(ofKind: "TripsWidget")
                    dismiss()
                }
                .disabled(firstName.isEmpty || nationalId.isEmpty)
            }
        }.accentColor(.darkCyan)
    }

    private func addCustomer() {
        withAnimation {
            //let newTrip = Trip(name: name, destination: destination, startDate: startDate, endDate:
            //modelContext.insert(newTrip)
            
            let newCustomer = Customer( firstName: firstName,
                                       lastName: lastName,
                                       nationalId: nationalId,
                                       email: email,
                                       phone: phone,
                                       departammento: departammento,
                                       municipio: municipio,
                                       address: address,
                                       company: company
                                      )
            modelContext.insert(newCustomer)
            try? modelContext.save()
        }
    }
}

#Preview(traits: .sampleCustomers) {
    AddCustomerView()
}

