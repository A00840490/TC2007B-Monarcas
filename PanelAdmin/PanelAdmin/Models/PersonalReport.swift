//
//  PersonalReport.swift
//  PanelAdmin
//

import Foundation

struct PersonalReport: Codable
{
    var months: Int
    var summary: PersonalSummary
    var telefonistas: [TelefonistaPerformance]
    var recolectores: [RecolectorPerformance]
}

struct PersonalSummary: Codable
{
    var activeTelefonistas: Int
    var totalCalls: Int
    var confirmedCalls: Int
    var confirmationRate: Int
    var activeRecolectores: Int
    var totalCollections: Int
    var successfulCollections: Int
    var successRate: Int
    var amountCollected: Double
}

struct TelefonistaPerformance: Codable, Identifiable, Hashable
{
    var id: Int
    var name: String
    var totalCalls: Int
    var confirmedCalls: Int
    var confirmationRate: Int
}

struct RecolectorPerformance: Codable, Identifiable, Hashable
{
    var id: Int
    var name: String
    var totalCollections: Int
    var successfulCollections: Int
    var successRate: Int
    var amountCollected: Double
}
