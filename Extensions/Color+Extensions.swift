import SwiftUI

extension Color {
    static let darkBackground = Color(red: 0.1, green: 0.1, blue: 0.2)
    static let cardBackground = Color(red: 0.2, green: 0.2, blue: 0.3)
    static let premiumGradient = LinearGradient(
        gradient: Gradient(colors: [.purple, .pink]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}