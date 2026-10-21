# CaritasAuth

Swift package with the login shared by the Cáritas apps (admin, telefonista, recolector).

It includes:

- `AuthGate`: shows the login when there is no session and the app's content when there is. When the app opens with a saved session, it checks it with `POST /login/verify` against the app's role.
- `LoginView` / `LoginViewModel`: form, validations and the call to `POST /login/attempt`, which returns a JSON Web Token.
- `SessionStore`: stores the token in the Keychain; `readToken()` is used to send it as `Authorization: Bearer <token>`.
- `AuthConfiguration`: what changes per app (API URL, title, role, logo, email domain, session key, color).

## Structure

```
Sources/CaritasAuth/
  Config/       AuthConfiguration
  Models/       UserCredentials, LoginAttemptResponse
  Services/     AuthAPIClient, SessionStore, KeychainHelper
  Utilities/    SHA-256 hash
  ViewModels/   LoginViewModel
  Views/        LoginView, AuthGate
  Resources/    Media.xcassets with the Cáritas de Monterrey logo
```

## Using it in an app

1. In Xcode: **File → Add Package Dependencies… → Add Local…** and pick `Shared/CaritasAuth`. Add the `CaritasAuth` product to the app's target.
2. Create the app's configuration (for example in `Config/APIConfig.swift`):

   ```swift
   import CaritasAuth

   enum APIConfig {
       static let baseUrl = "https://host:10206/api/"
       static let auth = AuthConfiguration(
           apiBaseUrl: baseUrl,
           role: "Admin"   // or "Telefonista" / "Recolector"
       )
   }
   ```

3. Wrap the main screen:

   ```swift
   import CaritasAuth

   AuthGate(configuration: APIConfig.auth) { userId, logout in
       MainScreen(userId: userId, onLogout: logout)
   }
   ```

## Roles

The login title comes from the role: "Panel de Administrador", "Telefonistas" or
"Recolectores". To use a different text, pass `title:` to `AuthConfiguration`.

The Cáritas de Monterrey logo (`Resources/Media.xcassets`) is shown above the title in
every app. To use another image, pass `logo:` to `AuthConfiguration`.

`role` must match `Name` in the Role table. `AuthConfiguration.roleDisplayName(_:)`
gives the Spanish name to show to the user. `POST /login/attempt` rejects a
user with another role with 403, so the admin app does not let a recolector or a
telefonista in.

## Calling protected endpoints

```swift
var request = URLRequest(url: url)
if let token = SessionStore(key: APIConfig.auth.sessionKey).readToken() {
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
}
```
