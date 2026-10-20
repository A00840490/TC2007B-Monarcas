//
//  DonorDetail.swift
//  PanelAdmin
//

import Foundation

struct DonorDetail: Codable
{
    var id: Int
    var name: String
    var phone: String
    var address: String
    var riskStatus: String
    var isActive: Bool
    var months: Int
    var stats: DonorStats
    var pledge: DonorPledge?
    var upcoming: UpcomingContact?
    var activity: [DonorActivity]
}

struct DonorStats: Codable
{
    var lifetimeTotal: Double
    var windowTotal: Double
    var donationCount: Int
    var firstDonationDate: String?
}

struct DonorPledge: Codable
{
    var id: Int
    var amount: Double
    var paymentMethod: String
    var campaign: String?
    var frequency: String
    var startDate: String
    var nextInstallmentDate: String
    var endDate: String?
    var status: String
    var telefonistaName: String
    var recolectorName: String
}

struct UpcomingContact: Codable
{
    var kind: String
    var type: String?
    var date: String
    var userName: String
}

struct DonorActivity: Codable
{
    var kind: String
    var id: Int
    var date: String
    var amount: Double?
    var paymentMethod: String?
    var campaign: String?
    var isInstallment: Bool
    var status: String?
    var type: String?
    var userName: String?
    var notes: String?
    
    var key: String { "\(kind)-\(id)" }
}
