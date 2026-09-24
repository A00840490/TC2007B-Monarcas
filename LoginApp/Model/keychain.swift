import Foundation
import Security

class KeychainHelper {
    
    static let shared = KeychainHelper()
    private init() {}
    
    func save(_ value: Int, forKey key: String) {
        let valueString = String(value)
        if let data = valueString.data(using: .utf8) {
            save(data, forKey: key)
        }
    }
    
    func readInt(forKey key: String) -> Int? {
        guard let data = read(forKey: key),
              let valueString = String(data: data, encoding: .utf8) else {
            return nil
        }
        return Int(valueString)
    }
    
    private func save(_ data: Data, forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func read(forKey key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess {
            return dataTypeRef as? Data
        }
        return nil
    }
    
    func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}