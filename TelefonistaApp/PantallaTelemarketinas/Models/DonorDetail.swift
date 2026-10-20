//
//  DonorDetail.swift
//  PantallaTelemarketinas
//
//  Created by Alumno on 17/10/26.
//

import Foundation

struct DonorDetail: Identifiable, Codable {
    let id: Int
    let name: String
    let nickname: String
    let phone: String
    let officePhone: String
    let email: String
    let address: String
    let risk: String
    let campaign: String
    let pledge: Double
    let history: [HistoryItem]
}
