//
//  DonorsView.swift
//  PanelAdmin
//

import SwiftUI

struct DonorLink: Hashable
{
    let id: Int
}

struct DonorsView: View
{
    @Binding var path: NavigationPath
    
    @State private var viewModel = DonorsViewModel()
    @State private var isAddingDonor = false
    @State private var createdDonorId: Int?
    
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
                    ScrollView
                    {
                        VStack(alignment: .leading, spacing: 16)
                        {
                            if let summary = viewModel.list?.summary
                            {
                                kpis(summary)
                            }
                            
                            filters
                            
                            donorList
                            
                            DonorAgendaPanel(viewModel: viewModel)
                        }
                    }
                    .scrollIndicators(.hidden)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Constants.secondaryBackgroundColor)
        .navigationTitle("Donantes")
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: DonorLink.self)
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
    
    private var header: some View
    {
        HStack(spacing: 12)
        {
            Text("Donantes")
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
    
    private func openCreatedDonor()
    {
        if let id = createdDonorId
        {
            createdDonorId = nil
            path.append(DonorLink(id: id))
        }
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
            .frame(maxWidth: 360)
            
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
            
            HStack(spacing: 2)
            {
                Text("Riesgo")
                    .foregroundColor(.gray)
                
                Picker("Riesgo", selection: $viewModel.risk)
                {
                    Text("Todos").tag(String?.none)
                    Text("Bajo").tag(String?.some("LOW"))
                    Text("Medio").tag(String?.some("MEDIUM"))
                    Text("Alto").tag(String?.some("HIGH"))
                }
                .pickerStyle(.menu)
                .tint(Constants.primaryColor)
            }
            
            HStack(spacing: 2)
            {
                Text("Pago")
                    .foregroundColor(.gray)
                
                Picker("Pago", selection: $viewModel.paymentMethod)
                {
                    Text("Todos").tag(String?.none)
                    Text("Efectivo").tag(String?.some("CASH"))
                    Text("Transferencia").tag(String?.some("TRANSFER"))
                }
                .pickerStyle(.menu)
                .tint(Constants.primaryColor)
            }
            
            staffFilter("Recolector", selection: $viewModel.recolectorId, staff: viewModel.filters?.recolectores ?? [])
            
            staffFilter("Telefonista", selection: $viewModel.telefonistaId, staff: viewModel.filters?.telefonistas ?? [])
        }
    }
    
    private func staffFilter(_ title: String, selection: Binding<Int?>, staff: [AssignedStaff]) -> some View
    {
        HStack(spacing: 2)
        {
            Text(title)
                .foregroundColor(.gray)
            
            Picker(title, selection: selection)
            {
                Text("Todos").tag(Int?.none)
                
                ForEach(staff)
                { member in
                    Text("\(member.name) (\(member.donorCount))").tag(Int?.some(member.id))
                }
            }
            .pickerStyle(.menu)
            .tint(Constants.primaryColor)
        }
    }
    
    private var donorList: some View
    {
        VStack(spacing: 0)
        {
            listHeader
            
            Divider()
            
            ForEach(viewModel.pageDonors)
            { donor in
                NavigationLink(value: DonorLink(id: donor.id))
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
}

#Preview {
    NavigationStack
    {
        DonorsView(path: .constant(NavigationPath()))
    }
}
