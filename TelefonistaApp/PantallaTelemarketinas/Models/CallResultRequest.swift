//
//  CallResultRequest.swift
//  PantallaTelemarketinas
//
//  Created by Alumno on 17/10/26.
//

import Foundation

struct CallResultRequest: Codable {
    let result: String
    let notes: String
    let calledAt: String
    let amount: Double
    let collectionDate: String
    let rescheduleDate: String
}
