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
//       EmptyView()
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
                    .font(.system(size: 33))
                    .fontWeight(.semibold)
                
                VStack{
                    Text("Podra gestionar multiples Empresas, clientes y facturas.\n Seleccione el boton Continuar para empezar")
                        .font(.subheadline)
                        .padding()
                        .fontWeight(.semibold)
                        .padding(.bottom)
                    
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
            Color(.onboarding1).edgesIgnoringSafeArea(.all)
            VStack{
                ContentUnavailableView {
                    Label("Empresas", systemImage: "books.vertical.circle.fill")
                        .symbolEffect(.breathe)
                }description: {
                    Text("El primer paso de configuracion es agregar una empresa luego crear clientes.")
                }actions: {
                     
                }
                .offset(y: -60)
                
                
                Text("Primeros Pasos")
                    .font(.system(size: 33))
                    .fontWeight(.semibold)
                
                VStack{
                    Text("Seleccione continuar , para comenzar a crear empresas seleccione Administrar Empresas \n\n Luego podra configurar su informacion proporcionada por el ministerio de hacienda como el certificado para firmar DTE y la imagen de logo de sus facturas")
                        .font(.subheadline)
                        .padding()
                        .fontWeight(.semibold)
                        .padding(.bottom)
                    
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
                    
                    .padding(.horizontal)
                }
            }
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

#Preview("Onboarding iPad") {
    OnboardingView(requiresOnboarding: .constant(true))
        .previewDevice("iPad Pro (12.9-inch) (6th generation)")
}
