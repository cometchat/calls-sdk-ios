import SwiftUI
import UIKit

// MARK: - Palette

/// Light and dark values for every colour the app uses. Screens use the `Color` tokens
/// below and never a literal, so the whole app follows the appearance setting.
enum AppPalette {
    private static func pair(_ light: UInt32, _ dark: UInt32, alpha: CGFloat = 1) -> UIColor {
        UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                           green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255,
                           alpha: alpha)
        }
    }

    static let appBackground = pair(0xFFFFFF, 0x1A1D21)
    static let cardBackground = pair(0xFFFFFF, 0x222529)
    static let background2 = pair(0xF5F5F5, 0x26282C)
    static let background3 = pair(0xECECEC, 0x2C2D30)
    static let borderLight = pair(0xECECEC, 0x35373B)
    static let borderPrimary = pair(0xC3CBD6, 0x4C4C4C)
    static let brandAccent = pair(0x6D5DF6, 0x6D5DF6)
    static let accentSoft = pair(0x6D5DF6, 0x6D5DF6, alpha: 0.08)
    static let textPrimary = pair(0x181A20, 0xD1D2D3)
    static let textSecondary = pair(0x7E7E7E, 0x9A9B9D)
    static let textTertiary = pair(0x9E9E9E, 0x6E6F71)
    static let textDisabled = pair(0xC3CBD6, 0x4C4C4C)
    static let statusOnline = pair(0x2EB57D, 0x2BAC76)
    static let statusSuccessBg = pair(0x2EB57D, 0x2BAC76, alpha: 0.1)
    static let statusOffline = pair(0x9E9E9E, 0x6E6F71)
    static let statusError = pair(0xD9235E, 0xE01E5A)
    static let statusErrorBg = pair(0xD9235E, 0xE01E5A, alpha: 0.1)
    static let statusNeutralBg = pair(0xF5F5F5, 0x26282C)
    static let selected = pair(0x49418B, 0x373267)
    static let codeBackground = pair(0xF5F5F5, 0x2C2D30)
    static let emphasis = pair(0x181A20, 0xFFFFFF)
    static let onEmphasis = pair(0xFFFFFF, 0x1A1D21)
    static let onAccent = pair(0xFFFFFF, 0xFFFFFF)
    static let scrim = pair(0x000000, 0x000000, alpha: 0.5)
}

extension Color {
    static let appBackground = Color(AppPalette.appBackground)
    static let cardBackground = Color(AppPalette.cardBackground)
    static let background2 = Color(AppPalette.background2)
    static let background3 = Color(AppPalette.background3)
    static let borderLight = Color(AppPalette.borderLight)
    static let borderPrimary = Color(AppPalette.borderPrimary)
    static let brandAccent = Color(AppPalette.brandAccent)
    static let accentSoft = Color(AppPalette.accentSoft)
    static let textPrimary = Color(AppPalette.textPrimary)
    static let textSecondary = Color(AppPalette.textSecondary)
    static let textTertiary = Color(AppPalette.textTertiary)
    static let textDisabled = Color(AppPalette.textDisabled)
    static let statusOnline = Color(AppPalette.statusOnline)
    static let statusSuccessBg = Color(AppPalette.statusSuccessBg)
    static let statusOffline = Color(AppPalette.statusOffline)
    static let statusError = Color(AppPalette.statusError)
    static let statusErrorBg = Color(AppPalette.statusErrorBg)
    static let statusNeutralBg = Color(AppPalette.statusNeutralBg)
    static let selected = Color(AppPalette.selected)
    static let codeBackground = Color(AppPalette.codeBackground)
    static let emphasis = Color(AppPalette.emphasis)
    static let onEmphasis = Color(AppPalette.onEmphasis)
    static let onAccent = Color(AppPalette.onAccent)
    static let scrim = Color(AppPalette.scrim)

    /// Older name for `brandAccent`, still used by a few screens.
    static let accentPurple = brandAccent
}

// MARK: - Type, spacing, radius

enum AppType {
    private static func scaled(_ size: CGFloat, _ weight: Font.Weight, _ style: UIFont.TextStyle,
                               design: Font.Design = .default) -> Font {
        .system(size: UIFontMetrics(forTextStyle: style).scaledValue(for: size), weight: weight, design: design)
    }

