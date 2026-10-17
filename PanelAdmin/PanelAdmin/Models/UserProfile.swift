//
//  UserProfile.swift
//  PanelAdmin
//

import Foundation

/// Logged-in user's data returned by POST /api/user.
struct UserProfile: Codable, Equatable
{
    var name: String
    var email: String
    var role: String
}
