import Foundation
import Combine

@MainActor
class LoginAttemptService: ObservableObject {
    
    @Published var emailInput = ""
    @Published var passwordInput = ""
    
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var errorMessage = ""
    
    private let caritasApi: CaritasApi
    
    init(caritasApi: CaritasApi = CaritasApi()) {
        self.caritasApi = caritasApi
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
        
        if !cleanEmail.hasSuffix("@caritas.org.mx") {
            showError("Debes ingresar un correo institucional válido (@caritas.org.mx).")
            return
        }
        
        isLoading = true
        
        Task {
            
            do {

                let credentials = userCredentials(caritasEMail: cleanEmail, password: cleanPassword)
                let response = try await caritasApi.postloginAttempt(credentials)
                
                KeychainHelper.shared.save(response.userId, forKey: "userDatabaseId")
                
                isLoading = false
                onSuccess(response.userId)

            } catch {

                print("Error: \(error)")
                isLoading = false
                showError("Credenciales incorrectas o falla en el servidor.")

            }

        }

    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showAlert = true
    }
}