//
//  CustomIndicatorView.swift
//  FacturasSimples
//
//  Created by Jorge Flores on 2/7/25.
//

import SwiftUI

struct CustomIndicatorView: View {
    
    var totalPages: Int
    var currentPage: Int
    var activeTint: Color = .black
    var inactiveTint: Color = .gray.opacity(0.5)
    var body: some View {
        HStack(spacing:8){
            ForEach(0..<totalPages, id: \.self){
                Circle()
                    .fill(currentPage == $0 ? activeTint : inactiveTint  )
                    .frame(width: 4, height: 4)
            }
        }
    }
}

struct CustomTextField: View{
    @Binding var text: String
    var hint: String
    var leadingIcon: String
    var isPassword: Bool = false
    
    var hintColor :Color = .tabBar
    
    var body: some View{
        HStack(spacing:8){
            Image(systemName: leadingIcon)
                .font(.callout)
                .foregroundColor(.gray)
                .frame(width: 40,alignment: .leading)
            
            if isPassword{
                SecureField("",text: $text)
                   
                    
            }
            else{
                TextField("",text: $text, prompt: Text(hint).foregroundColor(hintColor))
                   
            }
        }
        .padding(.horizontal,15)
        .padding(.vertical,15)
        .foregroundColor(.black)
        .accentColor(.black)
        .background{
            RoundedRectangle(cornerRadius: 12,style: .continuous)
                .fill(.gray.opacity(0.1))
        }
                          
    }
}
