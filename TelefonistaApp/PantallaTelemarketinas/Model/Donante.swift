//
//  Donante.swift
//  PantallaTelemarketinas
//
//  Created by ximena gomez gonzalez on 22/09/26.
//

import Foundation

struct Donante: Identifiable, Codable {
    let id: Int
    let nombre: String
    let telefono: String
    let promesa: String
    let caso: String
    let riesgo: String
    let ultimoContacto: String
}
