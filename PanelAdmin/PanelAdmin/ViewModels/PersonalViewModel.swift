//
//  PersonalViewModel.swift
//  PanelAdmin
//

import Foundation
import Observation

@Observable
class PersonalViewModel
{
    enum LoadState: Equatable
    {
        case loading
        case ready
        case loggedOut(String)
        case error(String)
    }
    
    enum Role: String, CaseIterable, Identifiable
    {
        case telefonistas
        case recolectores
        
        var id: String { rawValue }
        
        var title: String
        {
            self == .telefonistas ? "Telefonistas" : "Recolectores"
        }
    }
    
    enum SortKey: String, CaseIterable, Identifiable
    {
        case rate
        case volume
        case name
        
        var id: String { rawValue }
        
        var title: String
        {
            switch self
            {
                case .rate:
                    return "Tasa"
                case .volume:
                    return "Actividad"
                case .name:
                    return "Nombre"
            }
        }
    }
    
    var state: LoadState = .loading
    var report: PersonalReport?
    
    var role: Role = .telefonistas { didSet { page = 0 } }
    var sortKey: SortKey = .rate { didSet { page = 0 } }
    
    var months = 3
    
    /// The list never scrolls: the view sets how many rows fit in the space
    /// it has, and the rest go to the next pages.
    var pageSize = 6
    var page = 0
    
    private let personalService = PersonalService()
    
    func load() async
    {
        if report == nil { state = .loading }
        
        do {
            report = try await personalService.getPersonal(months: months)
            state = .ready
        } catch DonorServiceError.invalidSession {
            state = .loggedOut("Tu sesión expiró. Inicia sesión de nuevo.")
        } catch {
            print("Error loading personal: \(error)")
            state = .error("No se pudo cargar el personal.")
        }
    }
    
    var telefonistas: [TelefonistaPerformance]
    {
        let all = report?.telefonistas ?? []
        
        switch sortKey
        {
            case .rate:
                return all.sorted { $0.confirmationRate > $1.confirmationRate }
            case .volume:
                return all.sorted { $0.totalCalls > $1.totalCalls }
            case .name:
                return all.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }
    
    var recolectores: [RecolectorPerformance]
    {
        let all = report?.recolectores ?? []
        
        switch sortKey
        {
            case .rate:
                return all.sorted { $0.successRate > $1.successRate }
            case .volume:
                return all.sorted { $0.totalCollections > $1.totalCollections }
            case .name:
                return all.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }
    
    var totalCount: Int
    {
        role == .telefonistas ? telefonistas.count : recolectores.count
    }
    
    var pageCount: Int
    {
        if totalCount == 0 { return 1 }
        return (totalCount + pageSize - 1) / pageSize
    }
    
    var currentPage: Int
    {
        min(page, pageCount - 1)
    }
    
    var pageTelefonistas: [TelefonistaPerformance]
    {
        let start = currentPage * pageSize
        let end = min(start + pageSize, telefonistas.count)
        if start >= end { return [] }
        return Array(telefonistas[start..<end])
    }
    
    var pageRecolectores: [RecolectorPerformance]
    {
        let start = currentPage * pageSize
        let end = min(start + pageSize, recolectores.count)
        if start >= end { return [] }
        return Array(recolectores[start..<end])
    }
    
    var rangeText: String
    {
        if totalCount == 0 { return "0 personas" }
        let start = currentPage * pageSize + 1
        let end = min(start + pageSize - 1, totalCount)
        return "\(start)–\(end) de \(totalCount) personas"
    }
    
    func nextPage()
    {
        page = min(currentPage + 1, pageCount - 1)
    }
    
    func previousPage()
    {
        page = max(currentPage - 1, 0)
    }
}


