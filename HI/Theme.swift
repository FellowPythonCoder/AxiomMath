import SwiftUI
import UIKit

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

enum AxiomPalette {

    static let primary      = Color(hex: 0x2F6FED)
    static let primaryDeep  = Color(hex: 0x1E4FD1)
    static let primaryLight = Color(hex: 0x5B93FF)

    static let accent       = Color(hex: 0x38BDF8)
    static let electric     = Color(hex: 0x22D3EE)

    static let glow          = Color(hex: 0xBFE3FF)
    static let coin          = Color(hex: 0xBAE6FD)

    static let navy         = Color(hex: 0x0B1324)
    static let navyDeep     = Color(hex: 0x020817)
    static let ice          = Color(hex: 0xF0F7FF)
    static let frost        = Color(hex: 0xDCEBFF)

    static let sunset       = Color(hex: 0xFF8A5B)
    static let sunsetDeep   = Color(hex: 0xF06A3D)

    static let portal       = Color(hex: 0x8B7CFC)
    static let portalDeep   = Color(hex: 0x5B3FE0)

    static let success      = Color(hex: 0x14B8A6)
    static let warning      = sunsetDeep

    static let sky           = accent
    static let mint          = success
    static let gold          = coin
    static let berry         = warning
    static let cream         = ice
    static let sand          = frost

    static func background(dark: Bool) -> LinearGradient {
        LinearGradient(
            colors: dark
                ? [navyDeep, Color(hex: 0x1E3A8A), navy]
                : [ice, frost, Color(hex: 0xBFDBFE)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func heroGradient(dark: Bool) -> LinearGradient {
        LinearGradient(
            colors: dark
                ? [primaryDeep, navyDeep]
                : [primary, primaryLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func cardGradient(dark: Bool) -> LinearGradient {
        LinearGradient(
            colors: dark
                ? [navy, primaryDeep.opacity(0.85), navyDeep]
                : [Color(hex: 0xEAF2FF), Color(hex: 0xCFE3FF), primaryLight.opacity(0.55)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func cardText(dark: Bool) -> Color { dark ? .white : navy }
    static func cardTextMuted(dark: Bool) -> Color { dark ? .white.opacity(0.65) : navy.opacity(0.55) }
}

class HapticManager {
    static let instance = HapticManager()
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    func notify(type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
