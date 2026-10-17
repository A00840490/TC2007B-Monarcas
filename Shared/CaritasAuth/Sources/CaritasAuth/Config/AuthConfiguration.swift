import SwiftUI

/// What changes between apps (admin, telefonista, recolector).
/// Each app creates its own and passes it to `AuthGate`.
public struct AuthConfiguration {
    
    /// API base URL, ending in "/" (e.g. "https://host:10206/api/").
    public var apiBaseUrl: String
    
    /// Role this app accepts, equal to `Name` in the Role table
    /// ("Admin", "Telefonista" or "Recolector").
    public var role: String
    
    /// Title shown above the form. If the app does not set one,
    /// the one for its role is used (see `defaultTitle(for:)`).
    public var title: String
    
    /// Optional logo shown above the title.
    public var logo: Image?
    
    /// Allowed email domain (including "@").
    public var emailDomain: String
    
    /// Keychain key where the session token is stored.
    public var sessionKey: String
    
    /// Color of the button and the form's shadow.
    public var accentColor: Color
    
    public init(
        apiBaseUrl: String,
        role: String,
        title: String? = nil,
        logo: Image? = nil,
        emailDomain: String = "@caritas.org.mx",
        sessionKey: String = "caritasAuthToken",
        accentColor: Color = Color(red: 71/255, green: 194/255, blue: 203/255)
    ) {
        self.apiBaseUrl = apiBaseUrl
        self.role = role
        self.title = title ?? AuthConfiguration.defaultTitle(for: role)
        self.logo = logo
        self.emailDomain = emailDomain
        self.sessionKey = sessionKey
        self.accentColor = accentColor
    }
    
    /// Login title for the app's role (shown to the user).
    public static func defaultTitle(for role: String) -> String {
        switch role.trimmingCharacters(in: .whitespaces).lowercased() {
        case "admin":
            return "Panel de Administrador"
        case "telefonista":
            return "Telefonistas"
        case "recolector":
            return "Recolectores"
        default:
            return "Iniciar sesión"
        }
    }
    
    /// Role name shown to the user, e.g. "Admin" -> "Administrador".
    public static func roleDisplayName(_ role: String) -> String {
        switch role.trimmingCharacters(in: .whitespaces).lowercased() {
        case "admin":
            return "Administrador"
        case "telefonista":
            return "Telefonista"
        case "recolector":
            return "Recolector"
        default:
            return role
        }
    }
    
}
