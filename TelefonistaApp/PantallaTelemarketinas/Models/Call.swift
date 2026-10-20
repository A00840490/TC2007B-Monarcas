//
//  Call.swift
//  PantallaTelemarketinas
//
//  Created by Alumno on 17/10/26.
//

import Foundation

struct Call: Identifiable, Codable {
    let id: Int
    let time: String
    let hour: String
    let status: String
    let state: String
    let result: String
    let goal: String
    let donor: CallDonor
}
