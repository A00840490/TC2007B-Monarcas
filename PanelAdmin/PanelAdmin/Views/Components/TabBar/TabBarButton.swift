//
//  TabBarButton.swift
//  PanelAdmin
//

import SwiftUI

struct TabBarButton: View
{
    let icon: String
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View
    {
        Button(action: onTap)
        {
            VStack(spacing: 4)
            {
                Image(systemName: isSelected ? icon + ".fill" : icon)
                    .font(.system(size: 26))
                    .frame(height: 30)
                
                Text(title)
                    .font(.system(size: 15))
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Capsule()
                    .fill(isSelected ? Constants.primaryColor : .clear)
                    .frame(width: 24, height: 4)
            }
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .foregroundColor(isSelected ? Constants.primaryColor : .gray)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack
    {
        TabBarButton(icon: "chart.bar", title: "Dashboard", isSelected: true, onTap: {})
        TabBarButton(icon: "person.crop.circle", title: "Mi perfil", isSelected: false, onTap: {})
    }
}
