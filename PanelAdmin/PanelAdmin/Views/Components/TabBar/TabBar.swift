//
//  TabBar.swift
//  PanelAdmin
//

import SwiftUI

/// Bottom bar pinned to the edge of the screen (not floating) with one button per section.
struct TabBar: View
{
    @Binding var selectedTab: AppTab
    
    var body: some View
    {
        HStack(spacing: 0)
        {
            ForEach(AppTab.allCases)
            { tab in
                TabBarButton (
                    icon: tab.icon,
                    title: tab.title,
                    isSelected: selectedTab == tab,
                    onTap: { selectedTab = tab }
                )
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(Color.white.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top)
        {
            Divider()
        }
    }
}

#Preview {
    VStack
    {
        Spacer()
        TabBar(selectedTab: .constant(.dashboard))
    }
    .background(Constants.secondaryBackgroundColor)
}
