//
//  BienvenidaView.swift
//  PantallaTelemarketinas
//
//  Created by ximena gomez gonzalez on 22/09/26.
//

import SwiftUI

struct BienvenidaView: View {
    @Binding var selectedTab: String

    let servicio = LlamadasService()
    let turno = LlamadasService().obtenerTurno()

    @State private var llamadas: [Llamada] = []

    var body: some View {
        VStack {
            Spacer()

            Image(systemName: "cross.fill")
                .font(.system(size: 30))
                .foregroundColor(.white)
                .frame(width: 64, height: 64)
                .background(Constants.primaryColor)
                .padding(.bottom, 4)

            Text("Jueves 3 de septiembre · \(turno.nombreTurno)")
                .font(.system(size: 12))
                .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))
                .padding(.bottom, 4)

            Text("Buenos días, \(turno.telefonista)")
                .font(.system(size: 26))
                .padding(.bottom, 12)

            HStack {
                VStack {
                    Text("\(llamadas.count)")
                        .font(.system(size: 22))
                    Text("Asignadas")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))
                }
                .padding()
                .frame(minWidth: 90)
                .background(Color(red: 240/255, green: 240/255, blue: 240/255))
                .padding(.trailing, 8)

                VStack {
                    Text("6")
                        .font(.system(size: 22))
                    Text("Próximas 1h")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))
                }
                .padding()
                .frame(minWidth: 90)
                .background(Color(red: 240/255, green: 240/255, blue: 240/255))
                .padding(.trailing, 8)

                VStack {
                    Text("3")
                        .font(.system(size: 22))
                    Text("Vencidas")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))
                }
                .padding()
                .frame(minWidth: 90)
                .background(Color(red: 240/255, green: 240/255, blue: 240/255))
            }
            .padding(.bottom, 20)

            Button("Iniciar turno") {
                selectedTab = "Turno"
            }
            .buttonStyle(.borderedProminent)
            .tint(Constants.primaryColor)

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    BienvenidaView(selectedTab: .constant("Inicio"))
}
