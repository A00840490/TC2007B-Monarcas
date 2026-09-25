//
//  Sidebar.swift
//  PanelAdmin
//
//  Created by Alumno on 22/09/26.
//

import SwiftUI

struct Sidebar: View
{
    @Binding var selectedTab: String
    
    var body: some View
    {
        VStack
        {
            HStack
            {
                Text("Menú")
                    .font(.system(size: 32))
                    .foregroundColor(Constants.neutralColor)
            }
            
            Divider()
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            
            VStack
            {
                SidebarButton (
                    icon: "",
                    title: "Dashboard",
                    isSelected: selectedTab == "Dashboard",
                    onTap: { selectedTab = "Dashboard" }
                )
            }
            
            Spacer()
        }
    }
}

#Preview {
    Sidebar(selectedTab: .constant("Dashboard"))
}
