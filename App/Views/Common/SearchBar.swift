//
//  SearchBar.swift
//  App
//
//  Created by Jorge Flores on 10/21/24.
//

import SwiftUI

struct SearchBar: View {
    var body: some View {
        SearchModule()
    }
}

struct SearchModule:View {
    
    @State var searchKeys:String = ""
    @State var isSearchResultEmpty = false

    
    
    var body: some View{
        
        VStack{
            
            HStack {
                
                Button(action: {SearchFunc(keywords:searchKeys)}, label: {
                    Image(systemName: "magnifyingglass").foregroundColor(searchKeys.isEmpty ? Color("Amarello") : Color("Dark-Cyan") )
                }).alert(isPresented: $isSearchResultEmpty) {
                    Alert(title: Text("Error"), message: Text("No se encontro"), dismissButton: .default(Text("ok")))
                }
                
                
                ZStack(alignment: .leading){
                    
                    if searchKeys.isEmpty {
                        Text("Buscar")
                            .font(.title3)
                            .foregroundColor(Color(red: 174/255, green: 177/255, blue: 185/255, opacity: 1.0)) }
                    
                    
                    TextField("", text: $searchKeys).font(.title3).foregroundColor(.white)
                    
                }
            }.padding([.top, .leading, .bottom], 11.0)
                .background(Color("Blue-Gray"))
                .clipShape(Capsule())
            
        }
        
    }
    
    func SearchFunc(keywords:String){
        
    }
}

#Preview {
    SearchBar()
}
