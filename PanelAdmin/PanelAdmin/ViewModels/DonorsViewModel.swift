//
//  DonorsViewModel.swift
//  PanelAdmin
//

import Foundation
import Observation

@Observable
class DonorsViewModel
{
    enum LoadState: Equatable
    {
        case loading
        case ready
        case loggedOut(String)
        case error(String)
    }
    
    enum Segment: String, CaseIterable, Identifiable
    {
        case active
        case recover
        case all
        
        var id: String { rawValue }
        
        var title: String
        {
            switch self
            {
                case .active:
                    return "Activos"
                case .recover:
                    return "Por recuperar"
                case .all:
                    return "Todos"
            }
        }
    }
    
    enum SortKey
    {
        case name
        case risk
        case lastDonation
    }
    
    var state: LoadState = .loading
    var list: DonorList?
    
    var agenda: DonorAgenda?
    var agendaError: String?
    
    var followUps: DonorFollowUps?
    var followUpsError: String?
    
    var filters: DonorFilters?
    
    var months = 6
    
    var segment: Segment = .active { didSet { page = 0 } }
    var query = "" { didSet { page = 0 } }
    var risk: String? = nil { didSet { page = 0 } }
    var paymentMethod: String? = nil { didSet { page = 0 } }
    var recolectorId: Int? = nil { didSet { page = 0 } }
    var telefonistaId: Int? = nil { didSet { page = 0 } }
    
    var sortKey: SortKey = .lastDonation
    var sortAscending = false
    
    let pageSize = 4
    var page = 0
    
    private let donorService = DonorService()
    
    func load() async
    {
        async let first: Void = loadDonors()
        async let second: Void = loadAgenda()
        async let third: Void = loadFollowUps()
        async let fourth: Void = loadFilters()
        
        _ = await (first, second, third, fourth)
    }
    
    func loadDonors() async
    {
        if list == nil { state = .loading }
        
        do {
            list = try await donorService.getDonors(months: months)
            state = .ready
        } catch DonorServiceError.invalidSession {
            state = .loggedOut("Tu sesión expiró. Inicia sesión de nuevo.")
        } catch {
            if Task.isCancelled { return }
            print("Error loading donors: \(error)")
            state = .error("No se pudieron cargar los donantes.")
        }
    }
    
    func loadAgenda() async
    {
        do {
            agenda = try await donorService.getAgenda(days: 7)
            agendaError = nil
        } catch {
            if Task.isCancelled { return }
            print("Error loading the agenda: \(error)")
            agendaError = "No se pudo cargar la agenda."
        }
    }
    
    func loadFollowUps() async
    {
        do {
            followUps = try await donorService.getFollowUps()
            followUpsError = nil
        } catch {
            if Task.isCancelled { return }
            print("Error loading the follow-ups: \(error)")
            followUpsError = "No se pudieron cargar los donantes por reprogramar."
        }
    }
    
    func loadFilters() async
    {
        do {
            filters = try await donorService.getDonorFilters()
        } catch {
            if Task.isCancelled { return }
            print("Error loading the filters: \(error)")
        }
    }
    
    func count(for segment: Segment) -> Int
    {
        donors(in: segment).count
    }
    
    func donors(in segment: Segment) -> [DonorSummary]
    {
        let all = list?.donors ?? []
        
        switch segment
        {
            case .active:
                return all.filter { $0.isActive }
            case .recover:
                return all.filter { !$0.isActive && $0.everDonated }
            case .all:
                return all
        }
    }
    
    var visibleDonors: [DonorSummary]
    {
        let text = query.trimmingCharacters(in: .whitespaces).lowercased()
        let digits = text.filter { $0.isNumber }
        
        var result = donors(in: segment).filter { donor in
            if !text.isEmpty
            {
                let phone = donor.phone.filter { $0.isNumber }
                let matchesName = donor.name.lowercased().contains(text)
                let matchesPhone = !digits.isEmpty && phone.contains(digits)
                if !matchesName && !matchesPhone { return false }
            }
            if risk != nil && donor.riskStatus != risk { return false }
            if paymentMethod != nil && donor.paymentMethod != paymentMethod { return false }
            if recolectorId != nil && donor.recolectorId != recolectorId { return false }
            if telefonistaId != nil && donor.telefonistaId != telefonistaId { return false }
            return true
        }
        
        switch sortKey
        {
            case .name:
                result.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
            case .risk:
                result.sort { riskRank($0.riskStatus) < riskRank($1.riskStatus) }
            case .lastDonation:
                result.sort { ($0.lastDonationDate ?? "") < ($1.lastDonationDate ?? "") }
        }
        
        if !sortAscending
        {
            result.reverse()
        }
        
        return result
    }
    
    func sort(by key: SortKey)
    {
        if sortKey == key
        {
            sortAscending.toggle()
        }
        else
        {
            sortKey = key
            sortAscending = key == .name
        }
        page = 0
    }
    
    func sortArrow(for key: SortKey) -> String?
    {
        if sortKey != key { return nil }
        return sortAscending ? "chevron.up" : "chevron.down"
    }
    
    func riskRank(_ code: String) -> Int
    {
        switch code
        {
            case "MEDIUM":
                return 1
            case "HIGH":
                return 2
            default:
                return 0
        }
    }
    
    var pageCount: Int
    {
        let total = visibleDonors.count
        if total == 0 { return 1 }
        return (total + pageSize - 1) / pageSize
    }
    
    var currentPage: Int
    {
        min(page, pageCount - 1)
    }
    
    var pageDonors: [DonorSummary]
    {
        let donors = visibleDonors
        let start = currentPage * pageSize
        let end = min(start + pageSize, donors.count)
        if start >= end { return [] }
        return Array(donors[start..<end])
    }
    
    var rangeText: String
    {
        let total = visibleDonors.count
        if total == 0 { return "0 donantes" }
        let start = currentPage * pageSize + 1
        let end = min(start + pageSize - 1, total)
        return "\(start)–\(end) de \(total) donantes"
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
