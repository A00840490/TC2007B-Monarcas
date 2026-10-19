//
//  Ruta.swift
//  Ruta_del_dia
//
//  Created by Alumno on 24/09/26.
//

import Foundation

struct Recoleccion: Codable, Identifiable {
    var id: Int
    var scheduledDate: String
    var expectedAmount: Double
    var order: Int?
    var status: String
    var receivedAmount: Double?
    var notes: String?
    var donorName: String
    var address: String

    var estadoTexto: String {
        if status == "SUCCESSFUL" {
            return "Exitosa"
        } else if status == "FAILED" {
            return "Fallida"
        } else {
            return "Pendiente"
        }
    }
}

struct ResultadoRequest: Codable {
    var collectionId: Int
    var status: String
    var receivedAmount: Double?
    var notes: String?
}

struct ResultadoRespuesta: Codable {
    var id: Int
    var status: String
    var receivedAmount: Double?
    var notes: String?
}

struct ResumenDia: Codable {
    var date: String
    var totalVisits: Int
    var successful: Int
    var failed: Int
    var pending: Int
    var expectedAmount: Double
    var receivedAmount: Double
}

struct DonacionHistorial: Codable, Identifiable {
    var id: Int
    var donationDate: String
    var totalAmount: Double
    var paymentMethod: String

    var metodoTexto: String {
        if paymentMethod == "CASH" {
            return "Efectivo"
        } else if paymentMethod == "TRANSFER" {
            return "Transferencia"
        } else {
            return paymentMethod
        }
    }
}

struct ReprogramarRequest: Codable {
    var collectionId: Int
    var newDate: String
}

struct ReprogramarRespuesta: Codable {
    var id: Int
    var status: String
    var scheduledDate: String
}
