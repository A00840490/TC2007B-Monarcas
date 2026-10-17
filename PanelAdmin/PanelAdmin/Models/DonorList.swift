//
//  DonorList.swift
//  PanelAdmin
//

import Foundation

/// Response of GET /api/adminPanel/donors?months=N
struct DonorList: Codable
{
    var months: Int
    var summary: DonorListSummary
    var donors: [DonorSummary]
    var recolectores: [StaffMember]
}

struct DonorListSummary: Codable
{
    var activeDonors: Int
    var totalDonors: Int
    var donorsWithPledge: Int
    var monthlyCommitted: Double
    var raisedByActive: Double
    var donorsToRecover: Int
}

/// One row of the donor list.
struct DonorSummary: Codable, Identifiable, Hashable
{
    var id: Int
    var name: String
    var phone: String
    /// LOW, MEDIUM or HIGH
    var riskStatus: String
    var isActive: Bool
    var everDonated: Bool
    var hasActivePledge: Bool
    var pledgeAmount: Double?
    /// "YYYY-MM-DD"
    var lastDonationDate: String?
    var lastDonationAmount: Double?
    var daysSinceLastDonation: Int?
    var windowTotal: Double
    /// CASH or TRANSFER
    var paymentMethod: String?
    var recolectorId: Int?
}

struct StaffMember: Codable, Identifiable, Hashable
{
    var id: Int
    var name: String
}
