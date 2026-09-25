//
//  ContentView.swift
//  PanelAdmin
//
//  Created by Alumno on 22/09/26.
//

import SwiftUI

struct ContentView: View
{
    @State private var selectedTab: String = "Dashboard"
    
    var body: some View
    {
        HStack
        {
            Sidebar(selectedTab: $selectedTab)
                .frame(width: 240)
            
            Divider()
            
            Spacer()
            
            ZStack
            {
                switch selectedTab
                {
                    case "Dashboard":
                        DashboardView()
                    
                    default:
                        DashboardView()
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
