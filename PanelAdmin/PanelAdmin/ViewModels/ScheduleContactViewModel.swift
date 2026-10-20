//
//  ScheduleContactViewModel.swift
//  PanelAdmin
//

import Foundation
import Observation

enum ScheduleKind: String, Identifiable
{
    case call
    case collection
    
    var id: String { rawValue }
    
    var title: String
    {
        self == .call ? "Agendar llamada" : "Agendar recolección"
    }
    
    var assigneeTitle: String
    {
        self == .call ? "Telefonista" : "Recolector"
    }
    
    var notesTitle: String
    {
        self == .call ? "Objetivo de la llamada" : "Notas para el recolector"
    }
}

@Observable
class ScheduleContactViewModel
{
    let kind: ScheduleKind
    let staffId: Int
    
    var donors: [DonorSummary] = []
    var isLoadingDonors = true
    var donorsError: String?
    var donorId: Int?
    
    var date = ScheduleContactViewModel.tomorrowAtTen()
    var amountText = ""
    var suggestedAmount = ""
    var notes = ""
    
    var isSaving = false
    var errorMessage: String?
    
    private let donorService = DonorService()
    
    init(kind: ScheduleKind, staffId: Int)
    {
        self.kind = kind
        self.staffId = staffId
    }
    
    static func tomorrowAtTen() -> Date
    {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return calendar.date(bySettingHour: 10, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }
    
    var selectedDonor: DonorSummary?
    {
        donors.first { $0.id == donorId }
    }
    
    var cleanAmountText: String
    {
        amountText.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "")
    }
    
    var amount: Double?
    {
        Double(cleanAmountText)
    }
    
    var problem: String?
    {
        if kind == .collection && !cleanAmountText.isEmpty && !isValidAmount
        {
            return "Escribe un monto válido."
        }
        if notes.count > 1000
        {
            return "Las notas pueden tener hasta 1000 caracteres."
        }
        return nil
    }
    
    var isValidAmount: Bool
    {
        guard let amount else { return false }
        return amount.isFinite && amount >= 0
    }
    
    var canSave: Bool
    {
        donorId != nil && problem == nil && !isSaving
    }
    
    func loadDonors(months: Int) async
    {
        isLoadingDonors = true
        donorsError = nil
        
        do {
            let list = try await donorService.getDonors(months: months)
            donors = list.donors.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch DonorServiceError.invalidSession {
            donorsError = "Tu sesión expiró. Inicia sesión de nuevo."
        } catch {
            print("Error loading the donors: \(error)")
            donorsError = "No se pudieron cargar los donantes."
        }
        
        isLoadingDonors = false
    }
    
    func select(_ donor: DonorSummary)
    {
        donorId = donor.id
        
        if kind == .collection && (amountText.isEmpty || amountText == suggestedAmount)
        {
            if let pledgeAmount = donor.pledgeAmount
            {
                suggestedAmount = String(format: "%.2f", pledgeAmount).replacingOccurrences(of: ".00", with: "")
            }
            else
            {
                suggestedAmount = ""
            }
            amountText = suggestedAmount
        }
    }
    
    func save() async -> Bool
    {
        guard let donorId else { return false }
        
        isSaving = true
        errorMessage = nil
        
        let scheduledDate = DonorFormat.apiDate(date)
        let cleanNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let savedNotes = cleanNotes.isEmpty ? nil : cleanNotes
        
        do {
            if kind == .call
            {
                let call = NewPhoneCall(donorId: donorId, telefonistaId: staffId, scheduledDate: scheduledDate, notes: savedNotes)
                try await donorService.scheduleCall(call)
            }
            else
            {
                let collection = NewCollection(donorId: donorId, recolectorId: staffId, scheduledDate: scheduledDate, expectedAmount: cleanAmountText.isEmpty ? nil : amount, notes: savedNotes)
                try await donorService.scheduleCollection(collection)
            }
            isSaving = false
            return true
        } catch DonorServiceError.invalidSession {
            errorMessage = "Tu sesión expiró. Inicia sesión de nuevo."
        } catch DonorServiceError.invalidData {
            errorMessage = "Revisa la fecha y los datos. La fecha no puede ser de un día que ya pasó."
        } catch {
            print("Error scheduling: \(error)")
            errorMessage = "No se pudo agendar. Intenta de nuevo."
        }
        
        isSaving = false
        return false
    }
}
