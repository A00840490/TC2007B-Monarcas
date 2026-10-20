//
//  DonorList.swift
//  PanelAdmin
//

import Foundation

struct DonorList: Codable
{
    var months: Int
    var summary: DonorListSummary
    var donors: [DonorSummary]
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

struct DonorSummary: Codable, Identifiable, Hashable
{
    var id: Int
    var name: String
    var phone: String
    var riskStatus: String
    var isActive: Bool
    var everDonated: Bool
    var hasActivePledge: Bool
    var pledgeAmount: Double?
    var lastDonationDate: String?
    var lastDonationAmount: Double?
    var daysSinceLastDonation: Int?
    var windowTotal: Double
    var paymentMethod: String?
    var recolectorId: Int?
    var telefonistaId: Int?
}
