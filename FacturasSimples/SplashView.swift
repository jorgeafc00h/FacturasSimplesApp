import SwiftUI
struct SplashView :  View{
    
    var body: some View {
         
        ZStack{
            Color(.blueGray).ignoresSafeArea()
            
            VStack{
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 450, height: 450)
                Text("Facturas Simples")
                    .font(.title)
                    .font(.custom("Bradley Hand", size: 32)).foregroundColor(.white)
                Text("Crea y Administre tus Facturas Fácil y Rápido...")
                    .padding()
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
