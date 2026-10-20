//
//  DonorFormat.swift
//  PanelAdmin
//

import Foundation
import SwiftUI

enum DonorFormat
{
    static let locale = Locale(identifier: "es_MX")
    
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()
    
    static let longDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()
    
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "d MMM"
        return formatter
    }()
    
    static let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_MX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    static func money(_ amount: Double) -> String
    {
        amount.formatted(.currency(code: "MXN").precision(.fractionLength(0)).locale(locale))
    }
    
    static func parse(_ value: String?) -> Date?
    {
        guard let value, value.count >= 10 else { return nil }
        return dayFormatter.date(from: String(value.prefix(10)))
    }
    
    static func apiDate(_ date: Date) -> String
    {
        apiDateFormatter.string(from: date)
    }
    
    static func date(_ value: String?) -> String
    {
        guard let date = parse(value) else { return "—" }
        return longDateFormatter.string(from: date)
    }
    
    static func shortDate(_ value: String?) -> String
    {
        guard let date = parse(value) else { return "—" }
        return shortDateFormatter.string(from: date)
    }
    
    static func dateAndHour(_ value: String) -> String
    {
        guard let date = apiDateFormatter.date(from: String(value.prefix(19))) else
        {
            return shortDate(value)
        }
        
        let day = Calendar.current.isDateInToday(date) ? "Hoy" : shortDateFormatter.string(from: date)
        let hour = hourFormatter.string(from: date)
        
        if hour == "00:00" { return day }
        return day + " " + hour
    }
    
    static func daysAgo(_ days: Int?) -> String
    {
        guard let days else { return "Nunca ha donado" }
        
        if days < 1 { return "Hoy" }
        if days == 1 { return "Ayer" }
        if days < 60 { return "Hace \(days) días" }
        return "Hace \(days / 30) meses"
    }
    
    static func risk(_ code: String) -> String
    {
        switch code
        {
            case "LOW":
                return "Bajo"
            case "MEDIUM":
                return "Medio"
            case "HIGH":
                return "Alto"
            default:
                return code
        }
    }
    
    static func riskColor(_ code: String) -> Color
    {
        switch code
        {
            case "LOW":
                return Constants.moneyColor
            case "MEDIUM":
                return Constants.warningColor
            default:
                return Constants.dangerColor
        }
    }
    
    static func paymentMethod(_ code: String?) -> String
    {
        switch code
        {
            case "CASH":
                return "Efectivo"
            case "TRANSFER":
                return "Transferencia"
            default:
                return code ?? "—"
        }
    }
    
    static func pledgeStatus(_ code: String) -> String
    {
        switch code
        {
            case "ACTIVE":
                return "Activa"
            case "PAUSED":
                return "Pausada"
            case "CANCELLED":
                return "Cancelada"
            case "FINISHED":
                return "Terminada"
            default:
                return code
        }
    }
    
    static func callType(_ code: String?) -> String
    {
        switch code
        {
            case "CONFIRMATION":
                return "Llamada de confirmación"
            case "TRANSFER_COLLECTION":
                return "Llamada para transferencia"
            default:
                return "Llamada"
        }
    }
    
    static func callStatus(_ code: String?) -> String
    {
        switch code
        {
            case "PENDING":
                return "pendiente"
            case "NO_ANSWER":
                return "no contestó"
            case "DECLINED":
                return "no quiso donar"
            case "ACCEPTED":
                return "aceptó"
            case "RESCHEDULED":
                return "pidió otro día"
            default:
                return code ?? ""
        }
    }
    
    static func collectionStatus(_ code: String?) -> String
    {
        switch code
        {
            case "PENDING":
                return "programada"
            case "SUCCESSFUL":
                return "recolectada"
            case "FAILED":
                return "sin éxito"
            default:
                return code ?? ""
        }
    }
    
    static func activityTitle(_ item: DonorActivity) -> String
    {
        switch item.kind
        {
            case "DONATION":
                return "Donación de \(money(item.amount ?? 0))"
            case "CALL":
                return "\(callType(item.type)): \(callStatus(item.status))"
            default:
                return "Recolección \(collectionStatus(item.status))"
        }
    }
    
    static func activityDetail(_ item: DonorActivity) -> String
    {
        var parts: [String] = []
        
        if item.kind == "DONATION"
        {
            parts.append(paymentMethod(item.paymentMethod))
            if let campaign = item.campaign { parts.append(campaign) }
            if item.isInstallment { parts.append("cuota mensual") }
        }
        else
        {
            if let userName = item.userName { parts.append(userName) }
            if item.kind == "COLLECTION", let amount = item.amount { parts.append("\(money(amount)) esperados") }
            if let notes = item.notes { parts.append(notes) }
        }
        
        return parts.joined(separator: " · ")
    }
}
