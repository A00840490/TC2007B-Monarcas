//
//  RiskPill.swift
//  PanelAdmin
//

import SwiftUI

/// Donor's risk (LOW, MEDIUM, HIGH) as a colored pill.
struct RiskPill: View
{
    let riskStatus: String
    var prefix: String = ""
    
    var body: some View
    {
        let color = DonorFormat.riskColor(riskStatus)
        
        HStack(spacing: 6)
        {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            
            Text(prefix + DonorFormat.risk(riskStatus))
                .font(.system(size: 14, weight: .semibold))
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
        RiskPill(riskStatus: "LOW")
        RiskPill(riskStatus: "MEDIUM")
        RiskPill(riskStatus: "HIGH", prefix: "Riesgo ")
    }
}
