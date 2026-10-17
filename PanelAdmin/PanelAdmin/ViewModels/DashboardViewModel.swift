//
//  DashboardViewModel.swift
//  PanelAdmin
//

import Foundation
import Observation

@Observable
class DashboardViewModel
{
    var KPIs = DashboardKPIs(
        availableMoney: 0,
        pledgedMoney: 0,
        activeDonors: 0,
        atRiskDonors: 0
    )
    
    var errorMessage: String?
    
    private let dataService: DashboardDataService
    
    init(dataService: DashboardDataService = DashboardDataService())
    {
        self.dataService = dataService
    }
    
    func loadKPIs() async
    {
        do {
            KPIs = try await dataService.getDashboardKPIs()
        } catch {
            errorMessage = error.localizedDescription
            print("Error loading KPIs: \(error)")
        }
    }
}
