import Foundation

class AuthAPIClient {
    
    let baseUrl: String
    
    init(baseUrl: String) {
        self.baseUrl = baseUrl
    }
    
    func postLoginAttempt(_ loginCredentials: UserCredentials) async throws -> LoginAttemptResponse {

        let secureLoginAttempt = UserCredentials(
            email: loginCredentials.email,
            password: hasher(loginCredentials.password),
            role: loginCredentials.role
        )
        
        return try await post("login/attempt", body: secureLoginAttempt)
        
    }
    
    func postLoginVerify(token: String, role: String) async throws -> VerifyResponse {
        
        try await post("login/verify", body: VerifyRequest(token: token, role: role))
        
    }
    
    private func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        
        let url = URL(string: "\(baseUrl)\(path)")!
        var request = URLRequest(url: url)

        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("Invalid server response")
            throw AuthAPIError.server
        }
        
        guard httpResponse.statusCode == 200 else {
            print("API error code: \(httpResponse.statusCode)")
            print("Response: \(String(data: data, encoding: .utf8) ?? "no body")")
            if httpResponse.statusCode == 401 || httpResponse.statusCode == 403 {
                throw AuthAPIError.rejected(statusCode: httpResponse.statusCode)
            }
            throw AuthAPIError.server
        }
        
        return try JSONDecoder().decode(Response.self, from: data)
        
    }
    
}
