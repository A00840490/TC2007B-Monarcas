//
//  PersonalReport.swift
//  PanelAdmin
//

import Foundation

/// Response of GET /api/adminPanel/personal?months=N
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
    /// Percentage, 0-100
    var confirmationRate: Int
    var activeRecolectores: Int
    var totalCollections: Int
    var successfulCollections: Int
    /// Percentage, 0-100
    var successRate: Int
    var amountCollected: Double
}

/// One telefonista's calls in the selected window.
struct TelefonistaPerformance: Codable, Identifiable, Hashable
{
    var id: Int
    var name: String
    var totalCalls: Int
    var confirmedCalls: Int
    /// Percentage, 0-100
    var confirmationRate: Int
}

/// One recolector's collections in the selected window.
struct RecolectorPerformance: Codable, Identifiable, Hashable
{
    var id: Int
    var name: String
    var totalCollections: Int
    var successfulCollections: Int
    /// Percentage, 0-100
    var successRate: Int
    var amountCollected: Double
}

