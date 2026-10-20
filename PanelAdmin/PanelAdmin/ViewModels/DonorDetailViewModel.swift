//
//  DonorDetailViewModel.swift
//  PanelAdmin
//

import Foundation
import Observation

@Observable
class DonorDetailViewModel
{
    enum LoadState
    {
        case loading
        case ready(DonorDetail)
        case loggedOut(String)
        case error(String)
    }
    
    var state: LoadState = .loading
    
    private let donorService = DonorService()
    
    func load(id: Int, months: Int) async
    {
        do {
            state = .ready(try await donorService.getDonor(id: id, months: months))
        } catch DonorServiceError.invalidSession {
            state = .loggedOut("Tu sesión expiró. Inicia sesión de nuevo.")
        } catch DonorServiceError.notFound {
            state = .error("Este donante ya no existe.")
        } catch {
            print("Error loading the donor: \(error)")
            state = .error("No se pudo cargar el donante.")
        }
    }
}
