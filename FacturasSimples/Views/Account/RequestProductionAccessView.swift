import SwiftUI
import SwiftData


struct RequestProductionView: View {
    
    @State private var activeIntro: PageIntro = pagePreProdIntros[0]
    
    @Bindable var company : Company
    
    
    @Environment(\.modelContext) var modelContext
    @State private var showCloseButton: Bool = false
    
    var body: some View {
        ZStack{
            Color(activeIntro.backColor).ignoresSafeArea()
            
            GeometryReader{
                let size = $0.size
                
                SubPageView(intro: $activeIntro,size: size,showCloseButton: $showCloseButton){
                    VStack{
                        if activeIntro.companyStep1{
                            PreProdStep1(company: company, size: size, showCloseButton: $showCloseButton)
                        }
                    }
                    //.padding(.top,25)
                }
            }
            
            .padding(5)
            .interactiveDismissDisabled()
            
        }
        
    }
}

private struct SubPageView<ActionView:View> :View{
    
    @Binding var intro: PageIntro
    var size: CGSize
    @Environment(\.dismiss)   var dismiss
    
    var actionView: ActionView
    
    init(intro:Binding<PageIntro>, size: CGSize,showCloseButton: Binding<Bool>,
         @ViewBuilder actionView: @escaping () -> ActionView){
        self._intro = intro
        
        self.size = size
        self._showCloseButton = showCloseButton
        self.actionView = actionView()
    }
    
    // animation properties
    
    @State private var showView: Bool = false
    @State private var hideHoleView: Bool = false
    @Binding private var showCloseButton : Bool
    var body: some View{
        VStack{
            // image view
            GeometryReader{
                let size = $0.size
                
                Image(intro.introAssetImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(5)
                    .frame(width: size.width, height: size.height)
            }
            // movig up
            .offset(y: showView ? 0 : -size.height/2)
            .opacity(showView ? 1 : 0)
            
            VStack(alignment: .center, spacing: 10){
                Spacer(minLength: 0)
                
                Text(intro.title)
                    .font(.system(size:30))
                    .fontWeight(.black)
                    .padding(.top,3)
                //                    .lineLimit(5)
                    .foregroundColor(.black)
                    .minimumScaleFactor(0.01)
                    .multilineTextAlignment(.leading)
                
                Text(intro.subTitle)
                    .font(.system(size:17))
                    .fontWeight(.semibold)
                    .padding(.top,15)
                    .minimumScaleFactor(0.01)
                    .lineLimit(5)
                    .foregroundColor(.black)
                    .multilineTextAlignment(.leading)
                
                if !intro.displaysAction{
                    Group{
                        Spacer(minLength: 25)
                        
                        Spacer(minLength: 10)
                        
                        continueButon
                    }
                }
                else{
                    actionView
                    // moving down
                        .offset(y: showView ? 0 : size.height / 2)
                        .opacity(showView ? 1 : 0)
                    Spacer(minLength: 40)
                    
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // moving down
            .offset(y: showView ? 0 : size.height/2)
            .opacity(showView ? 1 : 0)
        }
        .offset(y: hideHoleView ? 0 : 1)
        .opacity(hideHoleView ? 0 : 1)
        .overlay(alignment: .topLeading){
            if intro != pagesIntros.first {
                Button{
                    changeIntro(true)
                }
                label:{
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .contentShape(Rectangle())
                }
                .padding(10)
                //Animating Back Button, comes from top when active
                .offset(y: showView ? 0 : -200)
                .offset(y: hideHoleView ? -200: 0)
                
            }
        }
        .overlay(alignment: .topTrailing){
            if !showCloseButton{
                Button{
                    dismiss()
                }
                label:{
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .contentShape(Rectangle())
                }
                .padding(10)
                //Animating Back Button, comes from top when active
                .offset(y: showView ? 0 : -200)
                .offset(y: hideHoleView ? -200: 0)
            }
        }
        .onAppear(){
            withAnimation(.spring(response:0.8,dampingFraction: 0.8,blendDuration:0).delay(0.1)){
                showView = true
            }
        }
    }
    private var continueButon : some View {
        Button{
            if intro.canContinue{
                changeIntro()
            }
            else{
                intro.hintColor = .red
            }
        }
        label:{
            Text("Continuar")
                .foregroundColor(.white)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.vertical, 15)
                .frame(width: size.width * 0.4)
                .background{
                    Capsule().fill(.black)
                }
        }.frame(maxWidth: .infinity)
    }
    
    func changeIntro(_ isPrevious: Bool = false){
        withAnimation(.spring(response:0.8,dampingFraction: 0.8,blendDuration:0)){
            hideHoleView = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            if let index = pagePreProdIntros.firstIndex(of: intro),
               ( isPrevious ? index != 0 :  index != pagesIntros.count - 1 ){
                print("page index \(index)")
                intro = isPrevious ? pagePreProdIntros[index - 1] :  pagePreProdIntros[index + 1]
            }
            else{
                intro = isPrevious ? pagePreProdIntros[0] : pagePreProdIntros[pagePreProdIntros.count - 1 ]
            }
            // Re animating as split page
            hideHoleView = false
            showView = false
            
            withAnimation(.spring(response:0.8,dampingFraction: 0.8,blendDuration:0)){
                showView = true
            }
        })
        
        
        
    }
}
 

struct PreProdStep1:View{
    
