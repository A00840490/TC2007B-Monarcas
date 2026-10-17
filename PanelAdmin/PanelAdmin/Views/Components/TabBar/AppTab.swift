//
//  AppTab.swift
//  PanelAdmin
//

import Foundation

/// Sections shown in the bottom tab bar.
enum AppTab: String, CaseIterable, Identifiable
{
    case dashboard
    case donors
    case profile
    
    var id: String { rawValue }
    
    var title: String
    {
        switch self
        {
            case .dashboard:
                return "Dashboard"
            
            case .donors:
                return "Donantes"
            
            case .profile:
                return "Mi perfil"
        }
    }
    
    var icon: String
    {
        switch self
        {
            case .dashboard:
                return "chart.bar"
            
            case .donors:
                return "person.2"
            
            case .profile:
                return "person.crop.circle"
        }
    }
}
