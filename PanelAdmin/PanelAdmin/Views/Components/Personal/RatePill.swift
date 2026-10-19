//
//  RatePill.swift
//  PanelAdmin
//

import SwiftUI

/// A confirmation or success rate as a colored pill, like the donors' risk.
struct RatePill: View
{
    let rate: Int
    let color: Color
    var prefix: String = ""
    
    var body: some View
    {
        HStack(spacing: 6)
        {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            
            Text("\(prefix)\(rate)%")
                .font(.system(size: 14, weight: .semibold))
                .monospacedDigit()
        }
        .padding(.horizontal, 11)
        .padding(.vertical, 4)
        .foregroundColor(color)
        .background(color.opacity(0.14))
        .clipShape(Capsule())
    }
}

#Preview {
    HStack
    {
        RatePill(rate: 76, color: Constants.moneyColor)
        RatePill(rate: 55, color: Constants.warningColor)
        RatePill(rate: 30, color: Constants.dangerColor, prefix: "Confirmación ")
    }
}