    @Environment(\.modelContext)   var modelContext
    @Environment(\.dismiss)   var dismiss
    @Bindable var company: Company
    var size: CGSize
    
    @State var viewModel = RequestProductionAccessViewModel()
    
    // Add state variables for confirmation dialogs
    @State private var showFacturasDialog = false
    @State private var showCCFDialog = false
    @State private var showNotasDialog = false
    @State private var showProcessAllDialog = false
    
    // Add state variables for force regeneration dialogs
    @State private var showForceFacturasDialog = false
    @State private var showForceCCFDialog = false 
    @State private var showForceNotasDialog = false
    @State private var showForceAllDialog = false
    
    // Add state to track selected document type
    @State private var selectedDocType: DocumentType = .factura
    @State private var showDocumentMenu = false
    @Binding var showCloseButton: Bool
    
    enum DocumentType: String, CaseIterable, Identifiable {
        case factura = "Facturas"
        case ccf = "Créditos Fiscales"
        case notaCredito = "Notas de Crédito"
        case todo = "Todo"
        
        var id: String { self.rawValue }
        
        var iconName: String {
            switch self {
            case .factura: return "doc.text"
            case .ccf: return "doc.text.fill"
            case .notaCredito: return "arrow.left.and.right.doc"
            case .todo: return "doc.on.doc.fill"
            }
        }
        
