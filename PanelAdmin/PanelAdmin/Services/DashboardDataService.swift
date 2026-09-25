//
//  DashboardDataService.swift
//  PanelAdmin
//
//  Created by Alumno on 24/09/26.
//

import Foundation

class DashboardDataService
{
    let urlBase = "http://10.14.255.44:10206/api/"
    
    func getDashboardKPIs() async throws -> DashboardKPIs {
        
        guard let url = URL(string: "\(urlBase)dashboarddata") else {
            print("URL incorrecto")
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
          
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Respuesta no válida del servidor")
            throw URLError(.badServerResponse)
        }
          
        guard httpResponse.statusCode == 200 else {
            print("Código de error del API: \(httpResponse.statusCode)")
            print("Cuerpo:", String(data: data, encoding: .utf8) ?? "vacío")
            throw URLError(.badServerResponse)
        }
              
        return try JSONDecoder().decode(DashboardKPIs.self, from: data)
    }
    
    func getDonacionesMeses() async throws -> [DonacionesMeses] {
        
        guard let url = URL(string: "\(urlBase)donacionesmeses") else {
            print("URL incorrecto")
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
          
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Respuesta no válida del servidor")
            throw URLError(.badServerResponse)
        }
          
        guard httpResponse.statusCode == 200 else {
            print("Código de error del API: \(httpResponse.statusCode)")
            print("Cuerpo:", String(data: data, encoding: .utf8) ?? "vacío")
            throw URLError(.badServerResponse)
        }
        
        print("JSON recibido:", String(data: data, encoding: .utf8) ?? "sin datos")
              
        return try JSONDecoder().decode([DonacionesMeses].self, from: data)
    }
}
