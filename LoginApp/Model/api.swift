import Foundation

class CaritasApi {
    
    let baseUrl = "http://monarcas.tc2007b.tec.mx:10206/api";
    
    func postloginAttempt(_ loginCredentials: userCredentials) async throws -> loginAttemptResponse {

        let secureLoginAttempt = userCredentials(
            caritasEMail: loginCredentials.caritasEMail,
            password: hasher(loginCredentials.password)
        )
        
        let url = URL(string: "\(baseUrl)loginAttempt")!
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(secureLoginAttempt)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Respuesta no válida del servidor")
            throw URLError(.badServerResponse)
        }
        
        guard (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) else {
            print("Código de error del API: \(httpResponse.statusCode)")
            print("Respuesta: \(String(data: data, encoding: .utf8) ?? "sin cuerpo")")
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(loginAttemptResponse.self, from: data)
        
    }
    
}
