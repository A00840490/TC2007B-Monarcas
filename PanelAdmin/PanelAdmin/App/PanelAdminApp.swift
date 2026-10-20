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
            AuthGate(configuration: APIConfig.auth) { _, logout in
                ContentView(onLogout: logout)
            }
        }
    }
}
