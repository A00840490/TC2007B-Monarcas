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
    
    /// Which team the screen shows.
    enum Role: String, CaseIterable, Identifiable
    {
        case telefonistas
        case recolectores
        
        var id: String { rawValue }
        
        var title: String
        {
            switch self
            {
                case .telefonistas:
                    return "Telefonistas"
                case .recolectores:
                    return "Recolectores"
            }
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
    
    /// How good a rate is; the view maps each level to a color.
    enum RateLevel
    {
        case good
        case medium
        case low
    }
    
    var state: LoadState = .loading
    private(set) var report: PersonalReport?
    
    // Changing the team or the order goes back to the first page.
    var role: Role = .telefonistas { didSet { page = 0 } }
    var sortKey: SortKey = .rate { didSet { page = 0 } }
    
    /// The list never scrolls: the view sets how many rows fit and the rest
    /// go to the next pages.
    var pageSize = 6
    private(set) var page = 0
    
    /// Window in months (3, 6 or 12).
    var months = 3
    
    private let personalService: PersonalService
    
    init(personalService: PersonalService = PersonalService())
    {
        self.personalService = personalService
    }
    
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
    
    // MARK: Ordered lists
    
    var telefonistas: [TelefonistaPerformance]
    {
        let all = report?.telefonistas ?? []
        switch sortKey
        {
            case .rate:
                return all.sorted { ($0.confirmationRate, $0.totalCalls)>($1.confirmationRate, $1.totalCalls) }
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
                return all.sorted { ($0.successRate, $0.totalCollections)>($1.successRate, $1.totalCollections) }
            case .volume:
                return all.sorted { $0.totalCollections > $1.totalCollections }
            case .name:
                return all.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }
    }
    
    /// True when the selected team has nobody to show.
    var isEmpty: Bool
    {
        switch role
        {
            case .telefonistas:
                return telefonistas.isEmpty
            case .recolectores:
                return recolectores.isEmpty
        }
    }
    
    // MARK: Pages
    
    /// People in the selected team.
    var totalCount: Int
    {
        switch role
        {
            case .telefonistas:
                return telefonistas.count
            case .recolectores:
                return recolectores.count
        }
    }
    
    var pageCount: Int
    {
        max(1, Int((Double(totalCount) / Double(max(pageSize, 1))).rounded(.up)))
    }
    
    var currentPage: Int
    {
        min(page, pageCount - 1)
    }
    
    var pageTelefonistas: [TelefonistaPerformance]
    {
        slice(telefonistas)
    }
    
    var pageRecolectores: [RecolectorPerformance]
    {
        slice(recolectores)
    }
    
    private func slice<T>(_ items: [T]) -> [T]
    {
        let start = currentPage * pageSize
        guard start < items.count else { return [] }
        return Array(items[start..<min(start + pageSize, items.count)])
    }
    
    /// "1–6 de 11 personas"
    var rangeText: String
    {
        let total = totalCount
        guard total > 0 else { return "0 personas" }
        let start = currentPage * pageSize + 1
        let end = min(start + pageSize - 1, total)
        return "\(start)–\(end) de \(total) personas"
    }
    
    func nextPage()
    {
        page = min(currentPage + 1, pageCount - 1)
    }
    
    func previousPage()
    {
        page = max(currentPage - 1, 0)
    }
    
    // MARK: Helpers for the view
    
    static func level(for rate: Int) -> RateLevel
    {
        if rate >= 70 { return .good }
        if rate >= 50 { return .medium }
        return .low
    }
    
    /// "Laura Treviño" -> "LT"
    static func initials(of name: String) -> String
    {
        let letters = name.split(separator: " ").prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }
}
