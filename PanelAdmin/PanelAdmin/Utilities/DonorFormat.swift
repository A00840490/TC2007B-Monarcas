//
//  DonorFormat.swift
//  PanelAdmin
//

import Foundation
import SwiftUI

/// Texts (in Spanish) and formats for the donor screens. The API sends codes
/// such as LOW or CASH; this is the only place that turns them into text.
enum DonorFormat
{
    private static let locale = Locale(identifier: "es_MX")
    
    private static let isoDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private static let apiDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()
    
    private static let monthNames = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"]
    
    // MARK: Numbers and dates
    
    static func money(_ amount: Double) -> String
    {
        amount.formatted(.currency(code: "MXN").precision(.fractionLength(0)).locale(locale))
    }
    
    /// Accepts "2026-10-06" and "2026-10-06T00:00:00".
    static func parse(_ value: String?) -> Date?
    {
        guard let value, value.count >= 10 else { return nil }
        return isoDay.date(from: String(value.prefix(10)))
    }
    
    /// Local date and time in the format the API expects: "2026-10-12T10:00:00"
    static func apiDate(_ date: Date) -> String
    {
        apiDateTime.string(from: date)
    }
    
    /// "6 oct 2026"
    static func date(_ value: String?) -> String
    {
        guard let date = parse(value) else { return "—" }
        return date.formatted(.dateTime.day().month(.abbreviated).year().locale(locale))
    }
    
    /// "6 oct"
    static func shortDate(_ value: String?) -> String
    {
        guard let date = parse(value) else { return "—" }
        return date.formatted(.dateTime.day().month(.abbreviated).locale(locale))
    }
    
    /// 1...12 -> "ene"..."dic"
    static func monthName(_ month: Int) -> String
    {
        monthNames.indices.contains(month - 1) ? monthNames[month - 1] : "\(month)"
    }
    
    static func daysAgo(_ days: Int?) -> String
    {
        guard let days else { return "Nunca ha donado" }
        switch days
        {
            case ..<1:
                return "Hoy"
            case 1:
                return "Ayer"
            case 2..<60:
                return "Hace \(days) días"
            default:
                return "Hace \(Int((Double(days) / 30).rounded())) meses"
        }
    }
    
    // MARK: Codes
    
    static func risk(_ code: String) -> String
    {
        ["LOW": "Bajo", "MEDIUM": "Medio", "HIGH": "Alto"][code] ?? code
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
        guard let code else { return "—" }
        return ["CASH": "Efectivo", "TRANSFER": "Transferencia"][code] ?? code
    }
    
    static func pledgeStatus(_ code: String) -> String
    {
        ["ACTIVE": "Activa", "PAUSED": "Pausada", "CANCELLED": "Cancelada", "FINISHED": "Terminada"][code] ?? code
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
        guard let code else { return "" }
        return [
            "PENDING": "Pendiente",
            "NO_ANSWER": "No contestó",
            "DECLINED": "No quiso donar",
            "ACCEPTED": "Aceptó",
            "RESCHEDULED": "Pidió otro día",
        ][code] ?? code
    }
    
    static func collectionStatus(_ code: String?) -> String
    {
        guard let code else { return "" }
        return ["PENDING": "Programada", "SUCCESSFUL": "Recolectada", "FAILED": "Sin éxito"][code] ?? code
    }
    
    // MARK: Composed texts
    
    /// "Llamada de confirmación el 13 oct con Laura Treviño"
    static func upcoming(_ contact: UpcomingContact?) -> String
    {
        guard let contact else { return "Nada agendado" }
        let label = contact.kind == "CALL" ? callType(contact.type) : "Recolección"
        return "\(label) el \(shortDate(contact.date)) con \(contact.userName)"
    }
    
    static func activityTitle(_ item: DonorActivity) -> String
    {
        switch item.kind
        {
            case "DONATION":
                return "Donación de \(money(item.amount ?? 0))"
            case "CALL":
                return "\(callType(item.type)): \(callStatus(item.status).lowercased())"
            default:
                return "Recolección \(collectionStatus(item.status).lowercased())"
        }
    }
    
    static func activityDetail(_ item: DonorActivity) -> String
    {
        var parts: [String] = []
        switch item.kind
        {
            case "DONATION":
                parts.append(paymentMethod(item.paymentMethod))
                if let campaign = item.campaign { parts.append(campaign) }
                if item.isInstallment { parts.append("cuota mensual") }
            case "CALL":
                if let userName = item.userName { parts.append(userName) }
                if let notes = item.notes { parts.append(notes) }
            default:
                if let userName = item.userName { parts.append(userName) }
                if let amount = item.amount { parts.append("\(money(amount)) esperados") }
                if let notes = item.notes { parts.append(notes) }
        }
        return parts.joined(separator: " · ")
    }
}
