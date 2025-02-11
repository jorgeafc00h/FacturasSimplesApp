
import SwiftUI
import SwiftData

struct AddCompanyView: View {
    
    
    
    @Binding var company : Company
    @Binding var intro: PageIntro
    // @State var viewModel   = AddCompanyViewModel()
    
    var body: some View {
        
        
        VStack(spacing:10){
            CustomTextField(text:$company.nit, hint:"NIT", leadingIcon: "person.text.rectangle.fill", hintColor: intro.hintColor)
            CustomTextField(text:$company.nombre, hint:"Nombres y Apellidos", leadingIcon:"person.fill",hintColor: intro.hintColor)
            CustomTextField(text:$company.nombreComercial, hint:"Nombre Comercial", leadingIcon:"widget.small",hintColor: intro.hintColor)
            CustomTextField(text:$company.nrc, hint:"NRC", leadingIcon: "building.columns.circle",hintColor: intro.hintColor)
            
            Spacer(minLength: 10)
        }
        .onChange(of: [company.nit,company.nrc,company.nombreComercial]){
            intro.canContinue = canContinue()
        }
        .onAppear(){
            intro.canContinue = canContinue()
            intro.hintColor = .tabBar
        }
        
        
        
        
    }
    func canContinue()->Bool{
        return !company.nit.isEmpty && !company.nombre.isEmpty && !company.nrc.isEmpty && !company.nombreComercial.isEmpty
    }
}

struct AddCompanyView2: View {
    
    @Binding var company : Company
    @Binding var intro: PageIntro
    @Binding var requiresOnboarding : Bool
    var size: CGSize
    @Binding var selectedCompanyId : String
    
    @Environment(\.modelContext)   var modelContext
     
   
    @State var viewModel = AddCompanyViewModel()
    
    var body: some View {
        VStack(spacing:10){
            CustomTextField(text:$company.correo,hint:"Correo Electrónico", leadingIcon: "envelope.fill",hintColor: intro.hintColor)
            CustomTextField(text:$company.telefono,hint:"Telefono", leadingIcon: "phone",hintColor: intro.hintColor)
            CustomTextField(text:$company.complemento,hint:"Direccion", leadingIcon: "house.fill",hintColor: intro.hintColor)
            Spacer(minLength: 10)
            Button{
                if intro.canContinue{
                    saveChanges()
                    requiresOnboarding = false
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
        .onChange(of: [company.correo,company.telefono,company.complemento]){
            intro.canContinue = canContinue()
        }
        .onAppear(){
            intro.canContinue = canContinue()
            intro.hintColor = .tabBar
        }
    }
    func canContinue()->Bool{
        return !company.correo.isEmpty && !company.telefono.isEmpty && !company.complemento.isEmpty
    }
    
}



