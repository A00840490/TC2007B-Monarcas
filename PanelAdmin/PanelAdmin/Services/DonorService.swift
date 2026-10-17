//
//  DonorService.swift
//  PanelAdmin
//

import Foundation
import CaritasAuth

enum DonorServiceError: Error
{
    /// No token, invalid or expired token (401), or the user is not an Admin (403).
    case invalidSession
    case notFound
    /// The API rejected the data (400); the message comes from the API, in English.
    case invalidData(String)
    case server(Int)
}

/// Donor endpoints of the admin panel. They require the Admin's token, which is
/// sent as `Authorization: Bearer <token>`.
class DonorService
{
    let baseUrl = APIConfig.adminPanelUrl
    
    private let sessionStore: SessionStore
    
    init(sessionStore: SessionStore = SessionStore(key: APIConfig.auth.sessionKey))
    {
        self.sessionStore = sessionStore
    }
    
    /// GET /api/adminPanel/donors?months=N
    func getDonors(months: Int) async throws -> DonorList {
        try await send("donors?months=\(months)")
    }
    
    /// GET /api/adminPanel/donors/{id}?months=N
    func getDonor(id: Int, months: Int) async throws -> DonorDetail {
        try await send("donors/\(id)?months=\(months)")
    }
    
    /// GET /api/adminPanel/staff: who calls and collections can be assigned to.
    func getStaff() async throws -> Staff {
        try await send("staff")
    }
    
    /// POST /api/adminPanel/donors. Returns the new donor's id.
    func createDonor(_ donor: NewDonor) async throws -> Int {
        let created: CreatedRecord = try await send("donors", method: "POST", body: donor)
        return created.id
    }
    
    /// POST /api/adminPanel/calls
    func scheduleCall(_ call: NewPhoneCall) async throws {
        let _: CreatedRecord = try await send("calls", method: "POST", body: call)
    }
    
    /// POST /api/adminPanel/collections
    func scheduleCollection(_ collection: NewCollection) async throws {
        let _: CreatedRecord = try await send("collections", method: "POST", body: collection)
    }
    
    private func send<T: Decodable>(_ path: String, method: String = "GET", body: (any Encodable)? = nil) async throws -> T {
        guard let token = sessionStore.readToken() else {
            throw DonorServiceError.invalidSession
        }
        
        guard let url = URL(string: baseUrl + path) else {
            print("Invalid URL")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid server response")
            throw URLError(.badServerResponse)
        }
        
        switch httpResponse.statusCode {
        case 200, 201:
            return try JSONDecoder().decode(T.self, from: data)
        case 400:
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? ""
            print("API rejected the data: \(message)")
            throw DonorServiceError.invalidData(message)
        case 401, 403:
            throw DonorServiceError.invalidSession
        case 404:
            throw DonorServiceError.notFound
        default:
            print("API error code: \(httpResponse.statusCode)")
            print("Body:", String(data: data, encoding: .utf8) ?? "empty")
            throw DonorServiceError.server(httpResponse.statusCode)
        }
    }
}
