import SwiftUI

struct PageIntro: Identifiable,Hashable{
    var id: UUID = .init()
    var introAssetImage : String
    var title: String
    var subTitle: String
    var displaysAction : Bool = false
    
    var backColor : Color = .white
    
    var companyStep1: Bool = false
    var companyStep2: Bool = false
    
    var canContinue : Bool = true
    var hintColor : Color = .tabBar
}

var pagesIntros : [PageIntro] = [
    .init(introAssetImage: "OnboardingImage1",title:"Bienvenido a Facturas Simples", subTitle:"Gestiona tus documentos tributarios electrónicos,de manera fácil y rápida, sin complicaciones..." ,backColor: .onboarding1),
    .init(introAssetImage: "page1",title:"Gestiona Facturas para Múltiples Empresas", subTitle:"Podrá centralizar la facturación electrónica para múltiples emisores...", backColor: .white),
    .init(introAssetImage: "page2",title:"Configuración Inicial!!", subTitle: "Configure la Aplicación con su información de contribuyente y comience a gestionar sus facturas...", displaysAction: true, companyStep1: true  ),
    .init(introAssetImage: "AppLogo",title:"Datos Generales!", subTitle: "Es la informacion que aparecera en las factura y DTE enviados al ministerio de hacienda", displaysAction: true, companyStep2: true  ),
]
