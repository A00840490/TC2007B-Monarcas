//
//  ScheduleContactSheet.swift
//  PanelAdmin
//

import SwiftUI

/// Form to schedule a call (assigned to a Telefonista) or a collection
/// (assigned to a Recolector) for one donor.
struct ScheduleContactSheet: View
{
    let donorName: String
    /// Called after the call or collection is saved.
    let onSaved: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ScheduleContactViewModel
    
    init(kind: ScheduleKind, donor: DonorDetail, onSaved: @escaping () -> Void)
    {
        // By default, the same person who handles the donor's pledge.
        let pledge = donor.pledge
        _viewModel = State(initialValue: ScheduleContactViewModel(
            kind: kind,
            donorId: donor.id,
            suggestedAmount: pledge?.amount,
            suggestedAssigneeName: kind == .call ? pledge?.telefonistaName : pledge?.recolectorName
        ))
        donorName = donor.name
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
                    LabeledContent("Donante", value: donorName)
                }
                
                Section(kind.assigneeTitle)
                {
                    assigneePicker
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
                await viewModel.loadStaff()
            }
        }
        .tint(Constants.primaryColor)
        .interactiveDismissDisabled(viewModel.isSaving)
    }
    
    @ViewBuilder
    private var assigneePicker: some View
    {
        switch viewModel.staffState
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
                        Task { await viewModel.loadStaff() }
                    }
                }
            
            case .ready:
                if viewModel.staff.isEmpty
                {
                    Text(kind.noStaffMessage)
                        .foregroundColor(.gray)
                }
                else
                {
                    Picker(kind.assigneeTitle, selection: $viewModel.assigneeId)
                    {
                        ForEach(viewModel.staff)
                        { member in
                            Text(member.name).tag(Int?.some(member.id))
                        }
                    }
                }
        }
    }
}
