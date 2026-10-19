//
//  UserService.swift
//  Ruta_del_dia
//
//  Creado por Alumno el 19/10/2026
//

import Foundation

enum UserServiceError: Error {
    case sesionInvalida
    case servidor(Int)
}

class UserService {

    let url = APIConfig.userUrl

    func getProfile(token: String) async throws -> UserProfile {

        guard let url = URL(string: url) else {
            print("URL incorrecto")
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["token": token])

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("Respuesta no válida del servidor")
            throw URLError(.badServerResponse)
        }

        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(UserProfile.self, from: data)
        case 401, 404:
            throw UserServiceError.sesionInvalida
        default:
            print("Código del API: \(httpResponse.statusCode)")
            throw UserServiceError.servidor(httpResponse.statusCode)
        }
    }
}
