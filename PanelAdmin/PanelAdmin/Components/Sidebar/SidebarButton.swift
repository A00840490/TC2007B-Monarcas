//
//  SidebarButton.swift
//  PanelAdmin
//
//  Created by Alumno on 22/09/26.
//

import SwiftUI

struct SidebarButton: View
{
    let icon: String
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View
    {
        Button(action: onTap)
        {
            HStack
            {
                Image(systemName: icon)
                    .font(.system(size: 28))
                
                Text(title)
                    .font(.system(size: 24))
                    .fontWeight(isSelected ? .semibold : .regular)
                
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(isSelected ? Constants.primaryColor : .clear)
            .foregroundColor(isSelected ? .white : Constants.primaryColor)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SidebarButton(icon: "", title: "Dashboard", isSelected: true, onTap: {})
}
