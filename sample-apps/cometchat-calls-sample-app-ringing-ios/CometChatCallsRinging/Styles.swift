import SwiftUI

// MARK: - Color Palette (matching CometChat Connect dark theme)

extension Color {
    static let appBackground = Color(hex: "#141414")
    static let cardBackground = Color(hex: "#1A1A1A")
    static let borderPrimary = Color(hex: "#383838")
    static let borderLight = Color(hex: "#272727")
    static let accentPurple = Color(hex: "#8C78F0")
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#989898")
    static let textTertiary = Color(hex: "#858585")
    static let statusError = Color(hex: "#C73C3E")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 6:
            (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b, a) = (0, 0, 0, 255)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}

// MARK: - Primary Button (filled purple)

struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(isEnabled ? Color.accentPurple : Color.accentPurple.opacity(0.4))
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}


// MARK: - Outlined Button (border only)

struct OutlinedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderPrimary, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

// MARK: - Rounded TextField (dark theme)

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderPrimary, lineWidth: 1)
            )
    }
}

// MARK: - Card Modifier

struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(24)
            .background(Color.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.borderLight, lineWidth: 1)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}

// MARK: - Section Label

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Or Divider

struct OrDivider: View {
    var body: some View {
        HStack(spacing: 12) {
            Rectangle().fill(Color.borderPrimary).frame(height: 1)
            Text("Or")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
            Rectangle().fill(Color.borderPrimary).frame(height: 1)
        }
    }
}
