//
//  ScheduleContactViewModel.swift
//  PanelAdmin
//

import Foundation
import Observation

/// What the admin schedules from a donor's screen.
enum ScheduleKind: String, Identifiable
{
    /// A PhoneCall assigned to a Telefonista.
    case call
    /// A Collection assigned to a Recolector.
    case collection
    
    var id: String { rawValue }
    
    var title: String
    {
        switch self
        {
            case .call:
                return "Agendar llamada"
            case .collection:
                return "Agendar recolección"
        }
    }
    
    var assigneeTitle: String
    {
        switch self
        {
            case .call:
                return "Telefonista"
            case .collection:
                return "Recolector"
        }
    }
    
    var noStaffMessage: String
    {
        switch self
        {
            case .call:
                return "No hay telefonistas registrados."
            case .collection:
                return "No hay recolectores registrados."
        }
    }
    
    var notesTitle: String
    {
        switch self
        {
            case .call:
                return "Objetivo de la llamada"
            case .collection:
                return "Notas para el recolector"
        }
    }
}

/// Form that schedules a call or a collection for one donor.
@Observable
class ScheduleContactViewModel
{
    enum StaffState
    {
        case loading
        case ready
        case error(String)
    }
    
    /// Same limit as the Notes column.
    static let notesLimit = 1000
    
    let kind: ScheduleKind
    let donorId: Int
    
    private(set) var staffState: StaffState = .loading
    /// Telefonistas for a call, recolectores for a collection.
    private(set) var staff: [StaffMember] = []
    var assigneeId: Int?
    var date: Date
    /// Only for collections.
    var amountText: String
    var notes = ""
    
    private(set) var isSaving = false
    private(set) var errorMessage: String?
    
    /// The pledge's telefonista or recolector, chosen by default if listed.
    private let suggestedAssigneeName: String?
    private let donorService: DonorService
    
    private static let amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    init(
        kind: ScheduleKind,
        donorId: Int,
        suggestedAmount: Double?,
        suggestedAssigneeName: String?,
        donorService: DonorService = DonorService()
    )
    {
        self.kind = kind
        self.donorId = donorId
        self.suggestedAssigneeName = suggestedAssigneeName
        self.donorService = donorService
        date = ScheduleContactViewModel.defaultDate()
        
        if kind == .collection, let suggestedAmount
        {
            amountText = ScheduleContactViewModel.amountFormatter.string(from: NSNumber(value: suggestedAmount)) ?? ""
        }
        else
        {
            amountText = ""
        }
    }
    
    /// Tomorrow at 10:00.
    static func defaultDate() -> Date
    {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now)) ?? .now
        return calendar.date(bySettingHour: 10, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }
    
    /// Parsed expected amount; nil if the field is empty or not a number.
    var amount: Double?
    {
        let text = amountText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }
        return Self.amountFormatter.number(from: text)?.doubleValue ?? Double(text)
    }
    
    /// What has to be fixed before saving, or nil if the form is valid.
    var problem: String?
    {
        if kind == .collection, !amountText.trimmingCharacters(in: .whitespaces).isEmpty
        {
            guard let amount, amount.isFinite, amount >= 0 else
            {
                return "Escribe un monto válido."
            }
        }
        if notes.count > Self.notesLimit
        {
            return "Las notas pueden tener hasta \(Self.notesLimit) caracteres."
        }
        return nil
    }
    
    var canSave: Bool
    {
        assigneeId != nil && problem == nil && !isSaving
    }
    
    func loadStaff() async
    {
        staffState = .loading
        
        do {
            let all = try await donorService.getStaff()
            staff = kind == .call ? all.telefonistas : all.recolectores
            assigneeId = staff.first(where: { $0.name == suggestedAssigneeName })?.id ?? staff.first?.id
            staffState = .ready
        } catch DonorServiceError.invalidSession {
            staffState = .error("Tu sesión expiró. Inicia sesión de nuevo.")
        } catch {
            print("Error loading the staff: \(error)")
            staffState = .error("No se pudo cargar el personal.")
        }
    }
    
    /// Saves the call or collection; returns false if it could not be saved.
    func save() async -> Bool
    {
        guard let assigneeId else { return false }
        
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        
        let scheduledDate = DonorFormat.apiDate(date)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let savedNotes = trimmedNotes.isEmpty ? nil : trimmedNotes
        
        do {
            switch kind
            {
                case .call:
                    try await donorService.scheduleCall(NewPhoneCall(
                        donorId: donorId,
                        telefonistaId: assigneeId,
                        scheduledDate: scheduledDate,
                        notes: savedNotes
                    ))
                case .collection:
                    try await donorService.scheduleCollection(NewCollection(
                        donorId: donorId,
                        recolectorId: assigneeId,
                        scheduledDate: scheduledDate,
                        expectedAmount: amount,
                        notes: savedNotes
                    ))
            }
            return true
        } catch DonorServiceError.invalidSession {
            errorMessage = "Tu sesión expiró. Inicia sesión de nuevo."
        } catch DonorServiceError.invalidData {
            errorMessage = "Revisa la fecha y los datos. La fecha no puede ser de un día que ya pasó."
        } catch {
            print("Error scheduling the \(kind.rawValue): \(error)")
            errorMessage = "No se pudo agendar. Intenta de nuevo."
        }
        return false
    }
}
