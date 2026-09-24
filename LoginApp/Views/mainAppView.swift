import SwiftUI

struct mainAppView: View {
    @State private var loggedInUserId: Int? = KeychainHelper.shared.readInt(forKey: "userDatabaseId")
    
    var body: some View {
        Group {
            if let userId = loggedInUserId {
                DashboardView(userId: userId) {
                    KeychainHelper.shared.delete(forKey: "userDatabaseId")
                    loggedInUserId = nil
                }
            } else {
                LoginView { userIdRecibido in
                    loggedInUserId = userIdRecibido
                }
            }
        }
    }
}