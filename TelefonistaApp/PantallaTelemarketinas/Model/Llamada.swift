//
//  Donante.swift
//  PantallaTelemarketinas
//
//  Created by ximena gomez gonzalez on 22/09/26.
//

import Foundation

struct Llamada: Identifiable, Codable {
    let id: Int
    let donante: Donante
    let hora: String
    let estado: String
    let objetivo: String
}
