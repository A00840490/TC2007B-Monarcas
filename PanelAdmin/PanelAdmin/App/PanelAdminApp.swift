//
//  PanelAdminApp.swift
//  PanelAdmin
//
//  Created by Alumno on 22/09/26.
//

import SwiftUI
import CaritasAuth

@main
struct PanelAdminApp: App {
    var body: some Scene {
        WindowGroup {
            // Requires an Admin login; with a valid session it shows the panel.
            AuthGate(configuration: APIConfig.auth) { _, logout in
                ContentView(onLogout: logout)
            }
        }
    }
}
