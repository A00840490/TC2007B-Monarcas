//
//  DashboardDataService.swift
//  PanelAdmin
//
//  Created by Alumno on 24/09/26.
//

import Foundation
import CaritasAuth

class DashboardDataService
{
    let baseUrl = APIConfig.adminPanelUrl
    
    let sessionStore = SessionStore(key: APIConfig.auth.sessionKey)
    
    func getDashboardKPIs() async throws -> DashboardKPIs {
        try await get("dashboard")
    }
    
    func getMonthlyDonations() async throws -> [MonthlyDonation] {
        try await get("monthlyDonations")
    }
    
    private func get<T: Decodable>(_ path: String) async throws -> T {
        guard let token = sessionStore.readToken() else {
            throw URLError(.userAuthenticationRequired)
        }
        
        guard let url = URL(string: baseUrl + path) else {
            print("Invalid URL")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
          
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid server response")
            throw URLError(.badServerResponse)
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(T.self, from: data)
        case 401, 403:
            throw URLError(.userAuthenticationRequired)
        default:
            print("API error code: \(httpResponse.statusCode)")
            print("Body:", String(data: data, encoding: .utf8) ?? "empty")
            throw URLError(.badServerResponse)
        }
    }
}