    static var title: Font { scaled(22, .bold, .title2) }
    static var heading: Font { scaled(18, .bold, .headline) }
    static var body: Font { scaled(15, .regular, .body) }
    static var bodyStrong: Font { scaled(15, .bold, .body) }
    static var label: Font { scaled(13, .medium, .footnote) }
    static var caption: Font { scaled(12, .regular, .caption1) }
    static var code: Font { scaled(13, .regular, .footnote, design: .monospaced) }
}

enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

enum AppRadius {
    static let medium: CGFloat = 9
    static let large: CGFloat = 14
    static let xlarge: CGFloat = 18
}

// MARK: - Surfaces

extension View {
    /// An opaque card: content sits on surfaces, never on glass.
    func surfaceSection() -> some View {
        background(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous).fill(Color.cardBackground))
            .overlay(RoundedRectangle(cornerRadius: AppRadius.large, style: .continuous)
                .stroke(Color.borderLight, lineWidth: 1))
    }

    func cardStyle() -> some View {
        padding(AppSpacing.xl).surfaceSection()
    }
}

// MARK: - Buttons

/// A filled capsule in the brand colour.
struct PrimaryButtonStyle: ButtonStyle {
    var fill: Color = .brandAccent
    var fullWidth = true
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppType.bodyStrong)
            .foregroundColor(isEnabled ? .onAccent : .textDisabled)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .frame(minHeight: 48)
            .padding(.horizontal, fullWidth ? 0 : AppSpacing.xl)
            .background(Capsule().fill(isEnabled ? fill : Color.background2))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// An outlined capsule on the card colour.
struct OutlinedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppType.bodyStrong)
            .foregroundColor(.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(Capsule().fill(configuration.isPressed ? Color.background2 : Color.cardBackground))
            .overlay(Capsule().stroke(Color.borderPrimary, lineWidth: 1))
    }
}

/// A full-width capsule for destructive actions such as signing out.
struct DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppType.bodyStrong)
            .foregroundColor(.statusError)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(Capsule().fill(Color.statusErrorBg))
            .overlay(Capsule().stroke(Color.statusError.opacity(0.6), lineWidth: 1))
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// The round voice / video buttons on user and group rows.
struct CircleIconButton: View {
    let systemName: String
    let accessibilityLabel: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.brandAccent)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.accentSoft))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Fields

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(AppType.body)
            .foregroundColor(.textPrimary)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: AppRadius.large).fill(Color.background2))
            .overlay(RoundedRectangle(cornerRadius: AppRadius.large).stroke(Color.borderLight, lineWidth: 1))
    }
}

/// The capsule search field above the user and group lists.
struct SearchField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.textSecondary)
            TextField(placeholder, text: $text)
                .font(AppType.body)
                .foregroundColor(.textPrimary)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.textTertiary)
                }
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .frame(height: 44)
        .background(Capsule().fill(Color.cardBackground))
        .overlay(Capsule().stroke(Color.borderLight, lineWidth: 1))
    }
}

// MARK: - Labels

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppType.label)
            .foregroundColor(.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct OrDivider: View {
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Rectangle().fill(Color.borderLight).frame(height: 1)
            Text("Or").font(AppType.caption).foregroundColor(.textSecondary)
            Rectangle().fill(Color.borderLight).frame(height: 1)
        }
    }
}

/// The app's wordmark, drawn in type so it follows the appearance setting.
struct AppLogo: View {
    var size: CGFloat = 22

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "phone.bubble.fill")
                .font(.system(size: size * 0.9, weight: .semibold))
                .foregroundColor(.brandAccent)
            Text("CometChat")
                .font(.system(size: size, weight: .bold))
                .foregroundColor(.textPrimary)
            + Text(" Calls")
                .font(.system(size: size, weight: .regular))
                .foregroundColor(.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Appearance

/// The Profile screen's System / Light / Dark choice.
enum AppearancePreference: String, CaseIterable, Identifiable {
    case system, light, dark

    static let storageKey = "appearance"

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    /// `.preferredColorScheme` covers SwiftUI; UIKit-presented screens (CallKit hand-off, the
    /// Calls SDK's call UI) read the window's style, so it is set there too.
    func apply() {
        let style: UIUserInterfaceStyle
        switch self {
        case .system: style = .unspecified
        case .light: style = .light
        case .dark: style = .dark
        }
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            scene.windows.forEach { $0.overrideUserInterfaceStyle = style }
        }
    }
}
