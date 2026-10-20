//
//  CallRowView.swift
//  PantallaTelemarketinas
//
//  Created by ximena gomez gonzalez on 22/09/26.
//

import SwiftUI

struct CallRowView: View {
    var call: Call

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(call.hour)
                    .font(.system(size: 15))
                    .foregroundColor(Constants.grayTextColor)
                Text(call.donor.name)
                    .font(.system(size: 17))
                    .foregroundColor(Constants.neutralColor)
            }

            Spacer()

            if call.state == "Terminada" {
                Text("Terminada · \(call.result)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(resultColor(call.status))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(resultColor(call.status).opacity(0.15))
                    .cornerRadius(16)
            } else {
                Text(call.state)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(stateColor(call.state))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(stateColor(call.state).opacity(0.15))
                    .cornerRadius(16)
            }

            Image(systemName: "chevron.right")
                .foregroundColor(Constants.grayTextColor)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .frame(minHeight: 64)
    }
}

#Preview {
    let previewDonor = CallDonor(id: 1, name: "Roberto Gómez Fernández", nickname: "Don Roberto",
                                 phone: "81 2234 5567", campaign: "Padrinazgo mensual",
                                 risk: "MEDIUM", pledge: 300)
    let previewCall = Call(id: 1, time: "", hour: "10:35", status: "PENDING",
                           state: "Próxima", result: "", goal: "Confirmar renovación",
                           donor: previewDonor)
    CallRowView(call: previewCall)
}
