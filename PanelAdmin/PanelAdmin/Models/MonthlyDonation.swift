//
//  MonthlyDonation.swift
//  PanelAdmin
//
//  Created by Alumno on 24/09/26.
//

import Foundation

struct MonthlyDonation: Codable, Identifiable
{
    var id: Int
    var month: String
    var amount: Int
}
