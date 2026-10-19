//
//  APIConfig.swift
//  Ruta_del_dia
//
//  Created by Alumno on 19/10/26.
//

import Foundation
import CaritasAuth

enum APIConfig {
    static let baseUrl = "https://monarcas.tc2007b.tec.mx:10206/api/"
    static let recolectoresUrl = baseUrl + "recolectores/"

    static let usarPlaceholder = false

    static let auth = AuthConfiguration(
        apiBaseUrl: baseUrl,
        role: "Recolector"
    )
}
