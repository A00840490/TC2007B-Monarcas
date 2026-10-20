//
//  CallDonor.swift
//  PantallaTelemarketinas
//
//  Created by Alumno on 17/10/26.
//

import Foundation

struct CallDonor: Identifiable, Codable {
    let id: Int
    let name: String
    let nickname: String
    let phone: String
    let campaign: String
    let risk: String
    let pledge: Double
}
