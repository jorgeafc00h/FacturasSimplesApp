import SwiftUI
struct OnboardingView: View {
    @Binding var requiresOnboarding : Bool
    @State var selectedTab : Int = 0
    var body: some View {
         
        
      
        TabView(selection: $selectedTab){
            OnboardingView1.tag(0)
            OnboardingView2.tag(1)
            }
        .interactiveDismissDisabled(true)
        
        .onAppear(){
            UIPageControl.appearance().currentPageIndicatorTintColor = .darkCyan
            UIPageControl.appearance().pageIndicatorTintColor = .gray
            
        }
    }
    
    private var OnboardingView1: some View {
        ZStack{
            Color(.onboarding1).edgesIgnoringSafeArea(.all)
            VStack{
                Image(.onboardingImage1)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .ignoresSafeArea()
                
                
                Text("Facturas de manera sencilla y sin complicaciones.")
                    .padding()
                    .font(.system(size: 33))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                
                VStack{
                    Text("Podra gestionar multiples Empresas, clientes y facturas.\n Seleccione el boton Continuar para empezar")
                        .font(.subheadline)
                        .padding()
                        .fontWeight(.semibold)
                        .padding(.bottom)
                        .foregroundColor(.black)
                    
                    Button{
                        selectedTab = 1
                    } label: {
                        Text("Continuar")
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(.black)
                    .clipShape(Capsule())
                    
                    .padding(.horizontal)
                }
            }
        }
    }
    private var OnboardingView2: some View {
        ZStack{
            Color(.amarello).edgesIgnoringSafeArea(.all)
            ScrollView{
            VStack{
                
                Label("Empresas", systemImage: "books.vertical.circle.fill")
                                        .symbolEffect(.wiggle.byLayer, options: .repeat(.periodic(delay: 1.5)))
                                        .font(.system(size: 33))
                                        .fontWeight(.semibold)
                                        .padding()
                                        .foregroundColor(.black)
                Text("Primeros Pasos")
                    .font(.system(size: 20))
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                
               
               
                    VStack(alignment: .leading) {
                        
                        HStack{
                            Image(systemName: "1.circle")
                                .foregroundColor(.marine)
                                .symbolEffect(.breathe)
                                .padding()
                            Text("Seleccione continuar,")
                                .multilineTextAlignment(.leading)
                                .font(.system(size: 20))
                                .fontWeight(.semibold)
                                .padding(.trailing)
                        }
                        HStack{
                            Image(systemName: "2.circle")
                                .foregroundColor(.marine)
                                .symbolEffect(.breathe)
                                .padding()
                            Text("Seleccione Administrar Empresas")
                                .multilineTextAlignment(.leading)
                                .font(.system(size: 20))
                                .fontWeight(.semibold)
                                .padding(.trailing)
                        }
                        HStack{
                            Image(systemName: "plus")
                                .foregroundColor(.marine)
                                .symbolEffect(.breathe)
                                .padding()
                            Text("Seleccione Crear en el boton +")
                                .multilineTextAlignment(.leading)
                                .font(.system(size: 20))
                                .fontWeight(.semibold)
                                .padding(.trailing)
                        }
                        
                        HStack{
                            Image(systemName: "4.circle")
                                .foregroundColor(.marine)
                                .symbolEffect(.breathe)
                                .padding()
                            Text("Configure Sus datos, y certificado")
                                .multilineTextAlignment(.leading)
                                .font(.system(size: 20))
                                .fontWeight(.semibold)
                                .padding(.trailing)
                        }
                       
                        HStack{
                            Image(systemName: "lock.fill")
                                .foregroundColor(.marine)
                                .symbolEffect(.breathe)
                                .padding()
                            Text("Configure las credenciales de Hacienda y Certificado")
                                .multilineTextAlignment(.leading)
                                .font(.system(size: 20))
                                .fontWeight(.semibold)
                                .padding(.trailing)
                        }
                        
                        Button{
                            requiresOnboarding = false
                        } label: {
                            Text("Continuar")
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        
                        .background(.black)
                        .clipShape(Capsule())
                        .padding(.top)
                        .padding(.horizontal)
                    }
                    .foregroundColor(.black)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }.ignoresSafeArea(.all)
        }
    }
}

 
#Preview("Onboarding") {
    OnboardingView(requiresOnboarding: .constant(true))
}

#Preview("Onboarding Dark") {
    OnboardingView(requiresOnboarding: .constant(true))
        .preferredColorScheme(.dark)
}
 

