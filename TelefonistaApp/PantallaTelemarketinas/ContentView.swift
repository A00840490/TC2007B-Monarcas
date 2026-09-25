//
//  ContentView.swift
//  PantallaTelemarketinas
//
//  Created by ximena gomez gonzalez on 22/09/26.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: String = "Inicio"

    var body: some View {
        HStack {
            if selectedTab != "Inicio" {
                Sidebar(selectedTab: $selectedTab)
                    .frame(width: 200)

                Divider()
            }

            switch selectedTab {
            case "Turno":
                TurnoActivoView()
            default:
                BienvenidaView(selectedTab: $selectedTab)
            }
        }
    }
}

#Preview {
    ContentView()
}
