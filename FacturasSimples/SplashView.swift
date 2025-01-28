import SwiftUI
struct SplashView :  View{
    
    var body: some View {
         
        ZStack{
            Color(.marine).ignoresSafeArea()
            
            VStack{
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 450, height: 450)
                Text("Facturas Simples")
                    .font(.title)
                    .font(.system(size: 37, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                Text("Crea y Administra tus Facturas Facil y Rapido...")
                    .font(.footnote)
                    .font(.system(size: 27, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                
                Spacer()
                 
                
            }
            
        }
    }
}
#Preview {
    SplashView()
}
