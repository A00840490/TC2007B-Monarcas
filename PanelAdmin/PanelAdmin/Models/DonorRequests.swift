//
//  DonorRequests.swift
//  PanelAdmin
//

import Foundation

/// Body of POST /api/adminPanel/donors
struct NewDonor: Encodable
{
    var name: String
    var phone: String
    var address: String
    /// LOW, MEDIUM or HIGH
    var riskStatus: String
}

/// Body of POST /api/adminPanel/calls
struct NewPhoneCall: Encodable
{
    var donorId: Int
    var telefonistaId: Int
    /// "yyyy-MM-dd'T'HH:mm:ss", local time
    var scheduledDate: String
    var notes: String?
}

/// Body of POST /api/adminPanel/collections
struct NewCollection: Encodable
{
    var donorId: Int
    var recolectorId: Int
    /// "yyyy-MM-dd'T'HH:mm:ss", local time
    var scheduledDate: String
    var expectedAmount: Double?
    var notes: String?
}

/// What the create endpoints answer with (only the new id is used).
struct CreatedRecord: Decodable
{
    var id: Int
}

/// Response of GET /api/adminPanel/staff
struct Staff: Decodable
{
    var telefonistas: [StaffMember]
    var recolectores: [StaffMember]
}
