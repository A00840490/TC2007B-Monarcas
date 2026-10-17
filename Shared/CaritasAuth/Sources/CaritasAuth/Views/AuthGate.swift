import SwiftUI

/// Shows the login while there is no session and the app's content when there is.
/// If a token is already saved, it is first checked with `POST /login/verify`
/// against the app's role; if the API rejects it, it is deleted and login is shown.
/// Usage:
///
///     AuthGate(configuration: config) { userId, logout in
///         MainScreen(userId: userId, onLogout: logout)
///     }
public struct AuthGate<Content: View>: View {
    
    private enum SessionState {
        case checking(token: String)
        case loggedOut
        case loggedIn(userId: Int)
    }
    
    let configuration: AuthConfiguration
    let content: (Int, @escaping () -> Void) -> Content
    
    @State private var state: SessionState
    
    public init(
        configuration: AuthConfiguration,
        @ViewBuilder content: @escaping (_ userId: Int, _ logout: @escaping () -> Void) -> Content
    ) {
        self.configuration = configuration
        self.content = content
        if let token = SessionStore(key: configuration.sessionKey).readToken() {
            _state = State(initialValue: .checking(token: token))
        } else {
            _state = State(initialValue: .loggedOut)
        }
    }
    
    public var body: some View {
        Group {
            switch state {
            case .checking(let token):
                ProgressView()
                    .task { await verify(token) }
            case .loggedIn(let userId):
                content(userId) {
                    SessionStore(key: configuration.sessionKey).clear()
                    state = .loggedOut
                }
            case .loggedOut:
                LoginView(configuration: configuration) { receivedUserId in
                    state = .loggedIn(userId: receivedUserId)
                }
            }
        }
    }
    
    @MainActor
    private func verify(_ token: String) async {
        do {
            let response = try await AuthAPIClient(baseUrl: configuration.apiBaseUrl)
                .postLoginVerify(token: token, role: configuration.role)
            state = .loggedIn(userId: response.userId)
        } catch AuthAPIError.rejected {
            // Expired token, deleted user or different role: log out.
            SessionStore(key: configuration.sessionKey).clear()
            state = .loggedOut
        } catch {
            // No connection: keep the token to try again next time.
            print("Could not verify the session: \(error)")
            state = .loggedOut
        }
    }
    
}
