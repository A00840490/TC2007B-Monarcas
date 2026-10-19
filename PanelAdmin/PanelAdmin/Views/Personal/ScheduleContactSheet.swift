//
//  ScheduleContactSheet.swift
//  PanelAdmin
//

import SwiftUI

/// Form to schedule a call for a Telefonista or a collection for a Recolector.
/// The staff member comes from the screen it opens from; the admin picks the donor.
struct ScheduleContactSheet: View
{
    let staffName: String
    /// Window used to load the donor list (it only decides who is active).
    let months: Int
    /// Called after the call or collection is saved.
    let onSaved: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ScheduleContactViewModel
    
    init(kind: ScheduleKind, staffId: Int, staffName: String, months: Int, onSaved: @escaping () -> Void)
    {
        _viewModel = State(initialValue: ScheduleContactViewModel(kind: kind, staffId: staffId))
        self.staffName = staffName
        self.months = months
        self.onSaved = onSaved
    }
    
    private var kind: ScheduleKind { viewModel.kind }
    
    var body: some View
    {
        NavigationStack
        {
            Form
            {
                Section
                {
                    LabeledContent(kind.assigneeTitle, value: staffName)
                }
                
                Section("Donante")
                {
                    donorSelector
                }
                
                Section("Fecha y hora")
                {
                    DatePicker(
                        "Fecha",
                        selection: $viewModel.date,
                        in: Calendar.current.startOfDay(for: .now)...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                
                if kind == .collection
                {
                    Section("Monto esperado")
                    {
                        HStack(spacing: 4)
                        {
                            Text("$")
                                .foregroundColor(.gray)
                            
                            TextField("Opcional", text: $viewModel.amountText)
                                .keyboardType(.decimalPad)
                        }
                    }
                }
                
                Section(kind.notesTitle)
                {
                    TextField("Opcional", text: $viewModel.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if let message = viewModel.problem ?? viewModel.errorMessage
                {
                    Section
                    {
                        Text(message)
                            .foregroundColor(Constants.dangerColor)
                    }
                }
            }
            .navigationTitle(kind.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar
            {
                ToolbarItem(placement: .cancellationAction)
                {
                    Button("Cancelar")
                    {
                        dismiss()
                    }
                    .disabled(viewModel.isSaving)
                }
                
                ToolbarItem(placement: .confirmationAction)
                {
                    if viewModel.isSaving
                    {
                        ProgressView()
                    }
                    else
                    {
                        Button("Agendar")
                        {
                            Task
                            {
                                if await viewModel.save()
                                {
                                    onSaved()
                                    dismiss()
                                }
                            }
                        }
                        .disabled(!viewModel.canSave)
                    }
                }
            }
            .task
            {
                await viewModel.loadDonors(months: months)
            }
        }
        .tint(Constants.primaryColor)
        .interactiveDismissDisabled(viewModel.isSaving)
    }
    
    @ViewBuilder
    private var donorSelector: some View
    {
        switch viewModel.donorsState
        {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity)
            
            case .error(let message):
                HStack
                {
                    Text(message)
                        .foregroundColor(Constants.dangerColor)
                    
                    Spacer()
                    
                    Button("Reintentar")
                    {
                        Task { await viewModel.loadDonors(months: months) }
                    }
                }
            
            case .ready:
                if viewModel.donors.isEmpty
                {
                    Text("No hay donantes registrados.")
                        .foregroundColor(.gray)
                }
                else
                {
                    NavigationLink
                    {
                        DonorPickerList(
                            donors: viewModel.donors,
                            selectedId: viewModel.donorId
                        )
                        { donor in
                            viewModel.select(donor)
                        }
                    } label: {
                        HStack
                        {
                            Text("Donante")
                            
                            Spacer()
                            
                            Text(viewModel.selectedDonor?.name ?? "Seleccionar")
                                .foregroundColor(viewModel.selectedDonor == nil ? .gray : Constants.neutralColor)
                        }
                    }
                }
        }
    }
}

/// Searchable list to choose the donor.
private struct DonorPickerList: View
{
    let donors: [DonorSummary]
    let selectedId: Int?
    let onSelect: (DonorSummary) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    
    private var filtered: [DonorSummary]
    {
        let text = query.trimmingCharacters(in: .whitespaces).lowercased()
        let digits = text.filter(\.isNumber)
        guard !text.isEmpty else { return donors }
        
        return donors.filter { donor in
            donor.name.lowercased().contains(text)
                || (!digits.isEmpty && donor.phone.filter(\.isNumber).contains(digits))
        }
    }
    
    var body: some View
    {
        List
        {
            ForEach(filtered)
            { donor in
                Button
                {
                    onSelect(donor)
                    dismiss()
                } label: {
                    HStack
                    {
                        VStack(alignment: .leading, spacing: 2)
                        {
                            Text(donor.name)
                                .foregroundColor(Constants.neutralColor)
                            
                            if !donor.phone.isEmpty
                            {
                                Text(donor.phone)
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Spacer()
                        
                        if donor.id == selectedId
                        {
                            Image(systemName: "checkmark")
                                .foregroundColor(Constants.primaryColor)
                        }
                    }
                }
            }
            
            if filtered.isEmpty
            {
                Text("Ningún donante coincide con la búsqueda.")
                    .foregroundColor(.gray)
            }
        }
        .searchable(text: $query, prompt: "Buscar por nombre o teléfono")
        .navigationTitle("Donante")
        .navigationBarTitleDisplayMode(.inline)
    }
}
