//
//  DonorRequests.swift
//  PanelAdmin
//

import Foundation

struct NewDonor: Encodable
{
    var name: String
    var phone: String
    var address: String
    var riskStatus: String
}

struct NewPhoneCall: Encodable
{
    var donorId: Int
    var telefonistaId: Int
    var scheduledDate: String
    var notes: String?
}

struct NewCollection: Encodable
{
    var donorId: Int
    var recolectorId: Int
    var scheduledDate: String
    var expectedAmount: Double?
    var notes: String?
}

struct CreatedRecord: Decodable
{
    var id: Int
}
