//
//  APIConfig.swift
//  PanelAdmin
//

import Foundation
import CaritasAuth

enum APIConfig
{
    static let baseUrl = "https://monarcas.tc2007b.tec.mx:10206/api/"
    static let adminPanelUrl = baseUrl + "adminPanel/"
    static let userUrl = baseUrl + "user"
    
    static let auth = AuthConfiguration(
        apiBaseUrl: baseUrl,
        role: "Admin"
    )
}
