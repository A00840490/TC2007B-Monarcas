//
//  PantallaTelemarketinasApp.swift
//  PantallaTelemarketinas
//
//  Created by ximena gomez gonzalez on 22/09/26.
//

import SwiftUI
import CaritasAuth

@main
struct PantallaTelemarketinasApp: App {
    var body: some Scene {
        WindowGroup {
            AuthGate(configuration: APIConfig.auth) { userId, logout in
                ContentView(onLogout: logout)
            }
        }
    }
}
