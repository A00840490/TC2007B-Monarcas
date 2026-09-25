import Foundation

class LlamadasService {

    let baseUrl = "http://monarcas.tc2007b.tec.mx.:10206/api/"

    func obtenerLlamadas() async throws -> [Llamada] {
        let url = URL(string: "\(baseUrl)llamadas")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            print("Respuesta no válida del servidor")
            throw URLError(.badServerResponse)
        }

        guard (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) else {
            print("Código de error del API: \(httpResponse.statusCode)")
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([Llamada].self, from: data)
    }

    func obtenerTurno() -> Turno {
        return Turno(id: 1, telefonista: "María", nombreTurno: "Turno matutino", totalAsignadas: 83)
    }
}
