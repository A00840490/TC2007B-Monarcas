//
//  DonorDetail.swift
//  PanelAdmin
//

import Foundation

/// Response of GET /api/adminPanel/donors/{id}?months=N
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
    /// Last 12 months, oldest first.
    var monthlyTotals: [MonthlyTotal]
    var pledge: DonorPledge?
    var upcoming: UpcomingContact?
    /// Newest first.
    var activity: [DonorActivity]
}

struct DonorStats: Codable
{
    var lifetimeTotal: Double
    var windowTotal: Double
    var donationCount: Int
    var firstDonationDate: String?
}

struct MonthlyTotal: Codable, Identifiable
{
    var year: Int
    var month: Int
    var amount: Double
    
    var id: String { "\(year)-\(month)" }
}

/// Main recurring pledge (RecurringDonation).
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
    /// ACTIVE, PAUSED, CANCELLED or FINISHED
    var status: String
    var telefonistaName: String
    var recolectorName: String
}

/// Next PENDING call or collection.
struct UpcomingContact: Codable
{
    /// CALL or COLLECTION
    var kind: String
    /// Call type; nil for collections.
    var type: String?
    var date: String
    var userName: String
}

/// A donation, call or collection of the donor.
struct DonorActivity: Codable
{
    /// DONATION, CALL or COLLECTION
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
    
    /// Unique across kinds (a donation and a call can share an id).
    var key: String { "\(kind)-\(id)" }
}
