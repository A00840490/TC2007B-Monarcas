import SwiftUI

struct LoginView: View {
    let onLoginSuccess: (Int) -> Void
    
    @StateObject private var loginElements = LoginAttemptService()

    var body: some View {
        VStack {
            Text("Panel de Administrador")
                .font(.system(size: 25, weight: .semibold))
                .padding(.top, 10)
                .padding(.bottom, 80)
            
            VStack(spacing: 10) {
                
                TextField("Email '@caritas.org.mx'", text: $loginElements.emailInput)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .frame(width: 270)
                
                SecureField("Contraseña", text: $loginElements.passwordInput)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 270)
                
                Button(action: {
                    loginElements.executeLogin(onSuccess: onLoginSuccess)
                }) {
                    if loginElements.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Iniciar sesión")
                    }
                }
                .disabled(loginElements.isLoading)
                .foregroundColor(.white)
                .padding()
                .background(Color.standardDarkerColor)
                .cornerRadius(10)
                .padding(.top, 60)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 60)
            .frame(maxWidth: 330)
            .background(.white)
            .cornerRadius(10)
            .shadow(color: Color.standardDarkerColor, radius: 12, x: 0, y: 0)
        }
        .padding(.bottom, 90)
        .alert("Error", isPresented: $loginElements.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(loginElements.errorMessage)
        }
    }
}

#Preview {
    LoginView(onLoginSuccess: { _ in })
}