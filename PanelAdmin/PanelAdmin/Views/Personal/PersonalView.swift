//
//  PersonalView.swift
//  PanelAdmin
//

import SwiftUI

struct PersonalView: View
{
    @State private var viewModel = PersonalViewModel()
    
    var body: some View
    {
        VStack(alignment: .leading, spacing: 16)
        {
            header
            
            switch viewModel.state
            {
                case .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                case .loggedOut(let message):
                    ContentUnavailableView(
                        "Sin sesión",
                        systemImage: "person.crop.circle.badge.xmark",
                        description: Text(message)
                    )
                
                case .error(let message):
                    ContentUnavailableView
                    {
                        Label("Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Reintentar")
                        {
                            Task { await viewModel.load() }
                        }
                    }
                
                case .ready:
                    if let summary = viewModel.report?.summary
                    {
                        kpis(summary)
                    }
                    
                    controls
                    
                    staffList
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Constants.secondaryBackgroundColor)
        .navigationTitle("Personal")
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: TelefonistaPerformance.self)
        { person in
            PersonalDetailView(
                role: .telefonistas,
                staffId: person.id,
                name: person.name,
                months: viewModel.months,
                stats: [
                    PersonalStat(label: "Llamadas realizadas", value: "\(person.totalCalls)"),
                    PersonalStat(label: "Confirmadas", value: "\(person.confirmedCalls)"),
                    PersonalStat(label: "Tasa de confirmación", value: "\(person.confirmationRate)%")
                ],
                rate: person.confirmationRate,
                rateColor: rateColor(person.confirmationRate)
            )
        }
        .navigationDestination(for: RecolectorPerformance.self)
        { person in
            PersonalDetailView(
                role: .recolectores,
                staffId: person.id,
                name: person.name,
                months: viewModel.months,
                stats: [
                    PersonalStat(label: "Recolecciones", value: "\(person.totalCollections)"),
                    PersonalStat(label: "Exitosas", value: "\(person.successfulCollections)"),
                    PersonalStat(label: "Tasa de éxito", value: "\(person.successRate)%"),
                    PersonalStat(label: "Monto recaudado", value: DonorFormat.money(person.amountCollected))
                ],
                rate: person.successRate,
                rateColor: rateColor(person.successRate)
            )
        }
        .task(id: viewModel.months)
        {
            await viewModel.load()
        }
    }
    
    private var header: some View
    {
        HStack(spacing: 12)
        {
            Text("Personal")
                .font(.system(size: 34))
                .bold()
                .foregroundColor(Constants.neutralColor)
            
            Spacer()
            
            Text("Ventana")
                .foregroundColor(.gray)
            
            Picker("Ventana", selection: $viewModel.months)
            {
                Text("3 meses").tag(3)
                Text("6 meses").tag(6)
                Text("12 meses").tag(12)
            }
            .pickerStyle(.menu)
            .tint(Constants.primaryColor)
        }
    }
    
    @ViewBuilder
    private func kpis(_ summary: PersonalSummary) -> some View
    {
        if viewModel.role == .telefonistas
        {
            HStack(spacing: 16)
            {
                DonorKPICard(
                    title: "Personal activo",
                    value: "\(summary.activeTelefonistas)",
                    note: "con llamadas en el periodo",
                    tint: Constants.primaryColor
                )
                
                DonorKPICard(
                    title: "Llamadas realizadas",
                    value: "\(summary.totalCalls)",
                    note: "últimos \(viewModel.months) meses",
                    tint: Constants.neutralColor
                )
                
                DonorKPICard(
                    title: "Confirmadas",
                    value: "\(summary.confirmedCalls)",
                    note: "donativos aceptados",
                    tint: Constants.moneyColor
                )
                
                DonorKPICard(
                    title: "Tasa de confirmación",
                    value: "\(summary.confirmationRate)%",
                    note: "confirmadas / realizadas",
                    tint: rateColor(summary.confirmationRate)
                )
            }
        }
        else
        {
            HStack(spacing: 16)
            {
                DonorKPICard(
                    title: "Personal activo",
                    value: "\(summary.activeRecolectores)",
                    note: "con recolecciones en el periodo",
                    tint: Constants.primaryColor
                )
                
                DonorKPICard(
                    title: "Recolecciones",
                    value: "\(summary.totalCollections)",
                    note: "últimos \(viewModel.months) meses",
                    tint: Constants.neutralColor
                )
                
                DonorKPICard(
                    title: "Exitosas",
                    value: "\(summary.successfulCollections)",
                    note: "tasa de éxito \(summary.successRate)%",
                    tint: rateColor(summary.successRate)
                )
                
                DonorKPICard(
                    title: "Monto recaudado",
                    value: DonorFormat.money(summary.amountCollected),
                    note: "en recolecciones exitosas",
                    tint: Constants.moneyColor
                )
            }
        }
    }
    
