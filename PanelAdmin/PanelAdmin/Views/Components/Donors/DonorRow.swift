//
//  DonorRow.swift
//  PanelAdmin
//

import SwiftUI

/// Column widths shared by the list header and its rows.
enum DonorColumns
{
    static let risk: CGFloat = 150
    static let lastDonation: CGFloat = 270
    static let arrow: CGFloat = 40
    static let rowHeight: CGFloat = 64
}

/// One donor in the list: name, risk and last donation, plus the arrow that
/// opens the detail.
struct DonorRow: View
{
    let donor: DonorSummary
    
    var body: some View
    {
        HStack(spacing: 12)
        {
            Text(donor.name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Constants.neutralColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            RiskPill(riskStatus: donor.riskStatus)
                .frame(width: DonorColumns.risk, alignment: .leading)
            
            lastDonation
                .frame(width: DonorColumns.lastDonation, alignment: .leading)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Constants.primaryColor)
                .frame(width: 34, height: 34)
                .background(Constants.primaryColor.opacity(0.12))
                .clipShape(Circle())
                .frame(width: DonorColumns.arrow, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .frame(height: DonorColumns.rowHeight)
        .contentShape(Rectangle())
    }
    
    @ViewBuilder
    private var lastDonation: some View
    {
        if let amount = donor.lastDonationAmount
        {
            HStack(spacing: 10)
            {
                Text(DonorFormat.money(amount))
                    .font(.system(size: 17, weight: .medium))
                    .monospacedDigit()
                    .foregroundColor(Constants.neutralColor)
                    .frame(minWidth: 80, alignment: .leading)
                
                let isCold = (donor.daysSinceLastDonation ?? 0) > 60
                Text(DonorFormat.daysAgo(donor.daysSinceLastDonation))
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .foregroundColor(isCold ? Constants.warningColor : .gray)
                    .background(isCold ? Constants.warningColor.opacity(0.14) : Color.gray.opacity(0.12))
                    .cornerRadius(6)
            }
        }
        else
        {
            Text("Nunca ha donado")
                .font(.system(size: 15))
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    DonorRow(donor: DonorSummary(
        id: 1,
        name: "Francisco \"Paco\" Salinas",
        phone: "8199000003",
        riskStatus: "LOW",
        isActive: true,
        everDonated: true,
        hasActivePledge: true,
        pledgeAmount: 800,
        lastDonationDate: "2026-10-02",
        lastDonationAmount: 1500,
        daysSinceLastDonation: 7,
        windowTotal: 2500,
        paymentMethod: "CASH",
        recolectorId: 3
    ))
}
