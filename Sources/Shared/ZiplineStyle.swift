//
//  ZiplineStyle.swift
//  Zipline
//
//  Created by Amirali Yazdani.
//
import SwiftUI
import UIKit

enum ZiplineStyle {
    static let accent = Color(red: 0.43, green: 0.29, blue: 0.98)
    static let accentDeep = Color(red: 0.27, green: 0.16, blue: 0.76)
    static let accentGradient = LinearGradient(
        colors: [Color(red: 0.58, green: 0.43, blue: 1.0), accent, accentDeep],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    static let canvas = Color(uiColor: .systemGroupedBackground)
    static let surface = Color(uiColor: .secondarySystemGroupedBackground)
    static let tile = Color(uiColor: .tertiarySystemGroupedBackground)
    static let ink = Color.primary
    static let muted = Color.secondary
}

/// Uses native Liquid Glass on current systems and a native material fallback elsewhere.
struct ZiplineCardSurface: ViewModifier {
    var modern: Bool
    var radius: CGFloat = 26

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        Group {
            if modern {
                if #available(iOS 26.0, *) {
                    content
                        .background(.clear, in: shape)
                        .glassEffect(.regular, in: shape)
                } else {
                    content.background(.regularMaterial, in: shape)
                }
            } else {
                content.background(ZiplineStyle.surface, in: shape)
            }
        }
        .overlay(shape.stroke(Color.primary.opacity(0.055), lineWidth: 1))
        .shadow(color: ZiplineStyle.accent.opacity(modern ? 0.10 : 0.055), radius: modern ? 26 : 14, x: 0, y: modern ? 12 : 6)
    }
}

extension View {
    func ziplineCardSurface(modern: Bool, radius: CGFloat = 26) -> some View {
        modifier(ZiplineCardSurface(modern: modern, radius: radius))
    }
}