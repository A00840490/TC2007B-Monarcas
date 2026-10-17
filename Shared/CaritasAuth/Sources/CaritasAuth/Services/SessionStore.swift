import Foundation

/// Saves, reads and deletes the JSON Web Token of the current session.
/// Apps can read it to send it as `Authorization: Bearer <token>`.
public struct SessionStore {
    
    let key: String
    
    public init(key: String) {
        self.key = key
    }
    
    public func readToken() -> String? {
        KeychainHelper.shared.readString(forKey: key)
    }
    
    public func save(token: String) {
        KeychainHelper.shared.save(token, forKey: key)
    }
    
    public func clear() {
        KeychainHelper.shared.delete(forKey: key)
    }
    
}
