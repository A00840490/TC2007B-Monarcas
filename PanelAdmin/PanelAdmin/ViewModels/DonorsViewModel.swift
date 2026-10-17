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
    private(set) var list: DonorList?
    
    /// Window that defines an active donor (3, 6 or 12 months).
    var months = 6
    
    // Filters; changing any of them goes back to the first page.
    var segment: Segment = .active { didSet { page = 0 } }
    var query = "" { didSet { page = 0 } }
    var risk: String? = nil { didSet { page = 0 } }
    var paymentMethod: String? = nil { didSet { page = 0 } }
    var recolectorId: Int? = nil { didSet { page = 0 } }
    
    private(set) var sortKey: SortKey = .lastDonation
    private(set) var sortAscending = false
    
    /// The list never scrolls: the view sets how many rows fit and the rest go
    /// to the next pages.
    var pageSize = 6
    private(set) var page = 0
    
    private let donorService: DonorService
    
    init(donorService: DonorService = DonorService())
    {
        self.donorService = donorService
    }
    
    func load() async
    {
        if list == nil { state = .loading }
        
        do {
            list = try await donorService.getDonors(months: months)
            state = .ready
        } catch DonorServiceError.invalidSession {
            state = .loggedOut("Tu sesión expiró. Inicia sesión de nuevo.")
        } catch {
            print("Error loading donors: \(error)")
            state = .error("No se pudieron cargar los donantes.")
        }
    }
    
    // MARK: Segments, filters and order
    
    func count(for segment: Segment) -> Int
    {
        donors(in: segment).count
    }
    
    private func donors(in segment: Segment) -> [DonorSummary]
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
        let digits = text.filter(\.isNumber)
        
        let filtered = donors(in: segment).filter { donor in
            let matchesText = text.isEmpty
                || donor.name.lowercased().contains(text)
                || (!digits.isEmpty && donor.phone.filter(\.isNumber).contains(digits))
            return matchesText
                && (risk == nil || donor.riskStatus == risk)
                && (paymentMethod == nil || donor.paymentMethod == paymentMethod)
                && (recolectorId == nil || donor.recolectorId == recolectorId)
        }
        
        return filtered.sorted { a, b in
            let order = compare(a, b)
            return sortAscending ? order == .orderedAscending : order == .orderedDescending
        }
    }
    
    func sort(by key: SortKey)
    {
        if sortKey == key {
            sortAscending.toggle()
        } else {
            sortKey = key
            sortAscending = key == .name
        }
        page = 0
    }
    
    func sortArrow(for key: SortKey) -> String?
    {
        guard sortKey == key else { return nil }
        return sortAscending ? "chevron.up" : "chevron.down"
    }
    
    private func compare(_ a: DonorSummary, _ b: DonorSummary) -> ComparisonResult
    {
        switch sortKey
        {
            case .name:
                return a.name.localizedCompare(b.name)
            case .risk:
                return compareValues(Self.riskRank(a.riskStatus), Self.riskRank(b.riskStatus))
            case .lastDonation:
                return compareValues(a.lastDonationDate ?? "", b.lastDonationDate ?? "")
        }
    }
    
    private func compareValues<T: Comparable>(_ a: T, _ b: T) -> ComparisonResult
    {
        if a < b { return .orderedAscending }
        if a > b { return .orderedDescending }
        return .orderedSame
    }
    
    private static func riskRank(_ code: String) -> Int
    {
        ["LOW": 0, "MEDIUM": 1, "HIGH": 2][code] ?? 0
    }
    
    // MARK: Pages
    
    var pageCount: Int
    {
        max(1, Int((Double(visibleDonors.count) / Double(max(pageSize, 1))).rounded(.up)))
    }
    
    var currentPage: Int
    {
        min(page, pageCount - 1)
    }
    
    var pageDonors: [DonorSummary]
    {
        let donors = visibleDonors
        let start = currentPage * pageSize
        guard start < donors.count else { return [] }
        return Array(donors[start..<min(start + pageSize, donors.count)])
    }
    
    /// "1–6 de 13 donantes"
    var rangeText: String
    {
        let total = visibleDonors.count
        guard total > 0 else { return "0 donantes" }
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
