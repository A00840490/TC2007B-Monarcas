//
//  VisitaCardView.swift
//  Ruta_del_dia
//
//  Created by Alumno on 24/09/26.
//

import SwiftUI

struct VisitaCardView: View {
    var visita: Recoleccion
    var esProxima: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                circuloOrden
                Text(hora)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(tealOscuro)
                etiqueta(textoBadge, colorBadge, fondoBadge)
                Spacer()
                if esProxima {
                    Text("Próxima ›")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(tealCaritas)
                } else {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(tealTexto)
                }
            }

            Text(visita.Nombre)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(tealOscuro)

            Label(visita.Direccion, systemImage: "mappin.circle")
                .font(.system(size: 14))
                .foregroundStyle(tealTexto)

            Divider()

            HStack(alignment: .bottom) {
                Text("$\(visita.MontoEsperado.formatted(.number.precision(.fractionLength(0)))) MXN")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(tealOscuro)
                Spacer()
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }


    var circuloOrden: some View {
        ZStack {
            if let orden = visita.Orden {
                Text("\(orden)")
                    .foregroundStyle(colorNumero)
            } else {
                Text("-")
                    .foregroundStyle(colorNumero)
            }
        }
        .font(.system(size: 13, weight: .bold))
        .frame(width: 26, height: 26)
        .background(colorCirculo)
        .clipShape(.circle)
    }

    func etiqueta(_ texto: String, _ color: Color, _ fondo: Color) -> some View {
        Text(texto)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(color)
            .padding(6)
            .background(fondo)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    var hora: String {
        let formatoEntrada = DateFormatter()
        formatoEntrada.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatoEntrada.locale = Locale(identifier: "en_US")

        let formatoSalida = DateFormatter()
        formatoSalida.dateFormat = "hh:mm a"
        formatoSalida.locale = Locale(identifier: "en_US")

        if let fecha = formatoEntrada.date(from: visita.FechaEstimada) {
            return formatoSalida.string(from: fecha)
        } else {
            return ""
        }
    }

    var textoBadge: String {
        if esProxima {
            return "EN RUTA"
        } else {
            return "PENDIENTE"
        }
    }

    var colorBadge: Color {
        if esProxima {
            return tealCaritas
        } else {
            return naranjaEstado
        }
    }

    var fondoBadge: Color {
        if esProxima {
            return tealSuave
        } else {
            return naranjaSuave
        }
    }

    var colorCirculo: Color {
        if esProxima {
            return tealCaritas
        } else {
            return tealSuave
        }
    }

    var colorNumero: Color {
        if esProxima {
            return Color.white
        } else {
            return tealTexto
        }
    }
}

#Preview {
    NavigationStack {
        VisitaCardView(
            visita: Recoleccion(id: 1, FechaEstimada: "2026-09-24T11:30:00", MontoEsperado: 2500,
                                Orden: 1, Nombre: "Nombre de ejemplo",
                                Direccion: "Calle de ejemplo 123"),
            esProxima: true
        )
        .padding()
    }
}
