//
//  api.swift
//  Caritas_Login_Screen
//
//  Created by Alumno on 24/09/26.
//

import Foundation

class CaritasApi {
    
    let baseUrl = "http://10.14.255.44:10206/api/";
    
    func getRuta(_ rutaParams: RutaRequest) async throws -> [Recoleccion] {
        
        guard let url = URL(string: "\(baseUrl)recolectoresRuta?usuarioId=\(rutaParams.usuarioId)&fecha=\(rutaParams.fecha)") else {
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
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode([Recoleccion].self, from: data)
        
    }
    
}
