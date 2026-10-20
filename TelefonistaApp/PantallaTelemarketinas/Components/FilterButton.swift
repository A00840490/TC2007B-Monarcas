//
//  FilterButton.swift
//  PantallaTelemarketinas
//
//  Created by Alumno on 17/10/26.
//

import SwiftUI

struct FilterButton: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn = !isOn
        } label: {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isOn ? .white : Constants.neutralColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isOn ? Constants.secondaryColor : Constants.grayBoxColor)
                .cornerRadius(20)
        }
    }
}

#Preview {
    FilterButton(title: "Vencidas", isOn: .constant(false))
}
