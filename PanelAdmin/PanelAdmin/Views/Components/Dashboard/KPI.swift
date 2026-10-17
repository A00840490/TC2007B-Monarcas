//
//  KPI.swift
//  PanelAdmin
//
//  Created by Alumno on 22/09/26.
//

import SwiftUI

struct KPI: View
{
    let title: String
    let value: Int
    let unit: String
    
    var body: some View
    {
        VStack(alignment: .leading)
        {
            Text(title)
                .font(.system(size: 20))
                .foregroundColor(.gray)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            
            HStack
            {
                Text("\(value)")
                    .font(.system(size: 32))
                
                Text(unit)
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .padding(16)
        .background(.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    KPI(title: "Dinero Disponible", value: 4532090, unit: "MXN")
}
