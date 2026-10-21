//
//  api.swift
//  Ruta_del_dia
//
//  Created by Alumno on 24/09/26.
//

import Foundation
import CaritasAuth

enum ApiError: Error {
    case sesionExpirada
    case noPermitido
    case noExiste
    case yaRegistrada
    case noReprogramable
    case datosInvalidos
    case servidor

    var mensaje: String {
        switch self {
        case .sesionExpirada:
            return "Tu sesión expiró. Cierra sesión y vuelve a entrar."
        case .noPermitido:
            return "Esta visita no está asignada a ti."
        case .noExiste:
            return "La visita no existe."
        case .yaRegistrada:
            return "Esta visita ya tiene un resultado registrado."
        case .noReprogramable:
            return "Solo se pueden reprogramar las visitas fallidas."
        case .datosInvalidos:
            return "Los datos no son válidos."
        case .servidor:
            return "Hubo un problema con el servidor. Intenta de nuevo."
        }
    }
}

class CaritasApi {

    let baseUrl = APIConfig.recolectoresUrl

    let sesion = SessionStore(key: APIConfig.auth.sessionKey)

    func getRuta(fecha: String) async throws -> [Recoleccion] {

        guard let url = URL(string: "\(baseUrl)route?date=\(fecha)") else {
            print("URL incorrecto")
            throw URLError(.badURL)
        }

        let request = crearRequest(url: url, metodo: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        try revisar(response)

        return try JSONDecoder().decode([Recoleccion].self, from: data)
    }

    func registrarResultado(_ resultado: ResultadoRequest) async throws -> ResultadoRespuesta {

        guard let url = URL(string: "\(baseUrl)result") else {
            print("URL incorrecto")
            throw URLError(.badURL)
        }

        var request = crearRequest(url: url, metodo: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(resultado)

        let (data, response) = try await URLSession.shared.data(for: request)
        try revisar(response)

        return try JSONDecoder().decode(ResultadoRespuesta.self, from: data)
    }

    func getResumen(fecha: String) async throws -> ResumenDia {

        guard let url = URL(string: "\(baseUrl)summary?date=\(fecha)") else {
            print("URL incorrecto")
            throw URLError(.badURL)
        }

        let request = crearRequest(url: url, metodo: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        try revisar(response)

        return try JSONDecoder().decode(ResumenDia.self, from: data)
    }

    func getHistorial(collectionId: Int) async throws -> [DonacionHistorial] {

        guard let url = URL(string: "\(baseUrl)history?collectionId=\(collectionId)") else {
            print("URL incorrecto")
            throw URLError(.badURL)
        }

        let request = crearRequest(url: url, metodo: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        try revisar(response)

        return try JSONDecoder().decode([DonacionHistorial].self, from: data)
    }

    func reprogramar(_ pedido: ReprogramarRequest) async throws -> ReprogramarRespuesta {

        guard let url = URL(string: "\(baseUrl)reschedule") else {
            print("URL incorrecto")
            throw URLError(.badURL)
        }

        var request = crearRequest(url: url, metodo: "PUT")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(pedido)

        let (data, response) = try await URLSession.shared.data(for: request)
        try revisar(response, conflicto: .noReprogramable)

        return try JSONDecoder().decode(ReprogramarRespuesta.self, from: data)
    }

    func crearRequest(url: URL, metodo: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = metodo
        if let token = sesion.readToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    func revisar(_ response: URLResponse, conflicto: ApiError = .yaRegistrada) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Respuesta no válida del servidor")
            throw ApiError.servidor
        }

        print("Código del API: \(httpResponse.statusCode)")

        switch httpResponse.statusCode {
        case 200, 201:
            return
        case 400:
            throw ApiError.datosInvalidos
        case 401:
            throw ApiError.sesionExpirada
        case 403:
            throw ApiError.noPermitido
        case 404:
            throw ApiError.noExiste
        case 409:
            throw conflicto
        default:
            throw ApiError.servidor
        }
    }

}
