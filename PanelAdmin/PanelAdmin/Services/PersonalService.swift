//
//  PersonalService.swift
//  PanelAdmin
//

import Foundation
import CaritasAuth

/// Staff performance endpoint of the admin panel. It requires the Admin's token,
/// sent as `Authorization: Bearer <token>`.
class PersonalService
{
    let baseUrl = APIConfig.adminPanelUrl
    
    private let sessionStore: SessionStore
    
    init(sessionStore: SessionStore = SessionStore(key: APIConfig.auth.sessionKey))
    {
        self.sessionStore = sessionStore
    }
    
    /// GET /api/adminPanel/personal?months=N (N is 3, 6 or 12)
    func getPersonal(months: Int) async throws -> PersonalReport {
        guard let token = sessionStore.readToken() else {
            throw DonorServiceError.invalidSession
        }
        
        guard let url = URL(string: baseUrl + "personal?months=\(months)") else {
            print("Invalid URL")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid server response")
            throw URLError(.badServerResponse)
        }
        
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(PersonalReport.self, from: data)
        case 400:
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? ""
            throw DonorServiceError.invalidData(message)
        case 401, 403:
            throw DonorServiceError.invalidSession
        default:
            print("API error code: \(httpResponse.statusCode)")
            print("Body:", String(data: data, encoding: .utf8) ?? "empty")
            throw DonorServiceError.server(httpResponse.statusCode)
        }
    }
}
