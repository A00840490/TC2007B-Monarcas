//
//  CallService.swift
//  PantallaTelemarketinas
//
//  Created by Alumno on 17/10/26.
//

import Foundation
import CaritasAuth

class CallService {
    let baseUrl = APIConfig.telefonistasUrl
    var sessionExpired = false

    func getProfile() async throws -> UserProfile {
        let request = try makeRequest(urlText: APIConfig.userUrl, method: "POST")
        let data = try await send(request: request)
        return try JSONDecoder().decode(UserProfile.self, from: data)
    }

    func getCalls() async throws -> [Call] {
        let request = try makeRequest(urlText: baseUrl + "calls", method: "GET")
        let data = try await send(request: request)
        return try JSONDecoder().decode([Call].self, from: data)
    }

    func getDonor(id: Int) async throws -> DonorDetail {
        let request = try makeRequest(urlText: baseUrl + "donors/\(id)", method: "GET")
        let data = try await send(request: request)
        return try JSONDecoder().decode(DonorDetail.self, from: data)
    }

    func saveResult(callId: Int, result: CallResultRequest) async throws {
        var request = try makeRequest(urlText: baseUrl + "calls/\(callId)/result", method: "POST")
        request.httpBody = try JSONEncoder().encode(result)
        let _ = try await send(request: request)
    }

    func addNote(donorId: Int, note: String) async throws -> HistoryItem {
        var request = try makeRequest(urlText: baseUrl + "donors/\(donorId)/notes", method: "POST")
        request.httpBody = try JSONEncoder().encode(NoteRequest(note: note))
        let data = try await send(request: request)
        return try JSONDecoder().decode(HistoryItem.self, from: data)
    }

    func makeRequest(urlText: String, method: String) throws -> URLRequest {
        guard let url = URL(string: urlText) else {
            print("URL incorrecto")
            throw URLError(.badURL)
        }

        let token = SessionStore(key: APIConfig.auth.sessionKey).readToken() ?? ""

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    func send(request: URLRequest) async throws -> Data {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("Respuesta no válida del servidor")
            throw URLError(.badServerResponse)
        }

        if httpResponse.statusCode == 401 {
            sessionExpired = true
        }

        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            print("Código de error del API: \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }

        return data
    }
}
