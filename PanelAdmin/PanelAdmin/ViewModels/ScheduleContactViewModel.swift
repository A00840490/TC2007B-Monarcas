//
//  ScheduleContactViewModel.swift
//  PanelAdmin
//

import Foundation
import Observation

/// What the admin schedules from a staff member's screen.
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

/// Form that schedules a call (for a Telefonista) or a collection (for a
/// Recolector). The staff member is fixed by the screen it opens from; the
/// admin chooses the donor.
@Observable
class ScheduleContactViewModel
{
    enum DonorsState
    {
        case loading
        case ready
        case error(String)
    }
    
    /// Same limit as the Notes column.
    static let notesLimit = 1000
    
    let kind: ScheduleKind
    /// Telefonista (call) or recolector (collection) the work is assigned to.
    let staffId: Int
    
    private(set) var donorsState: DonorsState = .loading
    private(set) var donors: [DonorSummary] = []
    private(set) var donorId: Int?
    var date: Date
    /// Only for collections.
    var amountText = ""
    var notes = ""
    
    private(set) var isSaving = false
    private(set) var errorMessage: String?
    
    /// Pledge amount put in the amount field; it is replaced only while the
    /// admin has not typed something else.
    private var suggestedAmountText = ""
    
    private let donorService: DonorService
    
    private static let amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }()
    
    init(
        kind: ScheduleKind,
        staffId: Int,
        donorService: DonorService = DonorService()
    )
    {
        self.kind = kind
        self.staffId = staffId
        self.donorService = donorService
        date = ScheduleContactViewModel.defaultDate()
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
    
    var selectedDonor: DonorSummary?
    {
        donors.first { $0.id == donorId }
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
        donorId != nil && problem == nil && !isSaving
    }
    
    func loadDonors(months: Int) async
    {
        donorsState = .loading
        
        do {
            let list = try await donorService.getDonors(months: months)
            donors = list.donors.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            donorsState = .ready
        } catch DonorServiceError.invalidSession {
            donorsState = .error("Tu sesión expiró. Inicia sesión de nuevo.")
        } catch {
            print("Error loading the donors: \(error)")
            donorsState = .error("No se pudieron cargar los donantes.")
        }
    }
    
    /// Chooses the donor; for a collection, suggests the donor's pledge amount.
    func select(_ donor: DonorSummary)
    {
        donorId = donor.id
        
        guard kind == .collection else { return }
        
        let isUntouched = amountText.isEmpty || amountText == suggestedAmountText
        guard isUntouched else { return }
        
        if let pledgeAmount = donor.pledgeAmount
        {
            suggestedAmountText = Self.amountFormatter.string(from: NSNumber(value: pledgeAmount)) ?? ""
        }
        else
        {
            suggestedAmountText = ""
        }
        amountText = suggestedAmountText
    }
    
    /// Saves the call or collection; returns false if it could not be saved.
    func save() async -> Bool
    {
        guard let donorId else { return false }
        
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
                        telefonistaId: staffId,
                        scheduledDate: scheduledDate,
                        notes: savedNotes
                    ))
                case .collection:
                    try await donorService.scheduleCollection(NewCollection(
                        donorId: donorId,
                        recolectorId: staffId,
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
