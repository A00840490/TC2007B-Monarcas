//
//  TurnoActivoView.swift
//  PantallaTelemarketinas
//
//  Created by ximena gomez gonzalez on 22/09/26.
//

import SwiftUI

struct TurnoActivoView: View {
    let servicio = LlamadasService()
    let turno = LlamadasService().obtenerTurno()

    @State private var llamadas: [Llamada] = []
    @State private var i = 0
    @State private var llamadaIniciada = false
    @State private var horaInicio = ""
    @State private var horaFin = ""
    @State private var contesto = "No contestó"
    @State private var agendo = "No agendó"
    @State private var fechaAgendada = Date()
    @State private var nota = ""

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading) {

                VStack(alignment: .leading) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Buenos días, \(turno.telefonista)")
                                .font(.system(size: 18))
                            Text(turno.nombreTurno)
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))
                        }
                        Spacer()
                        Text("\(i + 1) / \(llamadas.count)")
                            .font(.system(size: 12))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color(red: 210/255, green: 235/255, blue: 238/255))
                    }
                    .padding(.bottom, 8)

                    if llamadas.isEmpty == false {
                        ProgressView(value: Double(i + 1), total: Double(llamadas.count))
                            .tint(Constants.primaryColor)
                            .padding(.bottom, 16)
                    }

                    if llamadas.isEmpty == false {
                        HStack {
                            Button(action: {
                                if i > 0 {
                                    i -= 1
                                }
                            }) {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.system(size: 24))
                                    .padding(6)
                            }

                            Text("Llamada \(i + 1) de \(llamadas.count)")
                                .font(.system(size: 12))
                                .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))

                            Button(action: {
                                if i < llamadas.count - 1 {
                                    i += 1
                                }
                            }) {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.system(size: 24))
                                    .padding(6)
                            }
                        }
                        .padding(.bottom, 4)

                        Text(llamadas[i].donante.nombre)
                            .font(.system(size: 22))
                        Text(llamadas[i].donante.promesa)
                            .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))

                        let colorRiesgo: Color = {
                            if llamadas[i].donante.riesgo == "Bajo" {
                                return Color(red: 205/255, green: 235/255, blue: 210/255)
                            } else if llamadas[i].donante.riesgo == "Alto" {
                                return Color(red: 250/255, green: 205/255, blue: 205/255)
                            } else {
                                return Color(red: 250/255, green: 230/255, blue: 180/255)
                            }
                        }()

                        Text(llamadas[i].donante.riesgo)
                            .font(.system(size: 12))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(colorRiesgo)
                            .padding(.top, 4)
                    } else {
                        Text("Cargando llamadas...")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))
                    }

                    if llamadaIniciada == false {
                        Button("Comenzar llamada") {
                            let formato = DateFormatter()
                            formato.timeStyle = .short
                            formato.dateStyle = .none
                            horaInicio = formato.string(from: Date())
                            llamadaIniciada = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Constants.primaryColor)
                        .padding(.top, 12)
                    } else {
                        Text("Llamada iniciada: \(horaInicio)")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))
                            .padding(.top, 12)
                    }
                }
                .padding()
                .background(Color(red: 240/255, green: 240/255, blue: 240/255))

                VStack(alignment: .leading) {
                    Text("Registro de la llamada")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))
                        .padding(.bottom, 8)

                    Picker(selection: $contesto, label: Text("¿Contestó?")) {
                        Text("Contestó").tag("Contestó")
                        Text("No contestó").tag("No contestó")
                    }
                    .pickerStyle(.segmented)

                    Picker(selection: $agendo, label: Text("¿Agendó?")) {
                        Text("Agendó").tag("Agendó")
                        Text("No agendó").tag("No agendó")
                    }
                    .pickerStyle(.segmented)
                    .padding(.top, 8)

                    if agendo == "Agendó" {
                        DatePicker("Fecha de recolección", selection: $fechaAgendada)
                            .padding(.top, 8)
                    }

                    TextField("Nota de la llamada", text: $nota)
                        .textFieldStyle(.roundedBorder)
                        .padding(.top, 8)

                    if llamadaIniciada {
                        Button("Terminar llamada") {
                            let formato = DateFormatter()
                            formato.timeStyle = .short
                            formato.dateStyle = .none
                            horaFin = formato.string(from: Date())
                            llamadaIniciada = false
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Constants.primaryColor)
                        .padding(.top, 12)
                    }
                }
                .padding()
                .background(Color(red: 240/255, green: 240/255, blue: 240/255))
                .padding(.top, 12)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading) {
                Text("Cola del turno")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))
                    .padding(.bottom, 4)

                List(llamadas) { llamadaItem in
                    LlamadaRowView(llamada: llamadaItem)
                }
                .listStyle(.inset)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(red: 235/255, green: 246/255, blue: 250/255))
        .onAppear {
            Task {
                do {
                    llamadas = try await servicio.obtenerLlamadas()
                } catch {
                    print("Error: \(error)")
                }
            }
        }
    }
}

#Preview {
    TurnoActivoView()
}