    private var controls: some View
    {
        HStack(spacing: 12)
        {
            Picker("Equipo", selection: $viewModel.role)
            {
                ForEach(PersonalViewModel.Role.allCases)
                { role in
                    Text(role.title).tag(role)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 400)
            
            Spacer()
            
            HStack(spacing: 2)
            {
                Text("Ordenar")
                    .foregroundColor(.gray)
                
                Picker("Ordenar", selection: $viewModel.sortKey)
                {
                    ForEach(PersonalViewModel.SortKey.allCases)
                    { key in
                        Text(key.title).tag(key)
                    }
                }
                .pickerStyle(.menu)
                .tint(Constants.primaryColor)
            }
        }
    }
    
    @ViewBuilder
    private var staffList: some View
    {
        if viewModel.totalCount == 0
        {
            ContentUnavailableView(
                "Sin personal",
                systemImage: "person.2.slash",
                description: Text("No hay personas registradas con este rol.")
            )
        }
        else
        {
            VStack(spacing: 0)
            {
                listHeader
                
                Divider()
                
                if viewModel.role == .telefonistas
                {
                    ForEach(viewModel.pageTelefonistas)
                    { person in
                        NavigationLink(value: person)
                        {
                            telefonistaRow(person)
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                    }
                }
                else
                {
                    ForEach(viewModel.pageRecolectores)
                    { person in
                        NavigationLink(value: person)
                        {
                            recolectorRow(person)
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                    }
                }
                
                Spacer()
                
                Divider()
                
                pager
            }
            .frame(maxHeight: .infinity)
            .background(.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var listHeader: some View
    {
        HStack(spacing: 12)
        {
            if viewModel.role == .telefonistas
            {
                Text("Telefonista")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Llamadas")
                    .frame(width: 120, alignment: .leading)
                Text("Confirmadas")
                    .frame(width: 130, alignment: .leading)
                Text("Confirmación")
                    .frame(width: 150, alignment: .leading)
            }
            else
            {
                Text("Recolector")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Recolecciones")
                    .frame(width: 140, alignment: .leading)
                Text("Exitosas")
                    .frame(width: 110, alignment: .leading)
                Text("Monto")
                    .frame(width: 130, alignment: .leading)
                Text("Éxito")
                    .frame(width: 150, alignment: .leading)
            }
            
            Spacer()
                .frame(width: DonorColumns.arrow)
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(.gray)
        .padding(.horizontal, 20)
        .frame(height: 44)
    }
    
    private func telefonistaRow(_ person: TelefonistaPerformance) -> some View
    {
        HStack(spacing: 12)
        {
            nameText(person.name)
            
            numberText("\(person.totalCalls)")
                .frame(width: 120, alignment: .leading)
            
            numberText("\(person.confirmedCalls)")
                .frame(width: 130, alignment: .leading)
            
            RatePill(rate: person.confirmationRate, color: rateColor(person.confirmationRate))
                .frame(width: 150, alignment: .leading)
            
            arrow
        }
        .padding(.horizontal, 20)
        .frame(height: DonorColumns.rowHeight)
        .contentShape(Rectangle())
    }
    
    private func recolectorRow(_ person: RecolectorPerformance) -> some View
    {
        HStack(spacing: 12)
        {
            nameText(person.name)
            
            numberText("\(person.totalCollections)")
                .frame(width: 140, alignment: .leading)
            
            numberText("\(person.successfulCollections)")
                .frame(width: 110, alignment: .leading)
            
            numberText(DonorFormat.money(person.amountCollected))
                .frame(width: 130, alignment: .leading)
            
            RatePill(rate: person.successRate, color: rateColor(person.successRate))
                .frame(width: 150, alignment: .leading)
            
            arrow
        }
        .padding(.horizontal, 20)
        .frame(height: DonorColumns.rowHeight)
        .contentShape(Rectangle())
    }
    
    private func nameText(_ name: String) -> some View
    {
        Text(name)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(Constants.neutralColor)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func numberText(_ text: String) -> some View
    {
        Text(text)
            .font(.system(size: 17, weight: .medium))
            .monospacedDigit()
            .foregroundColor(Constants.neutralColor)
    }
    
    private var arrow: some View
    {
        Image(systemName: "chevron.right")
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(Constants.primaryColor)
            .frame(width: 34, height: 34)
            .background(Constants.primaryColor.opacity(0.12))
            .clipShape(Circle())
            .frame(width: DonorColumns.arrow, alignment: .trailing)
    }
    
    private var pager: some View
    {
        HStack
        {
            Text(viewModel.rangeText)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text("Página \(viewModel.currentPage + 1) de \(viewModel.pageCount)")
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Spacer()
            
            pageButton("chevron.left", isDisabled: viewModel.currentPage == 0)
            {
                viewModel.previousPage()
            }
            
            pageButton("chevron.right", isDisabled: viewModel.currentPage >= viewModel.pageCount - 1)
            {
                viewModel.nextPage()
            }
        }
        .padding(.leading, 20)
        .padding(.trailing, 12)
        .padding(.vertical, 8)
    }
    
    private func pageButton(_ icon: String, isDisabled: Bool, action: @escaping () -> Void) -> some View
    {
        Button(action: action)
        {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 40, height: 40)
                .background(Constants.secondaryBackgroundColor)
                .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .foregroundColor(Constants.neutralColor)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.35 : 1)
    }
    
    private func rateColor(_ rate: Int) -> Color
    {
        if rate >= 70 { return Constants.moneyColor }
        if rate >= 50 { return Constants.warningColor }
        return Constants.dangerColor
    }
}
