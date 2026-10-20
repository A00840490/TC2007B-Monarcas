//
//  DonorFollowUps.swift
//  PanelAdmin
//

import Foundation

struct DonorFollowUps: Codable
{
    var days: Int
    var items: [FollowUpItem]
}

struct FollowUpItem: Codable
{
    var kind: String
    var id: Int
    var donorId: Int
    var donorName: String
    var status: String
    var scheduledDate: String
    
    var key: String { kind + "\(id)" }
}
