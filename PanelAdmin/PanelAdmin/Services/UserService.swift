//
//  UserService.swift
//  PanelAdmin
//

import Foundation

enum UserServiceError: Error
{
    case invalidSession
    case server(Int)
}

class UserService
{
    let url = APIConfig.userUrl
    
    func getProfile(token: String) async throws -> UserProfile {
        
        guard let url = URL(string: url) else {
            print("Invalid URL")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["token": token])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid server response")
            throw URLError(.badServerResponse)
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(UserProfile.self, from: data)
        case 401, 404:
            throw UserServiceError.invalidSession
        default:
            print("API error code: \(httpResponse.statusCode)")
            print("Body:", String(data: data, encoding: .utf8) ?? "empty")
            throw UserServiceError.server(httpResponse.statusCode)
        }
    }
}
