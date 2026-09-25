//
//  Sidebar.swift
//  PantallaTelemarketinas
//
//  Created by ximena gomez gonzalez on 23/09/26.
//

import SwiftUI

struct Sidebar: View {
    @Binding var selectedTab: String

    var body: some View {
        VStack(alignment: .leading) {
            Text("Cáritas de Monterrey")
                .font(.system(size: 18))
                .foregroundColor(Constants.neutralColor)
                .padding(.bottom, 4)

            Divider()
                .padding(.bottom, 16)

            SidebarButton(
                icon: "house.fill",
                title: "Inicio",
                isSelected: selectedTab == "Inicio",
                onTap: { selectedTab = "Inicio" }
            )

            SidebarButton(
                icon: "phone.fill",
                title: "Turno activo",
                isSelected: selectedTab == "Turno",
                onTap: { selectedTab = "Turno" }
            )

            Spacer()
        }
        .padding()
    }
}

#Preview {
    Sidebar(selectedTab: .constant("Inicio"))
}
