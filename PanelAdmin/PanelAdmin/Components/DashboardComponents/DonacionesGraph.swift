//
//  DonacionesGraph.swift
//  PanelAdmin
//
//  Created by Alumno on 23/09/26.
//

import SwiftUI
import Charts

struct DonacionesGraph: View
{
    @State private var donacionesMeses: [DonacionesMeses] = []
    
    var body: some View
    {
        VStack(alignment: .leading)
        {
            Text("Donaciones Recibidas por mes")
                .font(.system(size: 32))
                .bold()
            
            Chart(donacionesMeses)
            {
                LineMark(
                    x: .value("Mes", $0.mes),
                    y: .value("Dinero", $0.monto)
                )
                .foregroundStyle(Constants.primaryColor)
            }
            .frame(width: 480,height: 240)
        }
        .task {
            await cargarDonaciones()
        }
    }
    
    private func cargarDonaciones() async
    {
        do {
            donacionesMeses = try await DashboardDataService().getDonacionesMeses()
        } catch {
            print("Error al cargar donaciones: \(error)")
        }
    }
}

#Preview {
    DonacionesGraph()
}
