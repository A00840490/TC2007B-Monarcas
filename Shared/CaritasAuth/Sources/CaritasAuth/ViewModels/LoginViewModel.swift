import Foundation
import Combine

@MainActor
class LoginViewModel: ObservableObject {
    
    @Published var emailInput = ""
    @Published var passwordInput = ""
    
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var errorMessage = ""
    
    let configuration: AuthConfiguration
    
    private let caritasApi: AuthAPIClient
    private let sessionStore: SessionStore
    
    init(configuration: AuthConfiguration) {
        self.configuration = configuration
        self.caritasApi = AuthAPIClient(baseUrl: configuration.apiBaseUrl)
        self.sessionStore = SessionStore(key: configuration.sessionKey)
    }
    
    func executeLogin(onSuccess: @escaping (Int) -> Void) {

        let cleanEmail = emailInput.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanPassword = passwordInput.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanEmail.isEmpty || cleanPassword.isEmpty {
            showError("Por favor, llena todos los campos sin dejar espacios vacíos.")
            return
        }
        
        if cleanEmail.contains(" ") || cleanPassword.contains(" ") {
            showError("Los campos no pueden contener espacios en blanco.")
            return
        }
        
        if !cleanEmail.hasSuffix(configuration.emailDomain) {
            showError("Debes ingresar un correo institucional válido (\(configuration.emailDomain)).")
            return
        }
        
        isLoading = true
        
        Task {
            
            do {

                let credentials = UserCredentials(
                    email: cleanEmail,
                    password: cleanPassword,
                    role: configuration.role
                )
                let response = try await caritasApi.postLoginAttempt(credentials)
                
                sessionStore.save(token: response.token)
                
                isLoading = false
                onSuccess(response.userId)

            } catch AuthAPIError.rejected(statusCode: 403) {

                isLoading = false
                showError("Este usuario no tiene acceso a esta app (\(AuthConfiguration.roleDisplayName(configuration.role))).")

            } catch AuthAPIError.rejected {

                isLoading = false
                showError("Correo o contraseña incorrectos.")

            } catch {

                print("Error: \(error)")
                isLoading = false
                showError("No se pudo conectar con el servidor.")

            }

        }

    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showAlert = true
    }
}