//
//  ProfileCache.swift
//  PanelAdmin
//

import Foundation
import CryptoKit

/// Stores the logged-in user's name, email and role in UserDefaults so the API
/// is not asked every time the profile opens. It is not sensitive data; the
/// token and the user id stay in the Keychain and are never stored here.
///
/// The profile is stored together with a SHA-256 hash of the token: if the
/// session changes (another login, another user), the hash does not match and
/// the profile is requested again.
struct ProfileCache
{
    private struct Entry: Codable
    {
        var session: String
        var profile: UserProfile
    }
    
    private let defaults: UserDefaults
    private let key: String
    
    init(defaults: UserDefaults = .standard, key: String = "userProfile")
    {
        self.defaults = defaults
        self.key = key
    }
    
    func profile(forToken token: String) -> UserProfile? {
        guard let data = defaults.data(forKey: key),
              let entry = try? JSONDecoder().decode(Entry.self, from: data),
              entry.session == Self.fingerprint(token) else {
            return nil
        }
        return entry.profile
    }
    
    func save(_ profile: UserProfile, token: String) {
        let entry = Entry(session: Self.fingerprint(token), profile: profile)
        if let data = try? JSONEncoder().encode(entry) {
            defaults.set(data, forKey: key)
        }
    }
    
    func clear() {
        defaults.removeObject(forKey: key)
    }
    
    private static func fingerprint(_ token: String) -> String {
        SHA256.hash(data: Data(token.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
