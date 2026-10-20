//
//  DashboardView.swift
//  PanelAdmin
//
//  Created by Alumno on 22/09/26.
//

import SwiftUI

struct DashboardView: View
{
    @State private var viewModel = DashboardViewModel()
    
    var body: some View
    {
        ZStack
        {
            VStack
            {
                VStack(alignment: .leading)
                {
                    Text("Panel de Control de Administrador")
                        .font(.system(size: 40))
                        .bold()
                    
                    Text("Cáritas de Monterrey - Gestión de Recaudación y Procuración de Fondos")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                        .bold()
                }
                .padding(.top, 32)
                
                Divider()
                    .padding(.bottom, 20)
                
                HStack(spacing: 16)
                {
                    KPI (
                        title: "Dinero Disponible",
                        value: viewModel.KPIs.availableMoney,
                        unit: "MXN"
                    )
                    .frame(maxWidth: .infinity)
                    
                    Spacer()
                    
                    KPI (
                        title: "Dinero Prometido",
                        value: viewModel.KPIs.pledgedMoney,
                        unit: "MXN"
                    )
                    .frame(maxWidth: .infinity)
                    
                    Spacer()
                    
                    KPI (
                        title: "Donantes Activos",
                        value: viewModel.KPIs.activeDonors,
                        unit: ""
                    )
                    .frame(maxWidth: .infinity)
                    
                    Spacer()
                    
                    KPI (
                        title: "Donantes en Riesgo",
                        value: viewModel.KPIs.atRiskDonors,
                        unit: ""
                    )
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                .padding(.bottom, 28)
                
                HStack(spacing: 16)
                {
                    DonationsChart()
                }
                .padding(.horizontal)
                .padding(.bottom, 28)
            }
        }
        .background(Constants.secondaryBackgroundColor)
        .task {
            await viewModel.loadKPIs()
        }
    }
}

#Preview {
    DashboardView()
}
