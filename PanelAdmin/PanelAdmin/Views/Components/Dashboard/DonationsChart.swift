//
//  DonationsChart.swift
//  PanelAdmin
//
//  Created by Alumno on 23/09/26.
//

import SwiftUI
import Charts

struct DonationsChart: View
{
    @State private var viewModel = DonationsViewModel()
    
    var body: some View
    {
        VStack(alignment: .leading)
        {
            Text("Donaciones Recibidas por mes")
                .font(.system(size: 32))
                .bold()
            
            Chart(viewModel.monthlyDonations)
            {
                LineMark(
                    x: .value("Mes", $0.month),
                    y: .value("Dinero", $0.amount)
                )
                .foregroundStyle(Constants.primaryColor)
            }
            .frame(width: 480,height: 240)
        }
        .task {
            await viewModel.loadDonations()
        }
    }
}

#Preview {
    DonationsChart()
}
