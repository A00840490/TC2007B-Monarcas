import Foundation
import CryptoKit

func hasher(_ content: String) -> String {

    let input = Data(content.utf8)
    let hashedContent = SHA256.hash(data: input)
    return hashedContent.compactMap { String(format: "%02x", $0) }.joined()

}