//
//  DonorAgenda.swift
//  PanelAdmin
//

import Foundation

struct DonorAgenda: Codable
{
    var days: Int
    var items: [AgendaItem]
}

struct AgendaItem: Codable
{
    var kind: String
    var id: Int
    var donorId: Int
    var donorName: String
    var scheduledDate: String
    var isOverdue: Bool
    
    var key: String { kind + "\(id)" }
}
