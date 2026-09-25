//
//  Turno.swift
//  PantallaTelemarketinas
//
//  Created by ximena gomez gonzalez on 23/09/26.
//Mas que nada necesario solo para el total de llamadas y su progress bar

import SwiftUI

struct Turno: Identifiable {
    let id: Int
    let telefonista: String
    let nombreTurno: String
    let totalAsignadas: Int
}
