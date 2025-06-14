//
//  AddInvoiceView.swift
//  App
//
//  Created by Jorge Flores on 11/3/24.
//

import SwiftUI
import SwiftData

struct AddInvoiceView: View {
    @Environment(\.modelContext)  var modelContext
    @Environment(\.calendar) private var calendar
    @Environment(\.dismiss)  var dismiss
    @Environment(\.timeZone) private var timeZone
    @EnvironmentObject var storeKitManager: StoreKitManager
    
    @AppStorage("selectedCompanyIdentifier")  var companyIdentifier : String = ""
    @Query var companies: [Company]
    
    @State var viewModel = AddInvoiceViewModel()
    @State var showCreditsGate = false
    
    // just to set as selected when the invoice is created.!!
    @Binding var selectedInvoice : Invoice?
    
    var selectedCompany: Company? {
        companies.first { $0.id == companyIdentifier }
    }
    
    var shouldDisableForCredits: Bool {
        guard let company = selectedCompany else { return false }
        
        // Test accounts don't need credit validation
        if company.isTestAccount {
            return false
        }
        
        // Production accounts need implementation fee and credits
        return storeKitManager.requiresImplementationFee(for: company) || !storeKitManager.hasAvailableCredits(for: company)
    }
    
    var shouldShowCreditsWarning: Bool {
        guard let company = selectedCompany else { return false }
        
        // Only show warning for production accounts that lack credits or implementation fee
        return company.requiresPaidServices && shouldDisableForCredits
    }
    
    var creditsWarningMessage: String {
        guard let company = selectedCompany else { return "" }
        
        if company.requiresPaidServices {
            if storeKitManager.requiresImplementationFee(for: company) {
                return "Esta empresa requiere pagar el costo de implementación para crear facturas en producción"
            } else if !storeKitManager.hasAvailableCredits(for: company) {
                return "Esta empresa requiere créditos para crear facturas en producción"
            }
        }
        
        return ""
    }
    
