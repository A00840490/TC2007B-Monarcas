//
//  NewDonorSheet.swift
//  PanelAdmin
//

import SwiftUI

/// Form to register a donor (POST /api/adminPanel/donors).
struct NewDonorSheet: View
{
    /// Receives the new donor's id after it is saved.
    let onCreated: (Int) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = NewDonorViewModel()
    
    private let riskOptions = ["LOW", "MEDIUM", "HIGH"]
    
    var body: some View
    {
        NavigationStack
        {
            Form
            {
                Section("Datos del donante")
                {
                    TextField("Nombre completo", text: $viewModel.name)
                        .textContentType(.name)
                    
                    TextField("Teléfono", text: $viewModel.phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                    
                    TextField("Dirección", text: $viewModel.address, axis: .vertical)
                        .textContentType(.fullStreetAddress)
                        .lineLimit(2...4)
                }
                
                Section("Riesgo")
                {
                    Picker("Riesgo", selection: $viewModel.riskStatus)
                    {
                        ForEach(riskOptions, id: \.self)
                        { code in
                            Text(DonorFormat.risk(code)).tag(code)
                        }
                    }
                    .pickerStyle(.segmented)
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
            .navigationTitle("Nuevo donante")
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
                        Button("Guardar")
                        {
                            Task
                            {
                                if let id = await viewModel.save()
                                {
                                    onCreated(id)
                                    dismiss()
                                }
                            }
                        }
                        .disabled(!viewModel.canSave)
                    }
                }
            }
        }
        .tint(Constants.primaryColor)
        .interactiveDismissDisabled(viewModel.isSaving)
    }
}

#Preview {
    NewDonorSheet { _ in }
}
