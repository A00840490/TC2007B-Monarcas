//
//  DonorKPICard.swift
//  PanelAdmin
//

import SwiftUI

struct DonorKPICard: View
{
    let title: String
    let value: String
    let note: String
    let tint: Color
    
    var body: some View
    {
        VStack(alignment: .leading, spacing: 4)
        {
            HStack(spacing: 8)
            {
                Circle()
                    .fill(tint)
                    .frame(width: 9, height: 9)
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Constants.neutralColor)
            }
            
            Text(value)
                .font(.system(size: 46, weight: .bold))
                .monospacedDigit()
                .foregroundColor(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            
            Text(note)
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .lineLimit(1)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.12))
        .cornerRadius(16)
    }
}

#Preview {
    HStack
    {
        DonorKPICard(title: "Donantes activos", value: "13", note: "de 16 registrados", tint: Constants.primaryColor)
        DonorKPICard(title: "Recaudado por activos", value: "$41,150", note: "últimos 6 meses", tint: Constants.moneyColor)
    }
    .padding()
}
