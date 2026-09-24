import Foundation

struct userCredentials : Codable {
    
    let caritasEMail: String;
    let password: String;
    
}

struct loginAttemptResponse: Codable {
    
    let userId: Int;
    
}
