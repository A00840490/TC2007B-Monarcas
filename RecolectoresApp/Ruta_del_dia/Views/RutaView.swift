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
            PendienteView(titulo: "Perfil", icono: "person", cerrarSesion: cerrarSesion)
                .tabItem {
                    Label("Perfil", systemImage: "person")
                }
        }
        .tint(tealCaritas)
    }
}

struct PendienteView: View {
    var titulo: String
    var icono: String
    var cerrarSesion: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icono)
                .font(.system(size: 40))
                .foregroundStyle(tealCaritas)
            Text(titulo)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(tealOscuro)
            Text("Disponible en el siguiente sprint")
                .font(.system(size: 15))
                .foregroundStyle(tealTexto)

            if let cerrarSesion = cerrarSesion {
                Button("Cerrar sesión", action: cerrarSesion)
                    .buttonStyle(.bordered)
                    .tint(tealCaritas)
                    .padding(.top, 8)
            }
        }
    }
}

#Preview {
    RutaView(cerrarSesion: {})
}
