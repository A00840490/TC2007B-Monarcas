//
//  DonationsViewModel.swift
//  PanelAdmin
//

import Foundation
import Observation

@Observable
class DonationsViewModel
{
    var monthlyDonations: [MonthlyDonation] = []
    
    private let dataService: DashboardDataService
    
    init(dataService: DashboardDataService = DashboardDataService())
    {
        self.dataService = dataService
    }
    
    func loadDonations() async
    {
        do {
            monthlyDonations = try await dataService.getMonthlyDonations()
        } catch {
            print("Error loading donations: \(error)")
        }
    }
}
