//
//  ContentView.swift
//  PanelAdmin
//
//  Created by Alumno on 22/09/26.
//

import SwiftUI

struct ContentView: View
{
    @State private var selectedTab: AppTab = .dashboard
    /// Screens pushed inside the current tab (e.g. a donor's detail).
    @State private var path = NavigationPath()
    
    /// Logs out and goes back to the login (provided by AuthGate).
    var onLogout: () -> Void = {}
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            NavigationStack(path: $path)
            {
                ZStack
                {
                    switch selectedTab
                    {
                        case .dashboard:
                            DashboardView()
                                .padding()
                                .toolbar(.hidden, for: .navigationBar)
                        
                        case .donors:
                            DonorsView(path: $path)
                        
                        case .personal:
                            PersonalView()
                        
                        case .profile:
                            ProfileView(onLogout: onLogout)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Constants.secondaryBackgroundColor)
                .navigationBarTitleDisplayMode(.inline)
            }
            
            // Tapping a tab, even the current one, goes back to that tab's first screen.
            TabBar(selectedTab: Binding(
                get: { selectedTab },
                set: { tab in
                    selectedTab = tab
                    path = NavigationPath()
                }
            ))
        }
    }
}

#Preview {
    ContentView()
}
