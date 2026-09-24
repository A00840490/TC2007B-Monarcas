//
//  RutaDiaView.swift
//  Ruta_del_dia
//
// Creado por Alumno 24/09/26
//

import SwiftUI
 
struct RutaDiaView: View {
 
    let api = CaritasApi()
 
    let usuarioId = 1
 
    @State private var ruta: [Recoleccion] = []
    @State private var fecha = Date()
    @State private var cargando = false
    @State private var mostrarFecha = false
    @State private var showAlert = false
    @State private var mensajeAlerta = ""
 
    var body: some View {
        NavigationStack {
            ZStack {
                fondoPantalla.ignoresSafeArea()
 
                VStack(spacing: 8) {
                    encabezado
 
                    ScrollView {
                        VStack(spacing: 16) {
                            resumenCard
 
                            if cargando {
                                ProgressView()
                            }
 
                            if ruta.isEmpty && !cargando {
                                Text("No hay visitas para esta fecha")
                                    .font(.system(size: 15))
                                    .foregroundStyle(tealTexto)
                                    .padding()
                            }
 
                            ForEach(ruta) { recoleccion in
                                NavigationLink {
                                    DetalleView()
                                } label: {
                                    VisitaCardView(visita: recoleccion, esProxima: recoleccion.id == idProxima)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .toolbar(.hidden)
            .navigationDestination(isPresented: $mostrarFecha) {
                FechaView(fecha: $fecha)
            }
            .onAppear {
                cargarRuta()
            }
            .alert(mensajeAlerta, isPresented: $showAlert) {
                Button("OK") {}
            }
        }
    }
 
    var encabezado: some View {
        ZStack {
            Text("Ruta del Día")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(tealOscuro)
 
            HStack {
                Spacer()
 
                Button(action: abrirCalendario) {
                    Image(systemName: "calendar")
                        .foregroundStyle(tealCaritas)
                        .padding(10)
                        .background(tealSuave)
                        .clipShape(.circle)
                }
                Button(action: cargarRuta) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .foregroundStyle(tealCaritas)
                        .padding(10)
                        .background(tealSuave)
                        .clipShape(.circle)
                }
            }
        }
        .padding()
    }
 
    var resumenCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TOTAL RECAUDADO")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(tealTexto)
 
            HStack(alignment: .bottom) {
                Text("$0")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(tealCaritas)
                Text("MXN")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(tealCaritas)
            }
 
            HStack {
                Text("Progreso de visitas")
                    .foregroundStyle(tealTexto)
                Spacer()
                Text("0 de \(ruta.count) completadas")
                    .foregroundStyle(tealOscuro)
            }
            .font(.system(size: 14))
 
            if ruta.count > 0 {
                ProgressView(value: 0, total: Double(ruta.count))
                    .tint(tealCaritas)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
 
 
    var idProxima: Int {
        if let primera = ruta.first {
            return primera.id
        } else {
            return -1
        }
    }
 
 
    func abrirCalendario() {
        mostrarFecha = true
    }
 

    func fechaTexto() -> String {
        let formato = DateFormatter()
        formato.dateFormat = "yyyy-MM-dd"
        formato.locale = Locale(identifier: "es_MX")
        return formato.string(from: fecha)
    }
 
    func cargarRuta() {
        Task {
            cargando = true
            do {
                let parametros = RutaRequest(usuarioId: usuarioId, fecha: fechaTexto())
                ruta = try await api.getRuta(parametros)
            } catch {
                print("Error: \(error)")
                ruta = []
                mensajeAlerta = "No se pudo cargar la ruta"
                showAlert = true
            }
            cargando = false
        }
    }
}
 
#Preview {
    RutaDiaView()
}
