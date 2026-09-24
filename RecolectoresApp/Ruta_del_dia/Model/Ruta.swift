//
//  Ruta.swift
//  Ruta_del_dia
//
//  Created by Alumno on 24/09/26.
//

import Foundation

struct RutaRequest {
    var usuarioId: Int
    var fecha: String
}

struct Recoleccion: Codable, Identifiable {
    var id: Int
    var FechaEstimada: String
    var MontoEsperado: Double
    var Orden: Int?
    var Nombre: String
    var Direccion: String
}
