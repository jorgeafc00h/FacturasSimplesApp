import SwiftUI
import SwiftData


struct RequestProductionView: View {
    
    @State private var activeIntro: PageIntro = pagePreProdIntros[0]
    
    @Bindable var company : Company
    
    @State private var isSyncing: Bool = false
    
    @Environment(\.modelContext) var modelContext
    @State private var showCloseButton: Bool = true
    
    // Completion callback to notify parent when process is completed with optional Company
    var onCompletion: ((Company?) -> Void)? = nil
    
    var body: some View {
        ZStack{
            Color(activeIntro.backColor).ignoresSafeArea()
            
            GeometryReader{
                let size = $0.size
                
                SubPageView(intro: $activeIntro,size: size,showCloseButton: $showCloseButton, isSyncing: $isSyncing){
                    VStack{
                        if activeIntro.companyStep1{
                            PreProdStep1(company: company, size: size, isSyncing: $isSyncing, onCompletion: onCompletion, showCloseButton: $showCloseButton)
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
    
    init(intro:Binding<PageIntro>, size: CGSize,showCloseButton: Binding<Bool>, isSyncing: Binding<Bool> = .constant(false),
         @ViewBuilder actionView: @escaping () -> ActionView){
        self._intro = intro
        
        self.size = size
        self._showCloseButton = showCloseButton
        self._isSyncing = isSyncing
        self.actionView = actionView()
    }
    
    // animation properties
    
    @State private var showView: Bool = false
    @State private var hideHoleView: Bool = false
    @Binding private var showCloseButton : Bool
    
    // Add state to track syncing status for image resizing
    @Binding private var isSyncing: Bool
    var body: some View{
        VStack{
            // image view - dynamically sized based on syncing status and device
            GeometryReader{
                let imageSize = $0.size
                let isIPad = UIDevice.current.userInterfaceIdiom == .pad
                let imageSizeFactor: CGFloat = {
                    if isSyncing && isIPad {
                        return 0.4 // Much smaller on iPad when syncing
                    } else if isSyncing {
                        return 0.6 // Smaller on iPhone when syncing
                    } else if isIPad {
                        return 0.8 // Normal size on iPad
                    } else {
                        return 1.0 // Full size on iPhone
                    }
                }()
                
                Image(intro.introAssetImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(5)
                    .frame(
                        width: imageSize.width * imageSizeFactor, 
                        height: imageSize.height * imageSizeFactor
                    )
                    .frame(width: imageSize.width, height: imageSize.height, alignment: .center)
                    .animation(.easeInOut(duration: 0.5), value: isSyncing)
            }
            // Adjust frame height based on syncing status to give more space to progress bars
            .frame(height: {
                let baseHeight = size.height * 0.5
                if isSyncing && UIDevice.current.userInterfaceIdiom == .pad {
                    return baseHeight * 0.6 // Reduce image container height on iPad when syncing
                } else if isSyncing {
                    return baseHeight * 0.7 // Slightly reduce on iPhone when syncing
                } else {
                    return baseHeight
                }
            }())
            .animation(.easeInOut(duration: 0.5), value: isSyncing)
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
            if intro != pagePreProdIntros.first, showCloseButton {
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
            if showCloseButton{
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
            if let index = pagePreProdIntros.firstIndex(of: intro) {
                if isPrevious {
                    if index > 0 {
                        intro = pagePreProdIntros[index - 1]
                    } else {
                        intro = pagePreProdIntros[0]
                    }
                } else {
                    if index < pagePreProdIntros.count - 1 {
                        intro = pagePreProdIntros[index + 1]
                    } else {
                        intro = pagePreProdIntros[pagePreProdIntros.count - 1]
                    }
                }
            } else {
                // Fallback if intro not found
                intro = isPrevious ? pagePreProdIntros[0] : pagePreProdIntros[pagePreProdIntros.count - 1]
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
    
    @State private var viewModel = RequestProductionAccessViewModel()
    @Binding var isSyncing: Bool
    
    // Completion callback from parent
    var onCompletion: ((Company?) -> Void)? = nil
    
    // Add state variables for confirmation dialogs
    @State private var showFacturasDialog = false
    @State private var showCCFDialog = false
    @State private var showNotasDialog = false
    @State private var showSujetoExcluidoDialog = false
    @State private var showNotaDebitoDialog = false
    @State private var showProcessAllDialog = false
    
    // Add state variables for force regeneration dialogs
    @State private var showForceFacturasDialog = false
    @State private var showForceCCFDialog = false 
    @State private var showForceNotasDialog = false
    @State private var showForceSujetoExcluidoDialog = false
    @State private var showForceNotaDebitoDialog = false
    @State private var showForceAllDialog = false
    
    // Add state to track selected document type
    @State private var selectedDocType: DocumentType = .factura
    @State private var showDocumentMenu = false
    @Binding var showCloseButton: Bool
    
    enum DocumentType: String, CaseIterable, Identifiable {
        case factura = "Facturas"
        case ccf = "Créditos Fiscales"
        case notaCredito = "Notas de Crédito"
        case sujetoExcluido = "Sujetos Excluidos"
        case notaDebito = "Notas de Débito"
        case todo = "Todo"
        
        var id: String { self.rawValue }
        
        var iconName: String {
            switch self {
            case .factura: return "doc.text"
            case .ccf: return "doc.text.fill"
            case .notaCredito: return "arrow.left.and.right.doc"
            case .sujetoExcluido: return "person.badge.minus"
            case .notaDebito: return "arrow.right.and.left.doc"
            case .todo: return "doc.on.doc.fill"
            }
        }
        
        var isProcessed: (RequestProductionAccessViewModel) -> Bool {
            switch self {
            case .factura: return { $0.hasProcessedFacturas }
            case .ccf: return { $0.hasProcessedCCF }
            case .notaCredito: return { $0.hasProcessedCreditNotes }
            case .sujetoExcluido: return { $0.hasProcessedSujetoExcluido }
            case .notaDebito: return { $0.hasProcessedNotaDebito }
            case .todo: return { $0.hasProcessedFacturas && $0.hasProcessedCCF && $0.hasProcessedCreditNotes && $0.hasProcessedSujetoExcluido && $0.hasProcessedNotaDebito }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var headerLink: some View {
        Link("ir al portal de Hacienda Facturación Electrónica", destination: URL(string: "https://admin.factura.gob.sv/login") ?? URL(string: "https://mh.gob.sv")!)
            .foregroundColor(.darkBlue)
    }
    
    private var syncingView: some View {
        Group {
            if viewModel.isSyncing {
                progressView
            } else {
                nonSyncingView
            }
        }
    }
    
    private var progressView: some View {
        Group {
            if viewModel.isProcessingAll {
                allProgressView
            } else {
                singleProgressView
            }
        }
    }
    
    private var allProgressView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 16) {
                DocumentProgressView(
                    title: "Facturas",
                    progress: viewModel.facturasProgress,
                    status: viewModel.facturasStatus.displayText,
                    icon: "doc.text"
                )
                
                DocumentProgressView(
                    title: "Créditos Fiscales",
                    progress: viewModel.ccfProgress,
                    status: viewModel.ccfStatus.displayText,
                    icon: "doc.text.fill"
                )
                
                DocumentProgressView(
                    title: "Notas de Crédito",
                    progress: viewModel.creditNotesProgress,
                    status: viewModel.creditNotesStatus.displayText,
                    icon: "arrow.left.and.right.doc"
                )
                
                DocumentProgressView(
                    title: "Sujetos Excluidos",
                    progress: viewModel.sujetoExcluidoProgress,
                    status: viewModel.sujetoExcluidoStatus.displayText,
                    icon: "person.badge.minus"
                )
                
                DocumentProgressView(
                    title: "Notas de Débito",
                    progress: viewModel.notaDebitoProgress,
                    status: viewModel.notaDebitoStatus.displayText,
                    icon: "arrow.right.and.left.doc"
                )
                
                EnhancedProgressView(
                    title: "Progreso General",
                    progress: viewModel.progress,
                    icon: "chart.bar.fill",
                    isActive: viewModel.isSyncing,
                    showAsOverall: true
                )
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: .infinity)
        .clipped()
    }
    
    private var singleProgressView: some View {
        VStack(spacing: 16) {
            EnhancedProgressView(
                title: "Procesando \(selectedDocType.rawValue)",
                progress: getSingleDocumentProgress(for: selectedDocType),
                icon: selectedDocType.iconName,
                isActive: viewModel.isSyncing
            )
            
            // Invoice count label
            HStack {
                Text(getInvoiceCountText(for: selectedDocType))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding()
    }
    
    private var nonSyncingView: some View {
        Group {
            if viewModel.hasCompleted {
                completionButton
            } else {
                documentSelectionView
            }
        }
    }
    
    private var completionButton: some View {
        Button(action: { 
            viewModel.validateProductionAccount { createdCompany in
                // Don't dismiss here - let the parent handle it
                if let onCompletion = onCompletion {
                    onCompletion(createdCompany)
                    dismiss()
                }
            }
        }) {
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
    
    private var documentSelectionView: some View {
        VStack {
            Spacer(minLength: 0)
            documentTypeMenu
            Spacer(minLength: 0)
        }
    }
    
    private var documentTypeMenu: some View {
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
        .padding(.top, 10)
        .disabled(viewModel.isSyncing)
    }
    
    private var selectedDocumentInfo: some View {
        EmptyView() // Placeholder for any document info we might want to show
    }
    
    private var actionButton: some View {
        EmptyView() // Placeholder for any action button we might need
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 5) {
                headerLink
                    .padding(.bottom, 3)
                
                syncingView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(title: Text("Información"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
        }
        .onAppear {
            viewModel.configure(company: company, modelContext: modelContext)
           
        }
        .onChange(of: viewModel.isSyncing) { oldValue, newValue in
            isSyncing = newValue
            if oldValue && !newValue {
                showCloseButton = true
            }
        }
        .modifier(ConfirmationDialogsModifier(
            showFacturasDialog: $showFacturasDialog,
            showForceFacturasDialog: $showForceFacturasDialog,
            showCCFDialog: $showCCFDialog,
            showForceCCFDialog: $showForceCCFDialog,
            showNotasDialog: $showNotasDialog,
            showForceNotasDialog: $showForceNotasDialog,
            showSujetoExcluidoDialog: $showSujetoExcluidoDialog,
            showForceSujetoExcluidoDialog: $showForceSujetoExcluidoDialog,
            showNotaDebitoDialog: $showNotaDebitoDialog,
            showForceNotaDebitoDialog: $showForceNotaDebitoDialog,
            showProcessAllDialog: $showProcessAllDialog,
            showForceAllDialog: $showForceAllDialog,
            onConfirmFacturas: confirmFacturas,
            onConfirmForceFacturas: confirmForceFacturas,
            onConfirmCCF: confirmCCF,
            onConfirmForceCCF: confirmForceCCF,
            onConfirmCreditNotes: confirmCreditNotes,
            onConfirmForceCreditNotes: confirmForceCreditNotes,
            onConfirmSujetoExcluido: confirmSujetoExcluido,
            onConfirmForceSujetoExcluido: confirmForceSujetoExcluido,
            onConfirmNotaDebito: confirmNotaDebito,
            onConfirmForceNotaDebito: confirmForceNotaDebito,
            onConfirmProcessAll: confirmProcessAll,
            onConfirmForceAll: confirmForceAll
        ))
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
        case .sujetoExcluido:
            showSujetoExcluidoDialog = true
        case .notaDebito:
            showNotaDebitoDialog = true
        case .todo:
            showProcessAllDialog = true
        }
    }
    
    // MARK: - Helper Methods for Confirmation Dialogs

    private func confirmFacturas() {
        viewModel.prepareCustomersAndProducts()
        if viewModel.invoices.count(where: { $0.invoiceType == .Factura && $0.status == .Completada }) >= viewModel.totalInvoices {
            showForceFacturasDialog = true
        } else {
            showCloseButton = false
            viewModel.generateFacturas()
            viewModel.sendInvoices(onCompletion: wrapCompletion)
        }
    }

    private func confirmForceFacturas() {
        showCloseButton = false
        viewModel.generateFacturas(forceGenerate: true)
        viewModel.sendInvoices(onCompletion: wrapCompletion)
    }

    private func confirmCCF() {
        viewModel.prepareCustomersAndProducts()
        if viewModel.invoices.count(where: { $0.invoiceType == .CCF && $0.status == .Completada }) >= viewModel.totalInvoices {
            showForceCCFDialog = true
        } else {
            showCloseButton = false
            viewModel.generateCreditosFiscales()
            viewModel.sendInvoices(onCompletion: wrapCompletion)
        }
    }

    private func confirmForceCCF() {
        showCloseButton = false
        viewModel.generateCreditosFiscales(forceGenerate: true)
        viewModel.sendInvoices(onCompletion: wrapCompletion)
    }

    private func confirmCreditNotes() {
        viewModel.prepareCustomersAndProducts()
        if viewModel.invoices.count(where: { $0.invoiceType == .NotaCredito && $0.status == .Completada }) >= 75 {
            showForceNotasDialog = true
        } else {
            showCloseButton = false
            viewModel.generateCreditNotes()
            viewModel.sendInvoices(onCompletion: wrapCompletion)
        }
    }

    private func confirmForceCreditNotes() {
        showCloseButton = false
        viewModel.generateCreditNotes(forceGenerate: true)
        viewModel.sendInvoices(onCompletion: wrapCompletion)
    }

    private func confirmSujetoExcluido() {
        viewModel.prepareCustomersAndProducts()
        if viewModel.invoices.count(where: { $0.invoiceType == .SujetoExcluido && $0.status == .Completada }) >= viewModel.totalInvoices {
            showForceSujetoExcluidoDialog = true
        } else {
            showCloseButton = false
            viewModel.generateSujetoExcluido()
            viewModel.sendInvoices(onCompletion: wrapCompletion)
        }
    }

    private func confirmForceSujetoExcluido() {
        showCloseButton = false
        viewModel.generateSujetoExcluido(forceGenerate: true)
        viewModel.sendInvoices(onCompletion: wrapCompletion)
    }

    private func confirmNotaDebito() {
        viewModel.prepareCustomersAndProducts()
        if viewModel.invoices.count(where: { $0.invoiceType == .NotaDebito && $0.status == .Completada }) >= 75 {
            showForceNotaDebitoDialog = true
        } else {
            showCloseButton = false
            viewModel.generateNotaDebito()
            viewModel.sendInvoices(onCompletion: wrapCompletion)
        }
    }

    private func confirmForceNotaDebito() {
        showCloseButton = false
        viewModel.generateNotaDebito(forceGenerate: true)
        viewModel.sendInvoices(onCompletion: wrapCompletion)
    }

    private func confirmProcessAll() {
        viewModel.prepareCustomersAndProducts()
        let hasEnoughFacturas = viewModel.invoices.count(where: { $0.invoiceType == .Factura && $0.status == .Completada }) >= viewModel.totalInvoices
        let hasEnoughCCF = viewModel.invoices.count(where: { $0.invoiceType == .CCF && $0.status == .Completada }) >= viewModel.totalInvoices
        let hasEnoughNotes = viewModel.invoices.count(where: { $0.invoiceType == .NotaCredito && $0.status == .Completada }) >= 75
        let hasEnoughSujetoExcluido = viewModel.invoices.count(where: { $0.invoiceType == .SujetoExcluido && $0.status == .Completada }) >= viewModel.totalInvoices
        let hasEnoughNotaDebito = viewModel.invoices.count(where: { $0.invoiceType == .NotaDebito && $0.status == .Completada }) >= 75
        
        if hasEnoughFacturas || hasEnoughCCF || hasEnoughNotes || hasEnoughSujetoExcluido || hasEnoughNotaDebito {
            showForceAllDialog = true
        } else {
            showCloseButton = false
            viewModel.processAllDocuments(onCompletion: wrapCompletion)
        }
    }

    private func confirmForceAll() {
        showCloseButton = false
        viewModel.processAllDocuments(forceGenerate: true, onCompletion: wrapCompletion)
    }
    
    // Wrapper to convert simple completion to company-aware completion
    private func wrapCompletion() {
        // When the document processing is complete, validate and create the production account
        viewModel.validateProductionAccount { createdCompany in
            if let onCompletion = onCompletion {
                onCompletion(createdCompany)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Returns the appropriate progress value for a specific document type
    private func getSingleDocumentProgress(for docType: DocumentType) -> Double {
        switch docType {
        case .factura:
            return viewModel.facturasProgress
        case .ccf:
            return viewModel.ccfProgress
        case .notaCredito:
            return viewModel.creditNotesProgress
        case .sujetoExcluido:
            return viewModel.sujetoExcluidoProgress
        case .notaDebito:
            return viewModel.notaDebitoProgress
        case .todo:
            return viewModel.progress // Overall progress for "todo"
        }
    }
    
    /// Returns the count text for synced and pending invoices for a specific document type
    private func getInvoiceCountText(for docType: DocumentType) -> String {
        let syncedCount: Int
        let totalCount: Int
        
        switch docType {
        case .factura:
            let facturaInvoices = viewModel.generatedInvoices.filter { $0.invoiceType == .Factura }
            syncedCount = facturaInvoices.count(where: { $0.status == .Completada })
            totalCount = facturaInvoices.count
        case .ccf:
            let ccfInvoices = viewModel.generatedInvoices.filter { $0.invoiceType == .CCF && !$0.isHelperForCreditNote }
            syncedCount = ccfInvoices.count(where: { $0.status == .Completada })
            totalCount = ccfInvoices.count
        case .notaCredito:
            let creditNoteInvoices = viewModel.generatedInvoices.filter { $0.invoiceType == .NotaCredito }
            syncedCount = creditNoteInvoices.count(where: { $0.status == .Completada })
            totalCount = creditNoteInvoices.count
        case .sujetoExcluido:
            let sujetoExcluidoInvoices = viewModel.generatedInvoices.filter { $0.invoiceType == .SujetoExcluido }
            syncedCount = sujetoExcluidoInvoices.count(where: { $0.status == .Completada })
            totalCount = sujetoExcluidoInvoices.count
        case .notaDebito:
            let notaDebitoInvoices = viewModel.generatedInvoices.filter { $0.invoiceType == .NotaDebito }
            syncedCount = notaDebitoInvoices.count(where: { $0.status == .Completada })
            totalCount = notaDebitoInvoices.count
        case .todo:
            syncedCount = viewModel.generatedInvoices.count(where: { $0.status == .Completada })
            totalCount = viewModel.generatedInvoices.count
        }
        
        let pendingCount = totalCount - syncedCount
        return "Sincronizadas: \(syncedCount) | Pendientes: \(pendingCount)"
    }
}
 

#Preview("Onboarding") {
    RequestProductionView(company: Company(nit: "123", nrc: "456", nombre: "Test Company"), onCompletion: nil)
}

#Preview("Onboarding Dark") {
    RequestProductionView(company: Company(nit: "123", nrc: "456", nombre: "Test Company"), onCompletion: nil)
        .preferredColorScheme(.dark)
}


#Preview ("3rd Page",traits: .sampleCompanies){
    
    // Add sample data
    let company = Company(nit:"123512351",nrc:"1351346",nombre:"Joe Cool",descActividad: "")
    
    RequestProductionView(company: company, onCompletion: { createdCompany in
        print("Preview: Production access process completed with company: \(createdCompany?.nombreComercial ?? "nil")")
    })
}

// MARK: - ConfirmationDialogsModifier
struct ConfirmationDialogsModifier: ViewModifier {
    @Binding var showFacturasDialog: Bool
    @Binding var showForceFacturasDialog: Bool
    @Binding var showCCFDialog: Bool
    @Binding var showForceCCFDialog: Bool
    @Binding var showNotasDialog: Bool
    @Binding var showForceNotasDialog: Bool
    @Binding var showSujetoExcluidoDialog: Bool
    @Binding var showForceSujetoExcluidoDialog: Bool
    @Binding var showNotaDebitoDialog: Bool
    @Binding var showForceNotaDebitoDialog: Bool
    @Binding var showProcessAllDialog: Bool
    @Binding var showForceAllDialog: Bool
    
    let onConfirmFacturas: () -> Void
    let onConfirmForceFacturas: () -> Void
    let onConfirmCCF: () -> Void
    let onConfirmForceCCF: () -> Void
    let onConfirmCreditNotes: () -> Void
    let onConfirmForceCreditNotes: () -> Void
    let onConfirmSujetoExcluido: () -> Void
    let onConfirmForceSujetoExcluido: () -> Void
    let onConfirmNotaDebito: () -> Void
    let onConfirmForceNotaDebito: () -> Void
    let onConfirmProcessAll: () -> Void
    let onConfirmForceAll: () -> Void
    
    func body(content: Content) -> some View {
        content
            .confirmationDialog("¿Desea generar y enviar Facturas?", isPresented: $showFacturasDialog, titleVisibility: .visible) {
                Button("Confirmar", action: onConfirmFacturas)
                Button("Cancelar", role: .cancel) {}
            }
            .confirmationDialog("Ya existen suficientes Facturas completadas. ¿Desea generar una nueva tanda de todas formas?", isPresented: $showForceFacturasDialog, titleVisibility: .visible) {
                Button("Sí, generar nueva tanda", action: onConfirmForceFacturas)
                Button("No, cancelar", role: .cancel) {}
            }
            .confirmationDialog("¿Desea generar y enviar Créditos Fiscales?", isPresented: $showCCFDialog, titleVisibility: .visible) {
                Button("Confirmar", action: onConfirmCCF)
                Button("Cancelar", role: .cancel) {}
            }
            .confirmationDialog("Ya existen suficientes Créditos Fiscales completados. ¿Desea generar una nueva tanda de todas formas?", isPresented: $showForceCCFDialog, titleVisibility: .visible) {
                Button("Sí, generar nueva tanda", action: onConfirmForceCCF)
                Button("No, cancelar", role: .cancel) {}
            }
            .confirmationDialog("¿Desea generar y enviar Notas de Crédito?", isPresented: $showNotasDialog, titleVisibility: .visible) {
                Button("Confirmar", action: onConfirmCreditNotes)
                Button("Cancelar", role: .cancel) {}
            }
            .confirmationDialog("Ya existen suficientes Notas de Crédito completadas. ¿Desea generar una nueva tanda de todas formas?", isPresented: $showForceNotasDialog, titleVisibility: .visible) {
                Button("Sí, generar nueva tanda", action: onConfirmForceCreditNotes)
                Button("No, cancelar", role: .cancel) {}
            }
            .confirmationDialog("¿Desea generar y enviar Sujetos Excluidos?", isPresented: $showSujetoExcluidoDialog, titleVisibility: .visible) {
                Button("Confirmar", action: onConfirmSujetoExcluido)
                Button("Cancelar", role: .cancel) {}
            }
            .confirmationDialog("Ya existen suficientes Sujetos Excluidos completados. ¿Desea generar una nueva tanda de todas formas?", isPresented: $showForceSujetoExcluidoDialog, titleVisibility: .visible) {
                Button("Sí, generar nueva tanda", action: onConfirmForceSujetoExcluido)
                Button("No, cancelar", role: .cancel) {}
            }
            .confirmationDialog("¿Desea generar y enviar Notas de Débito?", isPresented: $showNotaDebitoDialog, titleVisibility: .visible) {
                Button("Confirmar", action: onConfirmNotaDebito)
                Button("Cancelar", role: .cancel) {}
            }
            .confirmationDialog("Ya existen suficientes Notas de Débito completadas. ¿Desea generar una nueva tanda de todas formas?", isPresented: $showForceNotaDebitoDialog, titleVisibility: .visible) {
                Button("Sí, generar nueva tanda", action: onConfirmForceNotaDebito)
                Button("No, cancelar", role: .cancel) {}
            }
            .confirmationDialog("¿Desea generar y enviar todos los tipos de documentos?", isPresented: $showProcessAllDialog, titleVisibility: .visible) {
                Button("Confirmar", action: onConfirmProcessAll)
                Button("Cancelar", role: .cancel) {}
            }
            .confirmationDialog("Ya existen suficientes documentos completados. ¿Desea generar una nueva tanda de todos los tipos de todas formas?", isPresented: $showForceAllDialog, titleVisibility: .visible) {
                Button("Sí, generar nueva tanda de todos", action: onConfirmForceAll)
                Button("No, cancelar", role: .cancel) {}
            }
    }
}

#Preview ("PreProdStep1 Direct", traits: .sampleCompanies) {
    // Add sample data
    let company = Company(nit:"123512351",nrc:"1351346",nombre:"Joe Cool",descActividad: "")
    
    GeometryReader { geometry in
        let size = geometry.size
        PreProdStep1(
            company: company,
            size: size,
            isSyncing: .constant(false),
            onCompletion: { createdCompany in
                print("Preview: PreProdStep1 completed with company: \(createdCompany?.nombreComercial ?? "nil")")
            },
            showCloseButton: .constant(true)
        )
    }
    .background(Color(.systemBackground))
}


