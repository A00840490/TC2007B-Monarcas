//
//  DonorFilters.swift
//  PanelAdmin
//

import Foundation

struct DonorFilters: Codable
{
    var telefonistas: [AssignedStaff]
    var recolectores: [AssignedStaff]
}

struct AssignedStaff: Codable, Identifiable
{
    var id: Int
    var name: String
    var donorCount: Int
}
