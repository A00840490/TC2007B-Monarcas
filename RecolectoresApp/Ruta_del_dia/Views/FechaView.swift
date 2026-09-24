//
//  FechaView.swift
//  Ruta_del_dia
//
//  Created by Alumno on 24/09/26.
//

import SwiftUI

struct FechaView: View {

    @Binding var fecha: Date

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            fondoPantalla.ignoresSafeArea()

            VStack(spacing: 16) {
                Text("Elige la fecha de la ruta")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(tealOscuro)

                DatePicker("Fecha de la ruta", selection: $fecha, displayedComponents: [.date])
                    .datePickerStyle(.graphical)
                    .tint(tealCaritas)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))

                Button("Listo") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(tealCaritas)

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    FechaView(fecha: .constant(Date()))
}
