//
//  HistoryRowView.swift
//  PantallaTelemarketinas
//
//  Created by Alumno on 17/10/26.
//

import SwiftUI

struct HistoryRowView: View {
    var item: HistoryItem

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: resultIcon(item.status))
                .font(.system(size: 24))
                .foregroundColor(resultColor(item.status))
                .frame(width: 28)

            VStack(alignment: .leading) {
                Text(item.result)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(resultColor(item.status))
                Text(item.notes)
                    .font(.system(size: 16))
                    .foregroundColor(Constants.grayTextColor)
                Text("\(longDate(item.date)) · \(item.hour)")
                    .font(.system(size: 15))
                    .foregroundColor(Constants.grayTextColor)
            }

            Spacer()

            if item.amount > 0 {
                Text("$\(Int(item.amount))")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(Constants.moneyColor)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

#Preview {
    HistoryRowView(item: HistoryItem(id: "call-1", status: "ACCEPTED", result: "Aceptó",
                                     date: "2026-08-02", hour: "10:35",
                                     notes: "Confirmó recolección el mismo mes.", amount: 300))
}
