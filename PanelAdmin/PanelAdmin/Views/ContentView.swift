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
    @State private var path = NavigationPath()
    
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
            
            TabBar(selectedTab: selectedTab)
            { tab in
                selectedTab = tab
                path = NavigationPath()
            }
        }
        .onBackAndForthShake
        {
            selectedTab = .dashboard
            path = NavigationPath()
        }
    }
}

#Preview {
    ContentView()
}
