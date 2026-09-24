import SwiftUI

struct DashboardView: View {
    let userId: Int
    let onLogout: () -> Void

    var body: some View {
        Text("Hello World")
            .font(.largeTitle)
            .fontWeight(.semibold)
    }
}

#Preview {
    DashboardView(userId: 1, onLogout: { })
}