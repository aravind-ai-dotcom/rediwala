import SwiftUI
import UIKit

/// Shared visual tokens for RediWala Customer (light + dark).
enum AppTheme {
    static let primary = Color(red: 34 / 255, green: 197 / 255, blue: 94 / 255) // #22C55E
    static let accent = Color(red: 249 / 255, green: 115 / 255, blue: 22 / 255)
    static let info = Color(red: 59 / 255, green: 130 / 255, blue: 246 / 255)
    static let danger = Color(red: 239 / 255, green: 68 / 255, blue: 68 / 255)

    static let background = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.11, green: 0.12, blue: 0.13, alpha: 1)
        }
        return UIColor(red: 0.97, green: 0.97, blue: 0.96, alpha: 1)
    })

    static let card = Color(uiColor: UIColor { traits in
        if traits.userInterfaceStyle == .dark {
            return UIColor(red: 0.18, green: 0.19, blue: 0.20, alpha: 1)
        }
        return .white
    })

    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary

    static let cardCorner: CGFloat = 20
    static let buttonCorner: CGFloat = 18
    static let minTap: CGFloat = 56
}
