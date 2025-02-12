import SwiftUI
import SwiftData

struct OnboardingView: View{
    
    @State private var activeIntro: PageIntro = pagesIntros[0]
    @Binding var requiresOnboarding: Bool
    @Binding var selectedCompanyId: String
    @State private var keyboardHeight: CGFloat = 0
    
    @State var company : Company = Company(nit:"",nrc:"",nombre:"",descActividad: "")
    
    var body: some View {
        ZStack{
            Color(activeIntro.backColor).ignoresSafeArea()
           
            
            GeometryReader{
                let size = $0.size
                
                introView(intro: $activeIntro,size: size){
                    VStack{
                        //CustomCompanyRegister
                        if activeIntro.companyStep1{
                            AddCompanyView(company: $company,intro: $activeIntro)
                        }
                        if activeIntro.companyStep2{
                            AddCompanyView2(company:$company,
                                            intro: $activeIntro)
                        }
                        if activeIntro.companyStep3{
                            AddCompanyView3(company: $company,
                                            intro: $activeIntro,
                                            requiresOnboarding: $requiresOnboarding,
                                            size: size,
                                            selectedCompanyId: $selectedCompanyId)
                        }

                }
                .padding(.top,25)
            }
        }
            .padding(15)
            //.ignoresSafeArea(.keyboard,edges: .all)
            .offset(y: -keyboardHeight)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)){ output in
                if let info = output.userInfo, let height =
                    (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height {
                    keyboardHeight = height
                    
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)){ _ in
                keyboardHeight = 0
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8, blendDuration: 0),value: keyboardHeight)
            //.task { await syncCatalogsAsync()}
        }
        
    }
    
}

struct Home_Prewiews: PreviewProvider {
    static var previews: some View {
        Home()
    }
}
 

private struct introView<ActionView:View>: View {
    
    @Binding var intro: PageIntro
    var size: CGSize
    
    var filteredPages : [PageIntro] {
        pagesIntros.filter{ !$0.displaysAction }
    }
    
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
            
            VStack(alignment: .leading, spacing: 10){
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
                    
                    if intro.companyStep1 || intro.companyStep2 {
                        continueButon
                        
                    }
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
            if let index = pagesIntros.firstIndex(of: intro),
               ( isPrevious ? index != 0 :  index != pagesIntros.count - 1 ){
                intro = isPrevious ? pagesIntros[index - 1] :  pagesIntros[index + 1]
            }
            else{
                intro = isPrevious ? pagesIntros[0] : pagesIntros[pagesIntros.count - 1 ]
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

#Preview("Onboarding") {
    //OnboardingFromEmptyState()
    //OnboardingView(requiresOnboarding: .constant(true))
    OnboardingView(requiresOnboarding: .constant(true), selectedCompanyId: .constant(""))
}

#Preview("Onboarding Dark") {
    OnboardingView(requiresOnboarding: .constant(true), selectedCompanyId: .constant(""))
        .preferredColorScheme(.dark)
}
 

