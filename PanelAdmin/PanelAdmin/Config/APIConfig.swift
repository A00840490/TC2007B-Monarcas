//
//  APIConfig.swift
//  PanelAdmin
//

import Foundation
import CaritasAuth

enum APIConfig
{
    static let baseUrl = "https://10.14.255.44:10206/api/"
    // Endpoints exclusive to the admin panel.
    static let adminPanelUrl = baseUrl + "adminPanel/"
    // Logged-in user's profile.
    static let userUrl = baseUrl + "user"
    
    // Shared login (CaritasAuth package). It also provides the Keychain key
    // where the session token lives.
    static let auth = AuthConfiguration(
        apiBaseUrl: baseUrl,
        role: "Admin"
    )
}
