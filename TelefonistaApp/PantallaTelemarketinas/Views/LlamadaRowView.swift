//
//  LlamadaRowView.swift
//  PantallaTelemarketinas
//
//  Created by ximena gomez gonzalez on 22/09/26.
//

import SwiftUI

struct LlamadaRowView: View {
    var llamada: Llamada

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(llamada.hora)
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))
                Text(llamada.donante.nombre)
            }
            Spacer()
            Text(llamada.estado)
                .font(.system(size: 12))
                .foregroundColor(Color(red: 142/255, green: 142/255, blue: 147/255))
        }
    }
}

#Preview {
    let donantePrueba = Donante(
        id: 1,
        nombre: "Ana Martínez",
        telefono: "•••• 4821",
        promesa: "Apoyo Cáncer Infantil",
        caso: "Salud Infantil",
        riesgo: "Riesgo medio",
        ultimoContacto: "14 de agosto"
    )
    let llamadaPrueba = Llamada(id: 1, donante: donantePrueba, hora: "10:45 AM", estado: "Próxima", objetivo: "Confirmar renovación")
    LlamadaRowView(llamada: llamadaPrueba)
}
