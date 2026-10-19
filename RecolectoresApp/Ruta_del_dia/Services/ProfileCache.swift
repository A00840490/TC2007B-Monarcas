//
//  ProfileCache.swift
//  Ruta_del_dia
//
// Creado por Alumno el 19/10/2026

import Foundation
import CryptoKit

struct ProfileCache {

    private struct Entry: Codable {
        var session: String
        var profile: UserProfile
    }

    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "userProfile") {
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
