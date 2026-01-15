//
//  CarbyoTheme.swift
//  Carbyo IOS
//
//  Created by cedric pachis on 11/01/2026.
//

import SwiftUI

// MARK: - Colors
struct CarbyoColors {
    static let primary = Color(hex: "00B47D")
    static let primarySoft = Color(hex: "E6F4ED")
    static let background = Color(hex: "F7FAF9")
    static let surface = Color.white
    static let text = Color(hex: "0F172A")
    static let muted = Color(hex: "64748B")
    static let border = Color(hex: "E2E8F0")
}

// MARK: - Corner Radius
extension CGFloat {
    static let carbyoCardRadius: CGFloat = 18
    static let carbyoButtonRadius: CGFloat = 14
}

// MARK: - Shadow
extension View {
    func carbyoShadow() -> some View {
        self.shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 2)
    }
}

// MARK: - Card Component
struct CarbyoCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(CarbyoColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: .carbyoCardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: .carbyoCardRadius)
                    .stroke(CarbyoColors.border.opacity(0.5), lineWidth: 1)
            )
            .carbyoShadow()
    }
}

// MARK: - KPI Card Component
struct CarbyoKpiCard: View {
    let title: String
    let value: String
    let systemIcon: String
    let accent: Color
    
    init(title: String, value: String, systemIcon: String, accent: Color = CarbyoColors.primary) {
        self.title = title
        self.value = value
        self.systemIcon = systemIcon
        self.accent = accent
    }
    
    var body: some View {
        CarbyoCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: systemIcon)
                        .font(.title3)
                        .foregroundColor(accent)
                    
                    Spacer()
                }
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(CarbyoColors.text)
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(CarbyoColors.muted)
                    .lineSpacing(4)
            }
        }
    }
}

// MARK: - Row Link Component
struct CarbyoRowLink: View {
    let title: String
    let subtitle: String?
    let systemIcon: String
    let accent: Color
    
    init(title: String, subtitle: String? = nil, systemIcon: String, accent: Color = CarbyoColors.primary) {
        self.title = title
        self.subtitle = subtitle
        self.systemIcon = systemIcon
        self.accent = accent
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: systemIcon)
                .font(.title3)
                .foregroundColor(accent)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .foregroundColor(CarbyoColors.text)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(CarbyoColors.muted)
                        .lineSpacing(2)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(CarbyoColors.muted)
        }
        .padding()
        .background(CarbyoColors.surface)
        .cornerRadius(.carbyoCardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: .carbyoCardRadius)
                .stroke(CarbyoColors.border.opacity(0.5), lineWidth: 1)
        )
        .carbyoShadow()
    }
}

// MARK: - FAB Button Component
struct CarbyoFabButton: View {
    let systemIcon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemIcon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(CarbyoColors.primary)
                .clipShape(Circle())
                .carbyoShadow()
        }
    }
}

// MARK: - Screen Modifier
struct CarbyoScreenModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(CarbyoColors.background)
            .toolbarBackground(CarbyoColors.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

extension View {
    func carbyoScreen() -> some View {
        modifier(CarbyoScreenModifier())
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
