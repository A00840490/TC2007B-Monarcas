//
//  HistoryItem.swift
//  PantallaTelemarketinas
//
//  Created by Alumno on 17/10/26.
//

import Foundation

struct HistoryItem: Identifiable, Codable {
    let id: String
    let status: String
    let result: String
    let date: String
    let hour: String
    let notes: String
    let amount: Double
}
