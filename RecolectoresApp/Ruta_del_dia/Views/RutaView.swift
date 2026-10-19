//
//  RutaView.swift
//  Ruta_del_dia
//
// Creado por Alumno 24/09/26
//

import SwiftUI

struct RutaView: View {
    var cerrarSesion: () -> Void

    var body: some View {
        TabView {
            RutaDiaView()
                .tabItem {
                    Label("Ruta", systemImage: "list.bullet.rectangle")
                }
            NavigationStack {
                ProfileView(onLogout: cerrarSesion)
            }
            .tabItem {
                Label("Perfil", systemImage: "person")
            }
        }
        .tint(tealCaritas)
    }
}

#Preview {
    RutaView(cerrarSesion: {})
}