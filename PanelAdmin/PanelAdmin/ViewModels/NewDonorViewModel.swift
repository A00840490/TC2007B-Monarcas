//
//  NewDonorViewModel.swift
//  PanelAdmin
//

import Foundation
import Observation

/// Form of the "Nuevo donante" sheet.
@Observable
class NewDonorViewModel
{
    // Same limits as the Donor table.
    static let nameLimit = 150
    static let phoneLimit = 20
    static let addressLimit = 300
    
    var name = ""
    var phone = ""
    var address = ""
    /// LOW, MEDIUM or HIGH
    var riskStatus = "LOW"
    
    private(set) var isSaving = false
    private(set) var errorMessage: String?
    
    private let donorService: DonorService
    
    init(donorService: DonorService = DonorService())
    {
        self.donorService = donorService
    }
    
    /// What has to be fixed before saving, or nil if the form is valid.
    var problem: String?
    {
        if trimmed(name).count > Self.nameLimit
        {
            return "El nombre puede tener hasta \(Self.nameLimit) caracteres."
        }
        if trimmed(phone).count > Self.phoneLimit
        {
            return "El teléfono puede tener hasta \(Self.phoneLimit) caracteres."
        }
        if trimmed(address).count > Self.addressLimit
        {
            return "La dirección puede tener hasta \(Self.addressLimit) caracteres."
        }
        return nil
    }
    
    var canSave: Bool
    {
        !trimmed(name).isEmpty && problem == nil && !isSaving
    }
    
    /// Saves the donor and returns its id, or nil if it could not be saved.
    func save() async -> Int?
    {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        
        let donor = NewDonor(
            name: trimmed(name),
            phone: trimmed(phone),
            address: trimmed(address),
            riskStatus: riskStatus
        )
        
        do {
            return try await donorService.createDonor(donor)
        } catch DonorServiceError.invalidSession {
            errorMessage = "Tu sesión expiró. Inicia sesión de nuevo."
        } catch DonorServiceError.invalidData {
            errorMessage = "Revisa los datos del donante."
        } catch {
            print("Error creating the donor: \(error)")
            errorMessage = "No se pudo guardar el donante. Intenta de nuevo."
        }
        return nil
    }
    
    private func trimmed(_ text: String) -> String
    {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
