//
//  ProfileCache.swift
//  PanelAdmin
//

import Foundation
import CryptoKit

struct SavedProfile: Codable
{
    var tokenHash: String
    var profile: UserProfile
}

struct ProfileCache
{
    let key = "userProfile"
    
    func profile(forToken token: String) -> UserProfile?
    {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        guard let saved = try? JSONDecoder().decode(SavedProfile.self, from: data) else { return nil }
        
        if saved.tokenHash != hash(token) { return nil }
        return saved.profile
    }
    
    func save(_ profile: UserProfile, token: String)
    {
        let saved = SavedProfile(tokenHash: hash(token), profile: profile)
        
        if let data = try? JSONEncoder().encode(saved)
        {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    func clear()
    {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    func hash(_ token: String) -> String
    {
        let digest = SHA256.hash(data: Data(token.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
