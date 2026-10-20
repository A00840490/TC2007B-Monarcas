//
//  Format.swift
//  PantallaTelemarketinas
//
//  Created by Alumno on 17/10/26.
//

import SwiftUI

func riskText(_ risk: String) -> String {
    if risk == "LOW" {
        return "Riesgo bajo"
    } else if risk == "HIGH" {
        return "Riesgo alto"
    } else {
        return "Riesgo medio"
    }
}

func riskColor(_ risk: String) -> Color {
    if risk == "LOW" {
        return Constants.greenColor
    } else if risk == "HIGH" {
        return Constants.redColor
    } else {
        return Constants.orangeColor
    }
}

func stateColor(_ state: String) -> Color {
    if state == "Vencida" {
        return Constants.redColor
    } else if state == "Próxima" {
        return Constants.orangeColor
    } else {
        return Constants.greenColor
    }
}

func resultColor(_ status: String) -> Color {
    if status == "NO_ANSWER" {
        return Constants.redColor
    } else if status == "DECLINED" {
        return Constants.orangeColor
    } else if status == "ACCEPTED" {
        return Constants.greenColor
    } else if status == "RESCHEDULED" {
        return Constants.blueColor
    } else {
        return Constants.secondaryColor
    }
}

func resultIcon(_ status: String) -> String {
    if status == "ACCEPTED" {
        return "checkmark.circle.fill"
    } else if status == "DECLINED" {
        return "xmark.circle.fill"
    } else if status == "NO_ANSWER" {
        return "phone.down.fill"
    } else if status == "NOTE" {
        return "note.text"
    } else {
        return "clock.fill"
    }
}

func todayText() -> String {
    let formato = DateFormatter()
    formato.dateStyle = .full
    formato.locale = Locale(identifier: "es_MX")
    return formato.string(from: Date())
}

func longDate(_ apiText: String) -> String {
    let lector = DateFormatter()
    lector.dateFormat = "yyyy-MM-dd"
    let fecha = lector.date(from: apiText) ?? Date()

    let formato = DateFormatter()
    formato.dateStyle = .long
    formato.locale = Locale(identifier: "es_MX")
    return formato.string(from: fecha)
}

func apiDate(_ date: Date) -> String {
    let formato = DateFormatter()
    formato.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    return formato.string(from: date)
}
