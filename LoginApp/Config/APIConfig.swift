import SwiftUI
import CaritasAuth

enum APIConfig {
    
    static let baseUrl = "https://monarcas.tc2007b.tec.mx:10206/api/"
    
    static let auth = AuthConfiguration(
        apiBaseUrl: baseUrl,
        role: "Admin",
        logo: Image("CaritasLogo"),
        accentColor: .standardDarkerColor
    )
    
}
