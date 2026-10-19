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
    var mostrarFlecha = true

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                circuloOrden
                Text(hora)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(tealOscuro)
                etiqueta(textoBadge, colorBadge, fondoBadge)
                Spacer()
                if mostrarFlecha {
                    if esProxima {
                        Text("Próxima ›")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(tealCaritas)
                    } else {
                        Image(systemName: "chevron.right")
                            .foregroundStyle(tealTexto)
                    }
                }
            }

            Text(visita.donorName)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(tealOscuro)

            Label(visita.address, systemImage: "mappin.circle")
                .font(.system(size: 14))
                .foregroundStyle(tealTexto)

            Divider()

            HStack(alignment: .bottom) {
                if visita.estadoTexto == "Exitosa", let recibido = visita.receivedAmount {
                    Text("$\(recibido.formatted(.number.precision(.fractionLength(0...2)))) MXN")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(verdeEstado)
                } else {
                    Text("$\(visita.expectedAmount.formatted(.number.precision(.fractionLength(0)))) MXN")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(tealOscuro)
                }
                Spacer()
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }


    var circuloOrden: some View {
        ZStack {
            if let orden = visita.order {
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

        if let fecha = formatoEntrada.date(from: visita.scheduledDate) {
            return formatoSalida.string(from: fecha)
        } else {
            return ""
        }
    }

    var textoBadge: String {
        if visita.estadoTexto == "Exitosa" {
            return "EXITOSA"
        } else if visita.estadoTexto == "Fallida" {
            return "FALLIDA"
        } else if esProxima {
            return "EN RUTA"
        } else {
            return "PENDIENTE"
        }
    }

    var colorBadge: Color {
        if visita.estadoTexto == "Exitosa" {
            return verdeEstado
        } else if visita.estadoTexto == "Fallida" {
            return rojoEstado
        } else if esProxima {
            return tealCaritas
        } else {
            return naranjaEstado
        }
    }

    var fondoBadge: Color {
        if visita.estadoTexto == "Exitosa" {
            return verdeSuave
        } else if visita.estadoTexto == "Fallida" {
            return rojoSuave
        } else if esProxima {
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
            visita: Recoleccion(id: 1, scheduledDate: "2026-10-16T11:30:00", expectedAmount: 2500,
                                order: 1, status: "PENDING", donorName: "Nombre de ejemplo",
                                address: "Calle de ejemplo 123"),
            esProxima: true
        )
        .padding()
    }
}
