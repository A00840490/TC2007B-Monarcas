//
//  SidebarButton.swift
//  PantallaTelemarketinas
//
//  Created by ximena gomez gonzalez on 23/09/26.
//

import SwiftUI

struct SidebarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18))
                Text(title)
                    .font(.system(size: 16))
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(isSelected ? Constants.primaryColor : Color.clear)
            .foregroundColor(isSelected ? .white : Constants.neutralColor)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SidebarButton(icon: "house.fill", title: "Inicio", isSelected: true, onTap: {})
}
