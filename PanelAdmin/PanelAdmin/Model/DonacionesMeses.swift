//
//  DonacionesMeses.swift
//  PanelAdmin
//
//  Created by Alumno on 24/09/26.
//

import Foundation

struct DonacionesMeses: Codable, Identifiable
{
    var id: Int
    var mes: String
    var monto: Int
}
