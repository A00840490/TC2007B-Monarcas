//
//  ProfileView.swift
//  PanelAdmin
//

import SwiftUI
import CaritasAuth

struct ProfileView: View
{
    @State private var viewModel = ProfileViewModel()
    
    /// Goes back to the login after logging out (AuthGate's `logout`).
    var onLogout: (() -> Void)? = nil
    
    var body: some View
    {
        VStack(spacing: 24)
        {
            switch viewModel.state
            {
                case .loading:
                    ProgressView()
                
                case .ready(let profile):
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 96))
                        .foregroundColor(Constants.primaryColor)
                    
                    VStack(spacing: 16)
                    {
                        infoRow(title: "Nombre", value: profile.name, icon: "person")
                        infoRow(title: "Correo", value: profile.email, icon: "envelope")
                        infoRow(title: "Rol", value: AuthConfiguration.roleDisplayName(profile.role), icon: "person.badge.key")
                    }
                    .frame(maxWidth: 520)
                    
                    Button("Cerrar sesión", role: .destructive)
                    {
                        viewModel.logOut()
                        onLogout?()
                    }
                    .buttonStyle(.bordered)
                
                case .loggedOut(let message):
                    ContentUnavailableView
                    {
                        Label("Sin sesión", systemImage: "person.crop.circle.badge.xmark")
                    } description: {
                        Text(message)
                    } actions: {
                        if let onLogout
                        {
                            Button("Iniciar sesión", action: onLogout)
                        }
                    }
                
                case .error(let message):
                    ContentUnavailableView
                    {
                        Label("Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(message)
                    } actions: {
                        Button("Reintentar")
                        {
                            Task { await viewModel.loadProfile(force: true) }
                        }
                    }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Constants.secondaryBackgroundColor)
        .navigationTitle("Mi perfil")
        .toolbar
        {
            ToolbarItem(placement: .topBarTrailing)
            {
                Button
                {
                    Task { await viewModel.loadProfile(force: true) }
                } label: {
                    Label("Actualizar", systemImage: "arrow.clockwise")
                }
            }
        }
        .task { await viewModel.loadProfile() }
    }
    
    private func infoRow(title: String, value: String, icon: String) -> some View
    {
        HStack(spacing: 16)
        {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(Constants.primaryColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4)
            {
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                
                Text(value)
                    .font(.system(size: 22))
                    .foregroundColor(Constants.neutralColor)
            }
            
            Spacer()
        }
        .padding()
        .background(.white)
        .cornerRadius(10)
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