    var body: some View {
        
        NavigationStack { 
            Form{
                // Credits Status Section
                Section {
                    CreditsStatusView(company: selectedCompany)
                        .environmentObject(storeKitManager)
                }
                
                CustomerSection
                InvoiceDataSection
                ProductDetailsSection
                Section {
                    Button(action: { handleCreateInvoice(storeKitManager: storeKitManager, showCreditsGate: $showCreditsGate) }, label: {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Crear Factura")
                        }
                    })
                    .disabled(viewModel.disableAddInvoice)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.white)
                    .padding()
                    .background(.darkCyan)
                    .cornerRadius(10)
                    
                    if shouldShowCreditsWarning {
                        Text(creditsWarningMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .frame(idealWidth: LayoutConstants.sheetIdealWidth,
                   idealHeight: LayoutConstants.sheetIdealHeight)
            .navigationTitle("Nueva Factura")
            .sheet(isPresented: $viewModel.displayPickerSheet){
                CustomerPicker(selection:$viewModel.customer)
            }
            .sheet(isPresented: $viewModel.displayProductPickerSheet){
                ProductPicker(details: $viewModel.details)
            }
            .sheet(isPresented: $showCreditsGate) {
                CreditsGateView {
                    // When user proceeds after getting credits, dismiss the gate
                    showCreditsGate = false
                }
                .environmentObject(storeKitManager)
            }
            .sheet(isPresented: $viewModel.showImplementationFee) {
                if let company = selectedCompany {
                    ImplementationFeeView(company: company)
                        .environmentObject(storeKitManager)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Guardar", action: { handleCreateInvoice(storeKitManager: storeKitManager, showCreditsGate: $showCreditsGate) })
                    .disabled(viewModel.disableAddInvoice || shouldDisableForCredits)
                }
            }.accentColor(.darkCyan)
        }
        .onAppear(perform: getNextInoviceNumber)
        .onChange(of: viewModel.invoiceType){
            getNextInoviceOrCCFNumber(invoiceType: viewModel.invoiceType)
        }
        .presentationDetents([.large])
    }
    
    
    
    private var CustomerSection: some View {
        Section {
            Group{
                Button{
                    viewModel.displayPickerSheet.toggle()
                }label: {
                    if viewModel.customer == nil {
                        HStack{
                            Image(systemName: "magnifyingglass")
                            Text("Buscar Cliente")
                        }.foregroundColor(.darkCyan)
                    }
                    else {
                        HStack{
                            Text(viewModel.customer!.fullName)
                            Spacer()
                            Text(viewModel.customer!.nationalId)
                        }
                    }
                }
            }
            
            
        }
        
    }
    
    private var InvoiceDataSection : some View{
        Section {
            Group {
                TextField("Número de Factura",text: $viewModel.invoiceNumber)
                    .keyboardType(.numberPad)
                HStack{
                    Text("Fecha:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    DatePicker("Fecha", selection: $viewModel.date, displayedComponents: .date)
                        .labelsHidden()
                    
                }
               
                HStack{
                    Text("Tipo Documento:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker(" ", selection: $viewModel.invoiceType) {
                        ForEach(viewModel.invoiceTypes, id: \.self) { invoiceType in
                            
                            Text(invoiceType.stringValue()).tag(invoiceType)
                        }
                    }
                    //.onChange(of: viewModel.invoiceType, action: getNextInoviceOrCCFNumber(invoiceType: viewModel.invoiceType))
                    .pickerStyle(.segmented)
                }
                
            }
            
        }
    }
    
    
    private var ProductDetailsSection: some View {
        Section(header: Text("Productos")) {
            ForEach($viewModel.details) { $item in
                ProductDetailEditView(item: $item)
            }
            .onDelete(perform: deleteProduct)
            if viewModel.showAddProductSection {
                addProductSection
            }
            HStack{
                if !viewModel.showAddProductSection {
                    Button(action: SearchProduct,label: {
                        Label("Buscar Producto", systemImage: "magnifyingglass")
                    })
                }
                Spacer()
                Button(action: ShowAddProductSection,label: {
                    viewModel.showAddProductSection ?
                    Image(systemName: "xmark.circle.fill")
                        .contentTransition(.symbolEffect(.replace))
                        .foregroundColor(.red):
                    Image(systemName: "plus")
                        .contentTransition(.symbolEffect(.replace))
                        .foregroundColor(.darkCyan)
                })
            }
            .buttonStyle(BorderlessButtonStyle())
            .foregroundColor(.darkCyan)
        }
        
    }
    private var addProductSection : some View{
        VStack(alignment: .leading){
            TextField("Producto", text: $viewModel.productName)
            
            Divider()
                .frame(height: 1)
                .background(Color("Dark-Cyan")).padding(.bottom)
            
             TextField("Precio Unitario", value: $viewModel.unitPrice, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                   
            // .padding(.vertical, 10)
            Divider()
                .frame(height: 1)
                .background(Color("Dark-Cyan")).padding(.bottom)
            
            
            HStack{
                Text("IVA Incluido : \(viewModel.newProductHasTax ? "Si" : "No")")
                Spacer()
                Toggle("", isOn: $viewModel.newProductHasTax)
            }
            
            HStack{
                Text("IVA: $\(viewModel.productTax)")
                Spacer()
                if viewModel.newProductHasTax{
                    Text("Precio Unitario: $\(viewModel.productWithoutTax)")
                }
                else{
                    Text("Precio mas IVA: $\(viewModel.productUnitPricePlusTax)")
                }
                
               
            }
             
            Button(action: AddNewProduct,label: {
                HStack{
                    Image(systemName: "checkmark.circle.fill")
                        .contentTransition(.symbolEffect(.replace))
                    Text("Agregar")
                        .fontWeight(.bold)
                }
            }).disabled(viewModel.isDisabledAddProduct).padding(.vertical)
            
        }.buttonStyle(BorderlessButtonStyle())
    }
}




#Preview(traits: .sampleCustomers) {
    AddInoviceViewWrapper()
}


private struct AddInoviceViewWrapper: View {
    @State var selectedInovice: Invoice?
    var body: some View {
        AddInvoiceView(selectedInvoice: $selectedInovice)
    }
}
