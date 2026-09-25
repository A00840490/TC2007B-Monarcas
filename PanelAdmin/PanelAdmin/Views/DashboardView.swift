//
//  DashboardView.swift
//  PanelAdmin
//
//  Created by Alumno on 22/09/26.
//

import SwiftUI

struct DashboardView: View
{
    @State private var KPIs = DashboardKPIs(
        dineroDisponible: 0,
        dineroPrometido: 0,
        donantesActivos: 0,
        donantesEnRiesgo: 0
    )
    
    @State private var errorMesage: String?
    
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
                        value: KPIs.dineroDisponible,
                        unit: "MXN"
                    )
                    .frame(maxWidth: .infinity)
                    
                    Spacer()
                    
                    KPI (
                        title: "Dinero Prometido",
                        value: KPIs.dineroPrometido,
                        unit: "MXN"
                    )
                    .frame(maxWidth: .infinity)
                    
                    Spacer()
                    
                    KPI (
                        title: "Donantes Activos",
                        value: KPIs.donantesActivos,
                        unit: ""
                    )
                    .frame(maxWidth: .infinity)
                    
                    Spacer()
                    
                    KPI (
                        title: "Donantes en Riesgo",
                        value: KPIs.donantesEnRiesgo,
                        unit: ""
                    )
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal)
                .padding(.bottom, 28)
                
                HStack(spacing: 16)
                {
                    DonacionesGraph()
                }
                .padding(.horizontal)
                .padding(.bottom, 28)
            }
        }
        .background(Constants.secondaryBackgroundColor)
        .task {
            await cargarKPIs()
        }
    }
    
    private func cargarKPIs() async
    {
        do {
            KPIs = try await DashboardDataService().getDashboardKPIs()
        } catch {
            errorMesage = error.localizedDescription
            print("Error al cargar KPIs: \(error)")
        }
    }
}

#Preview {
    DashboardView()
}
