import SwiftUI

public struct LoginView: View {
    let configuration: AuthConfiguration
    let onLoginSuccess: (Int) -> Void
    
    @StateObject private var viewModel: LoginViewModel
    
    public init(configuration: AuthConfiguration, onLoginSuccess: @escaping (Int) -> Void) {
        self.configuration = configuration
        self.onLoginSuccess = onLoginSuccess
        _viewModel = StateObject(wrappedValue: LoginViewModel(configuration: configuration))
    }

    public var body: some View {
        VStack {
            if let logo = configuration.logo {
                logo
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220)
            }
            
            Text(configuration.title)
                .font(.system(size: 25, weight: .semibold))
                .padding(.top, 10)
                .padding(.bottom, 80)
            
            VStack(spacing: 10) {
                
                TextField("Email '\(configuration.emailDomain)'", text: $viewModel.emailInput)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .frame(width: 270)
                
                SecureField("Contraseña", text: $viewModel.passwordInput)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 270)
                
                Button(action: {
                    viewModel.executeLogin(onSuccess: onLoginSuccess)
                }) {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Iniciar sesión")
                    }
                }
                .disabled(viewModel.isLoading)
                .foregroundColor(.white)
                .padding()
                .background(configuration.accentColor)
                .cornerRadius(10)
                .padding(.top, 60)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 60)
            .frame(maxWidth: 330)
            .background(.white)
            .cornerRadius(10)
            .shadow(color: configuration.accentColor, radius: 12, x: 0, y: 0)
        }
        .padding(.bottom, 90)
        .alert("Error", isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

#Preview {
    LoginView(
        configuration: AuthConfiguration(apiBaseUrl: "https://localhost:10206/api/", role: "Admin"),
        onLoginSuccess: { _ in }
    )
}