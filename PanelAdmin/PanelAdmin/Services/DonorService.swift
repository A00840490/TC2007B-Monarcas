//
//  DonorService.swift
//  PanelAdmin
//

import Foundation
import CaritasAuth

enum DonorServiceError: Error
{
    case invalidSession
    case notFound
    case invalidData(String)
    case server(Int)
}

class DonorService
{
    let baseUrl = APIConfig.adminPanelUrl
    let sessionStore = SessionStore(key: APIConfig.auth.sessionKey)
    
    func getDonors(months: Int) async throws -> DonorList {
        try await send("donors?months=\(months)")
    }
    
    func getDonor(id: Int, months: Int) async throws -> DonorDetail {
        try await send("donors/\(id)?months=\(months)")
    }
    
    func getAgenda(days: Int) async throws -> DonorAgenda {
        try await send("agenda?days=\(days)")
    }
    
    func getFollowUps() async throws -> DonorFollowUps {
        try await send("followUps")
    }
    
    func getDonorFilters() async throws -> DonorFilters {
        try await send("donorFilters")
    }
    
    func createDonor(_ donor: NewDonor) async throws -> Int {
        let body = try JSONEncoder().encode(donor)
        let created: CreatedRecord = try await send("donors", method: "POST", body: body)
        return created.id
    }
    
    func scheduleCall(_ call: NewPhoneCall) async throws {
        let body = try JSONEncoder().encode(call)
        let _: CreatedRecord = try await send("calls", method: "POST", body: body)
    }
    
    func scheduleCollection(_ collection: NewCollection) async throws {
        let body = try JSONEncoder().encode(collection)
        let _: CreatedRecord = try await send("collections", method: "POST", body: body)
    }
    
    private func send<T: Decodable>(_ path: String, method: String = "GET", body: Data? = nil) async throws -> T {
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
            request.httpBody = body
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
            let message = String(data: data, encoding: .utf8) ?? ""
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
