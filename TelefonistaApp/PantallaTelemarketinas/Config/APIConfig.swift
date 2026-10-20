//
//  APIConfig.swift
//  PantallaTelemarketinas
//
//  Created by Alumno on 17/10/26.
//

import Foundation
import CaritasAuth

class APIConfig {
    static let baseUrl = "https://monarcas.tc2007b.tec.mx:10206/api/"
    static let telefonistasUrl = baseUrl + "telefonistas/"
    static let userUrl = baseUrl + "user"

    static let auth = AuthConfiguration(
        apiBaseUrl: baseUrl,
        role: "Telefonista"
    )
}
