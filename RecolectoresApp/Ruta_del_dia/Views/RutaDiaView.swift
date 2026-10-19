//
//  RutaDiaView.swift
//  Ruta_del_dia
//
// Creado por Alumno 24/09/26
//

import SwiftUI
 
struct RutaDiaView: View {
 
    let api = CaritasApi()
 
    @State private var ruta: [Recoleccion] = []
    @State private var resumen: ResumenDia?
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
                                    ResultadoView(visita: recoleccion)
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
                Text("$\(totalRecaudado.formatted(.number.precision(.fractionLength(0...2))))")
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
                Text("\(completadas) de \(totalVisitas) completadas")
                    .foregroundStyle(tealOscuro)
            }
            .font(.system(size: 14))
 
            if totalVisitas > 0 {
                ProgressView(value: Double(completadas), total: Double(totalVisitas))
                    .tint(tealCaritas)
            }

            if let datos = resumen {
                Text("Exitosas: \(datos.successful)  ·  Fallidas: \(datos.failed)  ·  Pendientes: \(datos.pending)")
                    .font(.system(size: 13))
                    .foregroundStyle(tealTexto)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
 
 
    // La próxima es la primera visita que sigue pendiente
    var idProxima: Int {
        for visita in ruta {
            if visita.estadoTexto == "Pendiente" {
                return visita.id
            }
        }
        return -1
    }

    // Los números del resumen vienen del API (GET summary)
    var totalVisitas: Int {
        if let datos = resumen {
            return datos.totalVisits
        } else {
            return 0
        }
    }

    // Visitas que ya tienen resultado (Exitosa o Fallida)
    var completadas: Int {
        if let datos = resumen {
            return datos.successful + datos.failed
        } else {
            return 0
        }
    }

    // Lo recibido en las visitas exitosas
    var totalRecaudado: Double {
        if let datos = resumen {
            return datos.receivedAmount
        } else {
            return 0
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
                ruta = try await api.getRuta(fecha: fechaTexto())
            } catch {
                print("Error: \(error)")
                ruta = []
                resumen = nil
                if let errorApi = error as? ApiError {
                    mensajeAlerta = errorApi.mensaje
                } else {
                    mensajeAlerta = "No se pudo cargar la ruta"
                }
                showAlert = true
                cargando = false
                return
            }

            // El resumen del día viene de su propio endpoint
            do {
                resumen = try await api.getResumen(fecha: fechaTexto())
            } catch {
                print("Error en el resumen: \(error)")
                resumen = nil
            }
            cargando = false
        }
    }
}
 
#Preview {
    RutaDiaView()
}