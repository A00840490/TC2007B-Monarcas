//
//  ResultadoView.swift
//  Ruta_del_dia
//
//  Created by Alumno on 19/10/26.
//

import SwiftUI

struct ResultadoView: View {
    
    var visita: Recoleccion

    let api = CaritasApi()
    let limiteMotivo = 1000

    @Environment(\.dismiss) private var dismiss
    @FocusState private var campoEnFoco: Bool

    @State private var opcion = 1
    @State private var montoTexto = ""
    @State private var motivo = ""
    @State private var guardando = false
    @State private var mostrarError = false
    @State private var mensajeError = ""
    @State private var mostrarExito = false

    @State private var historial: [DonacionHistorial] = []
    @State private var cargandoHistorial = false
    @State private var errorHistorial = false

    @State private var reprogramadaPara = ""

    var body: some View {
        ZStack {
            fondoPantalla.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    Text("Registrar resultado")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(tealOscuro)


                    VisitaCardView(visita: visita, esProxima: false, mostrarFlecha: false)

                    if yaRegistrada {
                        resultadoRegistrado
                    } else {
                        formulario
                    }

                    historialCard
                }
                .padding()
            }
            .alert("Resultado guardado", isPresented: $mostrarExito) {
                Button("OK") {
                    dismiss()
                }
            }
        }
        .onTapGesture {
            campoEnFoco = false
        }
        .onAppear {
            cargarHistorial()
        }
        .alert("No se pudo guardar el resultado", isPresented: $mostrarError) {
            Button("Reintentar") {
                guardar()
            }
            Button("Cancelar") {}
        } message: {
            Text(mensajeError)
        }
    }

    var formulario: some View {
        VStack(alignment: .leading, spacing: 16) {

            Text("¿Cómo salió la visita?")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(tealOscuro)

            Picker(selection: $opcion, label: Text("Resultado")) {
                Text("Exitosa").tag(1)
                Text("Fallida").tag(2)
            }
            .pickerStyle(.segmented)

            if opcion == 1 {
                campoMonto
            } else {
                campoMotivo
            }

            Button(action: guardar) {
                if guardando {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                } else {
                    Text("Guardar resultado")
                        .font(.system(size: 17, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(tealCaritas)
            .disabled(!formularioValido || guardando)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var campoMonto: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MONTO RECIBIDO (MXN)")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(tealTexto)

            TextField("Ej. 2500", text: $montoTexto)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
                .focused($campoEnFoco)

            if montoTexto.isEmpty {
                mensaje("Escribe el monto que entregó el donante.", tealTexto)
            } else if !montoValido {
                mensaje("Escribe un monto válido, mayor a 0.", rojoEstado)
            }
        }
    }

    var campoMotivo: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MOTIVO")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(tealTexto)

            TextField("Ej. No había nadie en el domicilio", text: $motivo)
                .textFieldStyle(.roundedBorder)
                .focused($campoEnFoco)

            HStack(alignment: .top) {
                if motivo.count > limiteMotivo {
                    mensaje("El motivo no puede pasar de \(limiteMotivo) caracteres.", rojoEstado)
                } else if motivo.isEmpty {
                    mensaje("Cuéntanos por qué no se pudo recolectar.", tealTexto)
                } else if !motivoValido {
                    mensaje("El motivo es obligatorio.", rojoEstado)
                }
                Spacer()
                Text("\(motivo.count)/\(limiteMotivo)")
                    .font(.system(size: 12))
                    .foregroundStyle(tealTexto)
            }
        }
    }

    var resultadoRegistrado: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Esta visita ya fue registrada")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(tealOscuro)

            if visita.estadoTexto == "Exitosa", let recibido = visita.receivedAmount {
                Text("Resultado: Exitosa, $\(recibido.formatted(.number.precision(.fractionLength(0...2)))) MXN")
                    .font(.system(size: 15))
                    .foregroundStyle(tealTexto)
            } else {
                Text("Resultado: \(visita.estadoTexto)")
                    .font(.system(size: 15))
                    .foregroundStyle(tealTexto)
            }

            if visita.estadoTexto == "Fallida" {
                if let motivoGuardado = visita.notes {
                    Text("Motivo: \(motivoGuardado)")
                        .font(.system(size: 15))
                        .foregroundStyle(tealTexto)
                }

                if reprogramadaPara.isEmpty {
                    NavigationLink {
                        ReprogramarView(visita: visita, reprogramadaPara: $reprogramadaPara)
                    } label: {
                        Text("Reprogramar visita")
                            .font(.system(size: 17, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(tealCaritas)
                } else {
                    mensaje("Visita reprogramada para el \(reprogramadaPara).", verdeEstado)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    var historialCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Últimas donaciones del donante")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(tealOscuro)

            if cargandoHistorial {
                ProgressView()
            } else if errorHistorial {
                mensaje("No se pudo cargar el historial.", rojoEstado)
            } else if historial.isEmpty {
                mensaje("Este donante aún no tiene donaciones.", tealTexto)
            } else {
                ForEach(historial) { donacion in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(fechaDonacion(donacion.donationDate))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(tealOscuro)
                            Text(donacion.metodoTexto)
                                .font(.system(size: 13))
                                .foregroundStyle(tealTexto)
                        }
                        Spacer()
                        Text("$\(donacion.totalAmount.formatted(.number.precision(.fractionLength(0...2)))) MXN")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(tealCaritas)
                    }
                    Divider()
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    func mensaje(_ texto: String, _ color: Color) -> some View {
        Text(texto)
            .font(.system(size: 13))
            .foregroundStyle(color)
    }

    var yaRegistrada: Bool {
        return visita.estadoTexto != "Pendiente"
    }

    var monto: Double? {
        return Double(montoTexto)
    }

    var montoValido: Bool {
        if let valor = monto {
            return valor > 0
        } else {
            return false
        }
    }

    var motivoLimpio: String {
        return motivo.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var motivoValido: Bool {
        return !motivoLimpio.isEmpty
    }

    var formularioValido: Bool {
        if opcion == 1 {
            return montoValido
        } else {
            return motivoValido && motivo.count <= limiteMotivo
        }
    }


    func guardar() {
        campoEnFoco = false

        let pedido: ResultadoRequest
        if opcion == 1 {
            pedido = ResultadoRequest(collectionId: visita.id, status: "SUCCESSFUL",
                                      receivedAmount: monto)
        } else {
            pedido = ResultadoRequest(collectionId: visita.id, status: "FAILED",
                                      notes: motivoLimpio)
        }

        Task {
            guardando = true
            do {
                let respuesta = try await api.registrarResultado(pedido)
                print("Guardado: \(respuesta.status)")
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


    func fechaDonacion(_ texto: String) -> String {
        let formatoEntrada = DateFormatter()
        formatoEntrada.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatoEntrada.locale = Locale(identifier: "en_US")

        let formatoSalida = DateFormatter()
        formatoSalida.dateFormat = "dd MMM yyyy"
        formatoSalida.locale = Locale(identifier: "es_MX")

        if let fecha = formatoEntrada.date(from: texto) {
            return formatoSalida.string(from: fecha)
        } else {
            return texto
        }
    }

    func cargarHistorial() {
        Task {
            cargandoHistorial = true
            errorHistorial = false
            do {
                historial = try await api.getHistorial(collectionId: visita.id)
            } catch {
                print("Error en el historial: \(error)")
                historial = []
                errorHistorial = true
            }
            cargandoHistorial = false
        }
    }
}

#Preview {
    NavigationStack {
        ResultadoView(
            visita: Recoleccion(id: 1, scheduledDate: "2026-10-16T11:30:00", expectedAmount: 2500,
                                order: 1, status: "PENDING", donorName: "Nombre de ejemplo",
                                address: "Calle de ejemplo 123")
        )
    }
}
