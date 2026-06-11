//
//  ViewModifiers.swift
//  Nomad
//

import SwiftUI

/// Provides adaptive shadows that look good in both light and dark mode
struct AdaptiveShadow: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let radius: CGFloat
    let y: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: colorScheme == .dark 
                    ? .black.opacity(0.4)
                    : .black.opacity(0.15),
                radius: radius,
                y: y
            )
    }
}

/// Provides an adaptive card-like background
struct CardBackground: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(
                color: colorScheme == .dark
                    ? .black.opacity(0.3)
                    : .black.opacity(0.08),
                radius: 8,
                y: 2
            )
    }
}

extension View {
    /// Applies an adaptive shadow that looks good in both light and dark mode
    func adaptiveShadow(radius: CGFloat = 8, y: CGFloat = 4) -> some View {
        modifier(AdaptiveShadow(radius: radius, y: y))
    }
    
    /// Applies a card-like background with proper elevation
    func cardBackground() -> some View {
        modifier(CardBackground())
    }
}
