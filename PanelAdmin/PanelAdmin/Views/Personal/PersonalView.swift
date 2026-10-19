//
//  PersonalView.swift
//  PanelAdmin
//

import SwiftUI

/// "Personal": performance of telefonistas (calls) and recolectores (collections)
/// in the selected window.
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
    
    // MARK: Header and indicators
    
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
    
    private func kpis(_ summary: PersonalSummary) -> some View
    {
        HStack(spacing: 16)
        {
            switch viewModel.role
            {
                case .telefonistas:
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
                
                case .recolectores:
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
    
    // MARK: Controls and list
    
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
            
            // Same look as the filter pickers of the donors screen
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
    
    /// Columns after the name; they change with the team.
    private var columns: [PersonalColumn]
    {
        switch viewModel.role
        {
            case .telefonistas:
                return [
                    PersonalColumn(title: "Llamadas", width: 120),
                    PersonalColumn(title: "Confirmadas", width: 130),
                    PersonalColumn(title: "Confirmación", width: PersonalColumn.rateWidth)
                ]
            case .recolectores:
                return [
                    PersonalColumn(title: "Recolecciones", width: 140),
                    PersonalColumn(title: "Exitosas", width: 110),
                    PersonalColumn(title: "Monto", width: 130),
                    PersonalColumn(title: "Éxito", width: PersonalColumn.rateWidth)
                ]
        }
    }
    
    @ViewBuilder
    private var staffList: some View
    {
        if viewModel.isEmpty
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
                
                // The rows go in an overlay so they never change the height
                // available; that height decides how many rows fit per page.
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onGeometryChange(for: CGFloat.self)
                    { proxy in
                        proxy.size.height
                    } action: { height in
                        viewModel.pageSize = max(3, Int(height / (DonorColumns.rowHeight + 1)))
                    }
                    .overlay(alignment: .top)
                    {
                        rows
                    }
                    .clipped()
                
                Divider()
                
                pager
            }
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
            Text(viewModel.role == .telefonistas ? "Telefonista" : "Recolector")
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(columns)
            { column in
                Text(column.title)
                    .frame(width: column.width, alignment: .leading)
            }
            
            Spacer()
                .frame(width: DonorColumns.arrow)
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(.gray)
        .padding(.horizontal, 20)
        .frame(height: 44)
    }
    
    private var rows: some View
    {
        VStack(spacing: 0)
        {
            switch viewModel.role
            {
                case .telefonistas:
                    ForEach(viewModel.pageTelefonistas)
                    { person in
                        NavigationLink(value: person)
                        {
                            PersonalRow(
                                name: person.name,
                                cells: [
                                    PersonalCell(text: "\(person.totalCalls)", width: columns[0].width),
                                    PersonalCell(text: "\(person.confirmedCalls)", width: columns[1].width)
                                ],
                                rate: person.confirmationRate,
                                rateColor: rateColor(person.confirmationRate)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                    }
                
                case .recolectores:
                    ForEach(viewModel.pageRecolectores)
                    { person in
                        NavigationLink(value: person)
                        {
                            PersonalRow(
                                name: person.name,
                                cells: [
                                    PersonalCell(text: "\(person.totalCollections)", width: columns[0].width),
                                    PersonalCell(text: "\(person.successfulCollections)", width: columns[1].width),
                                    PersonalCell(text: DonorFormat.money(person.amountCollected), width: columns[2].width)
                                ],
                                rate: person.successRate,
                                rateColor: rateColor(person.successRate)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        Divider()
                    }
            }
        }
    }
    
    private var pager: some View
    {
        HStack
        {
            Text(viewModel.rangeText)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Spacer()
            
            HStack(spacing: 6)
            {
                ForEach(0..<viewModel.pageCount, id: \.self)
                { index in
                    Circle()
                        .fill(index == viewModel.currentPage ? Constants.primaryColor : Color.gray.opacity(0.3))
                        .frame(width: 7, height: 7)
                }
            }
            
            Spacer()
            
            HStack(spacing: 6)
            {
                pageButton("chevron.left", label: "Página anterior", isDisabled: viewModel.currentPage == 0)
                {
                    viewModel.previousPage()
                }
                
                pageButton("chevron.right", label: "Página siguiente", isDisabled: viewModel.currentPage >= viewModel.pageCount - 1)
                {
                    viewModel.nextPage()
                }
            }
        }
        .padding(.leading, 20)
        .padding(.trailing, 12)
        .padding(.vertical, 8)
    }
    
    private func pageButton(_ icon: String, label: String, isDisabled: Bool, action: @escaping () -> Void) -> some View
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
        .accessibilityLabel(label)
    }
    
    /// Green for a good rate, amber for a medium one, red for a low one.
    private func rateColor(_ rate: Int) -> Color
    {
        switch PersonalViewModel.level(for: rate)
        {
            case .good:
                return Constants.moneyColor
            case .medium:
                return Constants.warningColor
            case .low:
                return Constants.dangerColor
        }
    }
}

/// A column after the name in the list header.
private struct PersonalColumn: Identifiable
{
    static let rateWidth: CGFloat = 150
    
    let title: String
    let width: CGFloat
    var id: String { title }
}

/// A value of a row, with the width of its column.
private struct PersonalCell
{
    let text: String
    let width: CGFloat
}

/// One person in the list, same format as a donor's row: name, a few
/// columns, the rate as a colored pill and the arrow that opens the detail.
private struct PersonalRow: View
{
    let name: String
    let cells: [PersonalCell]
    let rate: Int
    let rateColor: Color
    
    var body: some View
    {
        HStack(spacing: 12)
        {
            Text(name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Constants.neutralColor)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ForEach(Array(cells.enumerated()), id: \.offset)
            { _, cell in
                Text(cell.text)
                    .font(.system(size: 17, weight: .medium))
                    .monospacedDigit()
                    .foregroundColor(Constants.neutralColor)
                    .frame(width: cell.width, alignment: .leading)
            }
            
            RatePill(rate: rate, color: rateColor)
                .frame(width: PersonalColumn.rateWidth, alignment: .leading)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(Constants.primaryColor)
                .frame(width: 34, height: 34)
                .background(Constants.primaryColor.opacity(0.12))
                .clipShape(Circle())
                .frame(width: DonorColumns.arrow, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .frame(height: DonorColumns.rowHeight)
        .contentShape(Rectangle())
    }
}
