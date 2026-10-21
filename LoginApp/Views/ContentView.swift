import SwiftUI
import CaritasAuth

struct ContentView: View {
    
    var body: some View {
        
        ZStack {
            
            Color.standardColor
                .ignoresSafeArea()
            
            AuthGate(configuration: APIConfig.auth) { userId, logout in
                DashboardView(userId: userId, onLogout: logout)
            }
            
            .padding()
            
        }
        
    }
    
};

#Preview {
    ContentView()
}
