//
//  ReprogramarView.swift
//  Ruta_del_dia
//
//  Created by Alumno on 19/10/26.
//

import SwiftUI

struct ReprogramarView: View {

    var visita: Recoleccion

    @Binding var reprogramadaPara: String

    let api = CaritasApi()

    @Environment(\.dismiss) private var dismiss

    @State private var fecha = Date()
    @State private var guardando = false
    @State private var mostrarError = false
    @State private var mensajeError = ""
    @State private var mostrarExito = false

    var body: some View {
        ZStack {
            fondoPantalla.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    Text("Reprogramar visita")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(tealOscuro)

                    VisitaCardView(visita: visita, esProxima: false, mostrarFlecha: false)

                    VStack(alignment: .leading, spacing: 16) {
                        Text("¿Para qué fecha la reprogramamos?")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(tealOscuro)

                        DatePicker("Nueva fecha", selection: $fecha, in: manana..., displayedComponents: [.date])
                            .datePickerStyle(.graphical)
                            .tint(tealCaritas)

                        Button(action: reprogramar) {
                            if guardando {
                                ProgressView()
                                    .tint(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                            } else {
                                Text("Reprogramar")
                                    .font(.system(size: 17, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(tealCaritas)
                        .disabled(guardando)
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .padding()
            }
            .alert("Visita reprogramada", isPresented: $mostrarExito) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Quedó para el \(fechaLarga).")
            }
        }
        .onAppear {
            fecha = manana
        }
        .alert("No se pudo reprogramar", isPresented: $mostrarError) {
            Button("Reintentar") {
                reprogramar()
            }
            Button("Cancelar") {}
        } message: {
            Text(mensajeError)
        }
    }

    var manana: Date {
        let mananaMismaHora = Date().addingTimeInterval(24 * 60 * 60)
        return Calendar.current.startOfDay(for: mananaMismaHora)
    }

    func fechaTexto() -> String {
        let formato = DateFormatter()
        formato.dateFormat = "yyyy-MM-dd"
        formato.locale = Locale(identifier: "es_MX")
        return formato.string(from: fecha)
    }

    var fechaLarga: String {
        return fecha.formatted(date: .long, time: .omitted)
    }


    func reprogramar() {
        let pedido = ReprogramarRequest(collectionId: visita.id, newDate: fechaTexto())

        Task {
            guardando = true
            do {
                let respuesta = try await api.reprogramar(pedido)
                print("Reprogramada: \(respuesta.scheduledDate)")
                reprogramadaPara = fechaLarga
                mostrarExito = true
            } catch {
                print("Error: \(error)")
                if let errorApi = error as? ApiError {
                    mensajeError = errorApi.mensaje
                } else {
                    mensajeError = "Revisa tu conexión e intenta de nuevo."
                }
                mostrarError = true
            }
            guardando = false
        }
    }
}

#Preview {
    NavigationStack {
        ReprogramarView(
            visita: Recoleccion(id: 1, scheduledDate: "2026-10-16T11:30:00", expectedAmount: 2500,
                                order: 1, status: "FAILED", notes: "No había nadie",
                                donorName: "Nombre de ejemplo", address: "Calle de ejemplo 123"),
            reprogramadaPara: .constant("")
        )
    }
}
