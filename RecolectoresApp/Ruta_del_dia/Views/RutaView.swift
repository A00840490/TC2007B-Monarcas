//
//  RutaView.swift
//  Ruta_del_dia
//
// Creado por Alumno 24/09/26
//

import SwiftUI

struct RutaView: View {
    var body: some View {
        TabView {
            RutaDiaView()
                .tabItem {
                    Label("Ruta", systemImage: "list.bullet.rectangle")
                }
            PendienteView(titulo: "Historial", icono: "clock")
                .tabItem {
                    Label("Historial", systemImage: "clock")
                }
            PendienteView(titulo: "Notificaciones", icono: "bell")
                .tabItem {
                    Label("Notificaciones", systemImage: "bell")
                }
            PendienteView(titulo: "Perfil", icono: "person")
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
        }
    }
}

#Preview {
    RutaView()
}
