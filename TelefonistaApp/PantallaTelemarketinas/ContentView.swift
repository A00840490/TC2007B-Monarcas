//
//  ContentView.swift
//  PantallaTelemarketinas
//
//  Created by ximena gomez gonzalez on 22/09/26.
//

import SwiftUI

struct ContentView: View {
    var onLogout: () -> Void

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
                NavigationStack {
                    ActiveShiftView()
                }
                .tint(Constants.secondaryColor)
            default:
                WelcomeView(selectedTab: $selectedTab, onLogout: onLogout)
            }
        }
    }
}

#Preview {
    ContentView(onLogout: {})
}
