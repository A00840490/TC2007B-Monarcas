//
//  DashboardDataService.swift
//  PanelAdmin
//
//  Created by Alumno on 24/09/26.
//

import Foundation

class DashboardDataService
{
    let baseUrl = APIConfig.adminPanelUrl
    
    func getDashboardKPIs() async throws -> DashboardKPIs {
        
        guard let url = URL(string: "\(baseUrl)dashboard") else {
            print("Invalid URL")
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
          
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid server response")
            throw URLError(.badServerResponse)
        }
          
        guard httpResponse.statusCode == 200 else {
            print("API error code: \(httpResponse.statusCode)")
            print("Body:", String(data: data, encoding: .utf8) ?? "empty")
            throw URLError(.badServerResponse)
        }
              
        return try JSONDecoder().decode(DashboardKPIs.self, from: data)
    }
    
    func getMonthlyDonations() async throws -> [MonthlyDonation] {
        
        guard let url = URL(string: "\(baseUrl)monthlyDonations") else {
            print("Invalid URL")
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
          
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid server response")
            throw URLError(.badServerResponse)
        }
          
        guard httpResponse.statusCode == 200 else {
            print("API error code: \(httpResponse.statusCode)")
            print("Body:", String(data: data, encoding: .utf8) ?? "empty")
            throw URLError(.badServerResponse)
        }
        
        print("Received JSON:", String(data: data, encoding: .utf8) ?? "no data")
              
        return try JSONDecoder().decode([MonthlyDonation].self, from: data)
    }
}
