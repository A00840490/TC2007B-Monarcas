//
//  RutaDelDiaApp.swift
//  Ruta_del_dia
//
// Creado por Alumno 24/09/2026
//

import SwiftUI
import CaritasAuth

@main
struct RutaDelDiaApp: App {
    var body: some Scene {
        WindowGroup {
            AuthGate(configuration: APIConfig.auth) { _, cerrarSesion in
                RutaView(cerrarSesion: cerrarSesion)
            }
        }
    }
}
