//
//  ScheduleContactSheet.swift
//  PanelAdmin
//

import SwiftUI

struct ScheduleContactSheet: View
{
    let staffName: String
    let months: Int
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
    
    var body: some View
    {
        NavigationStack
        {
            Form
            {
                Section
                {
                    LabeledContent(viewModel.kind.assigneeTitle, value: staffName)
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
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                
                if viewModel.kind == .collection
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
                
                Section(viewModel.kind.notesTitle)
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
            .navigationTitle(viewModel.kind.title)
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
        if viewModel.isLoadingDonors
        {
            ProgressView()
                .frame(maxWidth: .infinity)
        }
        else if let error = viewModel.donorsError
        {
            HStack
            {
                Text(error)
                    .foregroundColor(Constants.dangerColor)
                
                Spacer()
                
                Button("Reintentar")
                {
                    Task { await viewModel.loadDonors(months: months) }
                }
            }
        }
        else if viewModel.donors.isEmpty
        {
            Text("No hay donantes registrados.")
                .foregroundColor(.gray)
        }
        else
        {
            NavigationLink
            {
                DonorPickerList(viewModel: viewModel)
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

struct DonorPickerList: View
{
    let viewModel: ScheduleContactViewModel
    
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    
    var filteredDonors: [DonorSummary]
    {
        if query.isEmpty { return viewModel.donors }
        
        let text = query.lowercased()
        return viewModel.donors.filter { donor in
            donor.name.lowercased().contains(text) || donor.phone.contains(text)
        }
    }
    
    var body: some View
    {
        List
        {
            ForEach(filteredDonors)
            { donor in
                Button
                {
                    viewModel.select(donor)
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
                        
                        if donor.id == viewModel.donorId
                        {
                            Image(systemName: "checkmark")
                                .foregroundColor(Constants.primaryColor)
                        }
                    }
                }
            }
            
            if filteredDonors.isEmpty
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
