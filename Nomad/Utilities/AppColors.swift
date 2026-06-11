//
//  AppColors.swift
//  Nomad
//

import SwiftUI

extension Color {
    /// Adaptive background color for cards and elevated surfaces
    static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
    
    /// Adaptive border color with good contrast in both modes
    static let adaptiveBorder = Color(uiColor: .separator)
    
    /// Subtle shadow color that works in both light and dark mode
    static func adaptiveShadow(opacity: Double = 0.15) -> Color {
        return Color(uiColor: .label).opacity(opacity)
    }
    
    /// Text color with guaranteed contrast on light backgrounds
    static let onLightBackground = Color(uiColor: .darkText)
    
    /// Text color with guaranteed contrast on dark backgrounds  
    static let onDarkBackground = Color(uiColor: .lightText)
}

extension ShapeStyle where Self == Color {
    /// Primary adaptive text color
    static var primaryText: Color {
        Color(uiColor: .label)
    }
    
    /// Secondary adaptive text color
    static var secondaryText: Color {
        Color(uiColor: .secondaryLabel)
    }
    
    /// Tertiary adaptive text color
    static var tertiaryText: Color {
        Color(uiColor: .tertiaryLabel)
    }
}
