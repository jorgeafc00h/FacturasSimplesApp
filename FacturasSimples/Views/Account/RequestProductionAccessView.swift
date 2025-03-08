import SwiftUI
import SwiftData


struct RequestProductionView: View {
    
    @State private var activeIntro: PageIntro = pagePreProdIntros[0]
    
    @Bindable var company : Company
    
    //@AppStorage("selectedCompanyIdentifier")  var companyId : String = ""
    
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack{
            Color(activeIntro.backColor).ignoresSafeArea()
            
            GeometryReader{
                let size = $0.size
                
                SubPageView(intro: $activeIntro,size: size){
                    VStack{
                        if activeIntro.companyStep1{
                            PreProdStep1(company: company, size: size)
                        }
                    }
                    .padding(.top,25)
                }
            }
            .padding(15)
            .interactiveDismissDisabled()
            
        }
        
    }
}

private struct SubPageView<ActionView:View> :View{
    
    @Binding var intro: PageIntro
    var size: CGSize
    
    
    var actionView: ActionView
    
    init(intro:Binding<PageIntro>, size: CGSize,
         @ViewBuilder actionView: @escaping () -> ActionView){
        self._intro = intro
        
        self.size = size
        self.actionView = actionView()
    }
    
    // animation properties
    
    @State private var showView: Bool = false
    @State private var hideHoleView: Bool = false
    var body: some View{
        VStack{
            // image view
            GeometryReader{
                let size = $0.size
                
                Image(intro.introAssetImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(15)
                    .frame(width: size.width, height: size.height)
            }
            // movig up
            .offset(y: showView ? 0 : -size.height/2)
            .opacity(showView ? 1 : 0)
            
            VStack(alignment: .center, spacing: 10){
                Spacer(minLength: 0)
                
                Text(intro.title)
                    .font(.system(size:40))
                    .fontWeight(.black)
                    .padding(.top,15)
                //                    .lineLimit(5)
                    .foregroundColor(.black)
                    .minimumScaleFactor(0.01)
                    .multilineTextAlignment(.leading)
                
                Text(intro.subTitle)
                    .font(.system(size:20))
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

//struct RequestProductionAccessView: View {
//    @Environment(\.modelContext)   var modelContext
//    @Environment(\.dismiss)   var dismiss
//    @Bindable var company: Company
//    @State var viewModel = RequestProductionAccessViewModel()
//
//
//
//    var body: some View {
//        ZStack {
//            Color(.onboarding1).ignoresSafeArea()
//
//            GeometryReader { geometry in
//                VStack {
//                    Spacer(minLength: 50)
//
//                    Text("Solicitar Acceso a Producción")
//                        .font(.title)
//                        .fontWeight(.bold)
//                        .foregroundColor(.primary)
//                        .padding(.bottom, 20)
//                        .offset(y: viewModel.showView ? 0 : -geometry.size.height / 2)
//                        .opacity(viewModel.showView ? 1 : 0)
//                        .animation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0).delay(0.1), value: viewModel.showView)
//
//                    VStack(spacing: 20) {
//                        if viewModel.hasMinimumInvoices {
//                            Button(action: ValidateProductionAccount) {
//                                Text("Siguiente")
//                                    .fontWeight(.bold)
//                                    .foregroundColor(.white)
//                                    .frame(maxWidth: .infinity)
//                                    .padding(EdgeInsets(top: 16, leading: 18, bottom: 16, trailing: 18))
//                                    .background(Capsule().fill(Color.blue))
//                                    .shadow(color: .gray, radius: 6)
//                            }
//                        } else {
//                            Button(action: { viewModel.showConfirmDialog = true }) {
//                                Text("Generar y Enviar 50 DTE por Tipo")
//                                    .fontWeight(.bold)
//                                    .foregroundColor(.white)
//                                    .frame(maxWidth: .infinity)
//                                    .padding(EdgeInsets(top: 16, leading: 18, bottom: 16, trailing: 18))
//                                    .background(Capsule().fill(Color.blue))
//                                    .shadow(color: .gray, radius: 6)
//                            }
//                            .confirmationDialog(
//                                "¿Desea generar y enviar 50 DTE por tipo?",
//                                isPresented: $viewModel.showConfirmDialog,
//                                titleVisibility: .visible
//                            ) {
//                                Button("Confirmar", action: generateAndSendInvoices)
//                                Button("Cancelar", role: .cancel) {}
//                            }
//                        }
//
//                        if viewModel.isSyncing {
//                            ProgressView(value: viewModel.progress, total: 1.0)
//                                .padding()
//                                .tint(Color.blue)
//                                .offset(y: viewModel.showView ? 0 : geometry.size.height / 2)
//                                .opacity(viewModel.showView ? 1 : 0)
//                                .animation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0).delay(0.1), value: viewModel.showView)
//                            Text("Progreso: \(Int(viewModel.progress * 100))%")
//                                .foregroundColor(.primary)
//                                .padding(.bottom)
//                                .offset(y: viewModel.showView ? 0 : geometry.size.height / 2)
//                                .opacity(viewModel.showView ? 1 : 0)
//                                .animation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0).delay(0.1), value: viewModel.showView)
//                        }
//
//                        Link("Solicitar Entorno Producción Facturación Electrónica", destination: URL(string: "https://admin.factura.gob.sv/login")!)
//                            .foregroundColor(Color.blue)
//                            .padding(.top, 30)
//                            .offset(y: viewModel.showView ? 0 : geometry.size.height / 2)
//                            .opacity(viewModel.showView ? 1 : 0)
//                            .animation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0).delay(0.1), value: viewModel.showView)
//
//                        Button(action: {
//                            dismiss()
//                        }) {
//                            Text("OK")
//                                .foregroundColor(.gray)
//                                .padding(.top, 20)
//                        }.disabled(viewModel.isSyncing)
//                        .offset(y: viewModel.showView ? 0 : geometry.size.height / 2)
//                        .opacity(viewModel.showView ? 1 : 0)
//                        .animation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0).delay(0.1), value: viewModel.showView)
//                    }
//                    .padding(.horizontal, 42.0)
//                    .offset(y: viewModel.showView ? 0 : geometry.size.height / 2)
//                    .opacity(viewModel.showView ? 1 : 0)
//                    .animation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0).delay(0.1), value: viewModel.showView)
//
//                    Spacer()
//                }
//                .alert(isPresented: $viewModel.showAlert) {
//                    Alert(title: Text("Información"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
//                }
//            }
//        }
//        .interactiveDismissDisabled()
//        .onAppear(perform: {
//            withAnimation(.spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0).delay(0.1)) {
//                viewModel.showView = true
//            }
//        })
//    }
//}

struct PreProdStep1:View{
    
    @Environment(\.modelContext)   var modelContext
    @Environment(\.dismiss)   var dismiss
    @Bindable var company: Company
    var size: CGSize
    
    @State var viewModel = RequestProductionAccessViewModel()
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing:10){
                
                Link("ir al portal de Hacienda Facturación Electrónica", destination: URL(string: "https://admin.factura.gob.sv/login")!)
                    .foregroundColor(.darkBlue)
                    .padding(.bottom)
                
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
                                //.frame(maxWidth: .infinity)
                                .frame(width: size.width * 0.4)
                                .padding(EdgeInsets(top: 16, leading: 18, bottom: 16, trailing: 18))
                                .background(Capsule().fill(Color.darkCyan))
                                .shadow(color: .gray, radius: 6)
                        }
                        .disabled(viewModel.isSyncing)
                    }
                    
                    else{
                        
                        Button(action: { viewModel.showConfirmDialog = true }) {
                            Text("Procesar")
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                //.frame(maxWidth: .infinity)
                                .frame(width: size.width * 0.4)
                                .padding(EdgeInsets(top: 16, leading: 18, bottom: 16, trailing: 18))
                                .background(Capsule().fill(Color.black))
                                .shadow(color: .gray, radius: 6)
                        }
                        .disabled(viewModel.isSyncing)
                        .confirmationDialog(
                            "¿Desea generar y enviar 50 DTE por tipo?",
                            isPresented: $viewModel.showConfirmDialog,
                            titleVisibility: .visible
                        ) {
                            Button("Confirmar", action: generateAndSendInvoices)
                            Button("Cancelar", role: .cancel) {
                                ValidateProductionAccount()
                            }
                        }
                    }
                }
                Spacer(minLength: 7)
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text("Información"), message: Text(viewModel.alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
}

//#Preview {
//    RequestProductionAccessView(company: Company(nit: "123", nrc: "456", nombre: "Test Company"))
//}



#Preview("Onboarding") {
    RequestProductionView(company: Company(nit: "123", nrc: "456", nombre: "Test Company"))
}

#Preview("Onboarding Dark") {
    RequestProductionView(company: Company(nit: "123", nrc: "456", nombre: "Test Company"))
        .preferredColorScheme(.dark)
}