        var isProcessed: (RequestProductionAccessViewModel) -> Bool {
            switch self {
            case .factura: return { $0.hasProcessedFacturas }
            case .ccf: return { $0.hasProcessedCCF }
            case .notaCredito: return { $0.hasProcessedCreditNotes }
            case .todo: return { $0.hasProcessedFacturas && $0.hasProcessedCCF && $0.hasProcessedCreditNotes }
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing:10){
                
                Link("ir al portal de Hacienda Facturación Electrónica", destination: URL(string: "https://admin.factura.gob.sv/login")!)
                    .foregroundColor(.darkBlue)
                
                if viewModel.isSyncing {
                    withAnimation{
                        VStack{
                            ProgressView(value: viewModel.progress, total: 1.0)
                                .padding()
                                .tint(Color.marine)
                            
                            Text("Progreso: \(Int(viewModel.progress * 100))%")
                                .foregroundColor(.primary)
                                .padding(.bottom)
                        }
                    }
                }
                else{
                    if viewModel.hasCompleted {
                        Button(action: ValidateProductionAccount) {
                            Text("Completar")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(width: size.width * 0.4)
                                .padding(EdgeInsets(top: 16, leading: 18, bottom: 16, trailing: 18))
                                .background(Capsule().fill(Color.darkCyan))
                                .shadow(color: .gray, radius: 6)
                        }
                        .disabled(viewModel.isSyncing)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                    else {
                        // Dropdown selector for document type
                        Spacer()
                        Menu {
                            ForEach(DocumentType.allCases) { docType in
                                Button(action: { 
                                    selectedDocType = docType
                                    showConfirmationForType(docType)
                                }) {
                                    HStack {
                                        Image(systemName: docType.iconName)
                                        Text(docType.rawValue)
                                        if docType.isProcessed(viewModel) {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.green)
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: selectedDocType.iconName)
                                Text("Procesar \(selectedDocType.rawValue)")
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: size.width * 0.7)
                            .padding(EdgeInsets(top: 16, leading: 18, bottom: 16, trailing: 18))
                            .background(Capsule().fill(Color.black))
                            .shadow(color: .gray, radius: 6)
                        }
                        .padding(.top,10)
                        .disabled(viewModel.isSyncing)
                        
//                        Button(action: { processSelectedDocumentType() }) {
//                            Text("Procesar")
//                                .fontWeight(.bold)
//                                .foregroundColor(.white)
//                                .frame(width: size.width * 0.4)
//                                .padding(EdgeInsets(top: 16, leading: 18, bottom: 16, trailing: 18))
//                                .background(Capsule().fill(Color.black))
//                                .shadow(color: .gray, radius: 6)
//                        }
//                        .disabled(viewModel.isSyncing)
//                        .padding(.top, 20)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Información"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
            
            // Confirmation dialogs
            .confirmationDialog("¿Desea generar y enviar Facturas?", isPresented: $showFacturasDialog, titleVisibility: .visible) {
                Button("Confirmar") {
                    prepareCustomersAndProducts()
                    
                    // Check if we already have enough facturas
                    if viewModel.invoices.count(where: { $0.invoiceType == .Factura && $0.status == .Completada }) >= viewModel.totalInvoices {
                        showForceFacturasDialog = true
                    } else {
                        showCloseButton = false
                        generateFacturas()
                        sendInvoices()
                    }
                }
                Button("Cancelar", role: .cancel) {}
            }
            
            .confirmationDialog("¿Desea generar y enviar Créditos Fiscales?", isPresented: $showCCFDialog, titleVisibility: .visible) {
                Button("Confirmar") {
                    prepareCustomersAndProducts()
                    
                    // Check if we already have enough CCF
                    if viewModel.invoices.count(where: { $0.invoiceType == .CCF && $0.status == .Completada }) >= viewModel.totalInvoices {
                        showForceCCFDialog = true
                    } else {
                        showCloseButton = false
                        generateCreditosFiscales()
                        sendInvoices()
                    }
                }
                Button("Cancelar", role: .cancel) {}
            }
            
            .confirmationDialog("¿Desea generar y enviar Notas de Crédito?", isPresented: $showNotasDialog, titleVisibility: .visible) {
                Button("Confirmar") {
                    prepareCustomersAndProducts()
                    
                    // Check if we already have enough Credit Notes
                    if viewModel.invoices.count(where: { $0.invoiceType == .NotaCredito && $0.status == .Completada }) >= 50 {
                        showForceNotasDialog = true
                    } else {
                        showCloseButton = false
                        generateCreditNotes()
                        sendInvoices()
                    }
                }
                Button("Cancelar", role: .cancel) {}
            }
            
            // Confirmation dialog for "Procesar Todo"
            .confirmationDialog("¿Desea generar y enviar todos los tipos de documentos?", isPresented: $showProcessAllDialog, titleVisibility: .visible) {
                Button("Confirmar") {
                    prepareCustomersAndProducts()
                    
                    // Check if we already have enough of any type
                    let hasEnoughFacturas = viewModel.invoices.count(where: { $0.invoiceType == .Factura && $0.status == .Completada }) >= viewModel.totalInvoices
                    let hasEnoughCCF = viewModel.invoices.count(where: { $0.invoiceType == .CCF && $0.status == .Completada }) >= viewModel.totalInvoices
                    let hasEnoughNotes = viewModel.invoices.count(where: { $0.invoiceType == .NotaCredito && $0.status == .Completada }) >= 50
                    
                    if hasEnoughFacturas || hasEnoughCCF || hasEnoughNotes {
                        showForceAllDialog = true
                    } else {
                        showCloseButton = false
                        processAllDocuments()
                    }
                }
                Button("Cancelar", role: .cancel) {}
            }
            
            // Force generation confirmation dialogs
            .confirmationDialog("Ya existen suficientes Facturas completadas. ¿Desea generar una nueva tanda de todas formas?", isPresented: $showForceFacturasDialog, titleVisibility: .visible) {
                Button("Sí, generar nueva tanda") {
                    showCloseButton = false
                    generateFacturas(forceGenerate: true)
                    sendInvoices()
                }
                Button("No, cancelar", role: .cancel) {}
            }
            
            .confirmationDialog("Ya existen suficientes Créditos Fiscales completados. ¿Desea generar una nueva tanda de todas formas?", isPresented: $showForceCCFDialog, titleVisibility: .visible) {
                Button("Sí, generar nueva tanda") {
                    showCloseButton = false
                    generateCreditosFiscales(forceGenerate: true)
                    sendInvoices()
                }
                Button("No, cancelar", role: .cancel) {}
            }
            
            .confirmationDialog("Ya existen suficientes Notas de Crédito completadas. ¿Desea generar una nueva tanda de todas formas?", isPresented: $showForceNotasDialog, titleVisibility: .visible) {
                Button("Sí, generar nueva tanda") {
                    showCloseButton = false
                    generateCreditNotes(forceGenerate: true)
                    sendInvoices()
                }
                Button("No, cancelar", role: .cancel) {}
            }
            
            .confirmationDialog("Ya existen suficientes documentos completados. ¿Desea generar una nueva tanda de todos los tipos de todas formas?", isPresented: $showForceAllDialog, titleVisibility: .visible) {
                Button("Sí, generar nueva tanda de todos") {
                    showCloseButton = false
                    processAllDocuments(forceGenerate: true)
                }
                Button("No, cancelar", role: .cancel) {}
            }
            
            .onAppear {
                loadAllInvoices()
            }
        }
        
    }
    
    // Function to show the appropriate confirmation dialog based on document type
    private func showConfirmationForType(_ docType: DocumentType) {
        switch docType {
        case .factura:
            showFacturasDialog = true
        case .ccf:
            showCCFDialog = true
        case .notaCredito:
            showNotasDialog = true
        case .todo:
            showProcessAllDialog = true
        }
    }
    
    // Function to process the selected document type
    private func processSelectedDocumentType() {
        showConfirmationForType(selectedDocType)
    }
}

 

#Preview("Onboarding") {
    RequestProductionView(company: Company(nit: "123", nrc: "456", nombre: "Test Company"))
}

#Preview("Onboarding Dark") {
    RequestProductionView(company: Company(nit: "123", nrc: "456", nombre: "Test Company"))
        .preferredColorScheme(.dark)
}


#Preview ("3rd Page",traits: .sampleCompanies){
    
    // Add sample data
    let company = Company(nit:"123512351",nrc:"1351346",nombre:"Joe Cool",descActividad: "")
    
    let intro = pagesIntros[5]
    GeometryReader{
        let size = $0.size
        PreProdStep1(
            company: company,
            size: size,
            showCloseButton: .constant(false)
        )
    }
     
}


