import Foundation

struct UserCredentials: Codable {
    
    let email: String
    let password: String
    let role: String
    
}

struct LoginAttemptResponse: Codable {
    
    let token: String
    let userId: Int
    let role: String
    
}

struct VerifyRequest: Codable {
    
    let token: String
    let role: String
    
}

struct VerifyResponse: Codable {
    
    let valid: Bool
    let userId: Int
    let role: String
    
}

enum AuthAPIError: Error {
    
    /// The API rejected the credentials or the token (401 or 403), or too many attempts (429).
    case rejected(statusCode: Int)
    
    /// Network failure or unexpected server response.
    case server
    
}
