//
//  DonorsView.swift
//  PanelAdmin
//

import SwiftUI

/// "Donantes activos": indicators, filters and a paged list that never
/// scrolls. Each row opens the donor's screen (DonorDetailView).
struct DonorsView: View
{
    /// The tab's navigation path, to open a donor that was just created.
    @Binding var path: NavigationPath
    
    @State private var viewModel = DonorsViewModel()
    @State private var isAddingDonor = false
    /// Donor just created; its screen opens when the form closes.
    @State private var createdDonorId: Int?
    
    /// Navigation value for a donor opened by id instead of from a row.
    private struct CreatedDonor: Hashable
    {
        let id: Int
    }
    
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
                    if let summary = viewModel.list?.summary
                    {
                        kpis(summary)
                    }
                    filters
                    donorList
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Constants.secondaryBackgroundColor)
        // The title is the back button's label in the donor's screen
        .navigationTitle("Donantes")
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: DonorSummary.self)
        { donor in
            DonorDetailView(donorId: donor.id, months: viewModel.months)
        }
        .navigationDestination(for: CreatedDonor.self)
        { donor in
            DonorDetailView(donorId: donor.id, months: viewModel.months)
        }
        .sheet(isPresented: $isAddingDonor, onDismiss: openCreatedDonor)
        {
            NewDonorSheet
            { id in
                createdDonorId = id
                Task { await viewModel.load() }
            }
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
            Text("Donantes activos")
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
            
            Button
            {
                isAddingDonor = true
            } label: {
                Label("Nuevo donante", systemImage: "plus")
                    .font(.system(size: 17, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(Constants.primaryColor)
        }
    }
    
    /// Opens the screen of the donor that was just created, so the admin can
    /// schedule its first call or collection.
    private func openCreatedDonor()
    {
        guard let id = createdDonorId else { return }
        createdDonorId = nil
        path.append(CreatedDonor(id: id))
    }
    
    private func kpis(_ summary: DonorListSummary) -> some View
    {
        HStack(spacing: 16)
        {
            DonorKPICard(
                title: "Donantes activos",
                value: "\(summary.activeDonors)",
                note: "de \(summary.totalDonors) registrados",
                tint: Constants.primaryColor
            )
            
            DonorKPICard(
                title: "Con promesa mensual",
                value: "\(summary.donorsWithPledge)",
                note: "\(DonorFormat.money(summary.monthlyCommitted)) comprometidos al mes",
                tint: Constants.pledgeColor
            )
            
            DonorKPICard(
                title: "Recaudado por activos",
                value: DonorFormat.money(summary.raisedByActive),
                note: "últimos \(viewModel.months) meses",
                tint: Constants.moneyColor
            )
        }
    }
    
    // MARK: Filters
    
    private struct FilterOption<Value: Hashable>: Identifiable
    {
        let value: Value
        let title: String
        var id: Value { value }
    }
    
    private var filters: some View
    {
        HStack(spacing: 12)
        {
            Picker("Segmento", selection: $viewModel.segment)
            {
                ForEach(DonorsViewModel.Segment.allCases)
                { segment in
                    Text("\(segment.title) \(viewModel.count(for: segment))").tag(segment)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 400)
            
            HStack(spacing: 8)
            {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Buscar por nombre o teléfono", text: $viewModel.query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(.white)
            .cornerRadius(10)
            
            filterMenu(
                "Riesgo",
                selection: $viewModel.risk,
                options: [
                    FilterOption(value: "LOW", title: "Bajo"),
                    FilterOption(value: "MEDIUM", title: "Medio"),
                    FilterOption(value: "HIGH", title: "Alto"),
                ]
            )
            
            filterMenu(
                "Pago",
                selection: $viewModel.paymentMethod,
                options: [
                    FilterOption(value: "CASH", title: "Efectivo"),
                    FilterOption(value: "TRANSFER", title: "Transferencia"),
                ]
            )
            
            filterMenu(
                "Recolector",
                selection: $viewModel.recolectorId,
                options: (viewModel.list?.recolectores ?? []).map { FilterOption(value: $0.id, title: $0.name) }
            )
        }
    }
    
    private func filterMenu<Value: Hashable>(
        _ title: String,
        selection: Binding<Value?>,
        options: [FilterOption<Value>]
    ) -> some View
    {
        HStack(spacing: 2)
        {
            Text(title)
                .foregroundColor(.gray)
            
            Picker(title, selection: selection)
            {
                Text("Todos").tag(Value?.none)
                
                ForEach(options)
                { option in
                    Text(option.title).tag(Value?.some(option.value))
                }
            }
            .pickerStyle(.menu)
            .tint(Constants.primaryColor)
        }
    }
    
    // MARK: List
    
    private var donorList: some View
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
    
    private var listHeader: some View
    {
        HStack(spacing: 12)
        {
            sortButton("Donante", key: .name)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            sortButton("Riesgo", key: .risk)
                .frame(width: DonorColumns.risk, alignment: .leading)
            
            sortButton("Última donación", key: .lastDonation)
                .frame(width: DonorColumns.lastDonation, alignment: .leading)
            
            Spacer()
                .frame(width: DonorColumns.arrow)
        }
        .padding(.horizontal, 20)
        .frame(height: 44)
    }
    
    private func sortButton(_ title: String, key: DonorsViewModel.SortKey) -> some View
    {
        Button
        {
            viewModel.sort(by: key)
        } label: {
            HStack(spacing: 4)
            {
                Text(title)
                
                if let arrow = viewModel.sortArrow(for: key)
                {
                    Image(systemName: arrow)
                        .font(.system(size: 11, weight: .bold))
                }
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.gray)
        }
        .buttonStyle(.plain)
    }
    
    private var rows: some View
    {
        VStack(spacing: 0)
        {
            ForEach(viewModel.pageDonors)
            { donor in
                NavigationLink(value: donor)
                {
                    DonorRow(donor: donor)
                }
                .buttonStyle(.plain)
                
                Divider()
            }
            
            if viewModel.visibleDonors.isEmpty
            {
                Text("Ningún donante coincide con los filtros.")
                    .foregroundColor(.gray)
                    .padding(.vertical, 40)
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
}

#Preview {
    NavigationStack
    {
        DonorsView(path: .constant(NavigationPath()))
    }
}
