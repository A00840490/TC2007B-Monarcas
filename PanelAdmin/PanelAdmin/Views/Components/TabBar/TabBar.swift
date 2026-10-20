//
//  TabBar.swift
//  PanelAdmin
//

import SwiftUI

struct TabBar: View
{
    let selectedTab: AppTab
    let onSelect: (AppTab) -> Void
    
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
                    onTap: { onSelect(tab) }
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
        TabBar(selectedTab: .dashboard) { _ in }
    }
    .background(Constants.secondaryBackgroundColor)
}
